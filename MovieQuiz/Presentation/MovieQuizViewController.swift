import UIKit
import Foundation

final class MovieQuizViewController: UIViewController, QuestionFactoryDelegate {
    // MARK: - Lifecycle
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var textLabel: UILabel!
    @IBOutlet private var counterLabel: UILabel!
    @IBOutlet private var activityIndicator: UIActivityIndicatorView!
    
    private var currentQuestionIndex = 0
    private var correctAnswers = 0
    private let questionsAmount: Int = 10
    private var questionFactory: QuestionFactoryProtocol?
    private var currentQuestion: QuizQuestion?
    private var alertPresenter: AlertPresenter?
    private var statisticService: StatisticServiceProtocol = StatisticServiceImplementation()
    
    @IBAction func yesButton(_ sender: UIButton) {
        guard let currentQuestion = currentQuestion else{
            return
        }
        let theAnswerIsCorrect = true
        showAnswerResult(isCorrect: theAnswerIsCorrect == currentQuestion.correctAnswer)
    }
    
    @IBAction func noButton(_ sender: UIButton) {
        guard let currentQuestion = currentQuestion else{
            return
        }
        let theAnswerIsCorrect = false
        showAnswerResult(isCorrect: theAnswerIsCorrect == currentQuestion.correctAnswer)
    }
    
    private func showLoadingIndicator() {
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
    }
    
    private func hideLoadingIndicator() {
        activityIndicator.isHidden = true
        activityIndicator.stopAnimating()
    }
    
    private func showNetworkError(message: String) {
        hideLoadingIndicator()
        var message = message

        if let urlError = message.lowercased() as String?,
               urlError.contains("offline") || urlError.contains("not connected to the internet") {
               message = "Похоже, нет подключения к интернету. Проверьте сеть и попробуйте снова."
            }
        let model = AlertModel(title: "Ошибка",
                                   message: message,
                                   buttonText: "Попробовать еще раз") { [weak self] in
                guard let self = self else { return }
                self.currentQuestionIndex = 0
                self.correctAnswers = 0
                self.questionFactory?.loadData()
            }
            alertPresenter?.show(alertModel: model)
    }
    
    private func showAnswerResult(isCorrect: Bool) {
        if isCorrect {
            correctAnswers += 1
        }
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 8
        if isCorrect == true {
            imageView.layer.borderColor = UIColor.ypGreen.cgColor
        }else{
            imageView.layer.borderColor = UIColor.ypRed.cgColor
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else {return}
            self.showNextQuestionOrResults()
        }
    }
    
    private func showNextQuestionOrResults() {
        currentQuestion = nil
        if currentQuestionIndex == questionsAmount - 1 {
            statisticService.store(correct: correctAnswers, total: questionsAmount)
            let text = "Ваш результат: \(correctAnswers)/\(questionsAmount)"
            let viewModel = QuizResultsViewModel(
                title: "Этот раунд окончен!",
                text: text,
                buttonText: "Сыграть ещё раз")
            show(quiz: viewModel)
        } else {
            currentQuestionIndex += 1
            self.questionFactory?.requestNextQuestion()
        }
    }
    
    private func convert(model: QuizQuestion) -> QuizStepViewModel {
        QuizStepViewModel(
            image: UIImage(data: model.image) ?? UIImage(),
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)")
    }
    
    private func show(quiz step: QuizStepViewModel) {
        imageView.layer.borderWidth = 0
        imageView.image = step.image
        textLabel.text = step.question
        counterLabel.text = step.questionNumber
    }
    
    private func show(quiz result: QuizResultsViewModel) {
        let accuracyText = String(format: "%.2f", statisticService.totalAccuracy)
        let currentResult = "\(result.text)"
        let gamesCountText = "Количество сыгранных квизов: \(statisticService.gamesCount)"
        let bestGame = statisticService.bestGame
        let bestGameText = "Рекорд: \(bestGame.correct)/\(bestGame.total) (\(bestGame.date.dateTimeString))"
        let averageAccuracyText = "Средняя точность: \(accuracyText)%"

        let detailedMessage = """
        \(currentResult)
        \(gamesCountText)
        \(bestGameText)
        \(averageAccuracyText)
        """
            
        let alertModel = AlertModel(
            title: result.title,
            message: detailedMessage,
            buttonText: result.buttonText
        ) { [weak self] in
            self?.currentQuestionIndex = 0
            self?.correctAnswers = 0
            self?.questionFactory?.requestNextQuestion()
        }
        alertPresenter?.show(alertModel: alertModel)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        alertPresenter = AlertPresenter(viewController: self)
        imageView.layer.cornerRadius = 20
        questionFactory = QuestionFactory(moviesLoader: MoviesLoader(), delegate: self)
        statisticService = StatisticServiceImplementation()
        showLoadingIndicator()
        questionFactory?.loadData()
    }

    // MARK: - QuestionFactoryDelegate

    func didReceiveNextQuestion(question: QuizQuestion?) {
        guard let question = question else {
            return
        }
        currentQuestion = question
        let viewModel = convert(model: question)
        
        DispatchQueue.main.async { [weak self] in
            self?.show(quiz: viewModel)
        }
    }
    
    func didLoadDataFromServer() {
        hideLoadingIndicator()
        questionFactory?.requestNextQuestion()
    }

    
    func didFailToLoadData(with error: Error) {
        var message = "Ошибка загрузки: \(error.localizedDescription)"

        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                message = "Нет подключения к интернету. Проверьте сеть и попробуйте снова."
            case .timedOut:
                message = "Превышено время ожидания. Попробуйте позже."
            default:
                break
            }
        }

        showNetworkError(message: message)
    }

}
    

        




