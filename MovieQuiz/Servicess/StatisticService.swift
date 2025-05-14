import Foundation

// Расширяем при объявлении
final class StatisticServiceImplementation: StatisticServiceProtocol {
    
    private let storage: UserDefaults = .standard

    private enum Keys: String {
        case bestCorrect
        case bestGame
        case gamesCount
        case bestTotal
        case bestDate
        case totalCorrect
        case totalQuestions
        }
    
    
    var gamesCount: Int{
        get{
            storage.integer(forKey: Keys.gamesCount.rawValue)
        }
        set{
            storage.set(newValue, forKey: Keys.gamesCount.rawValue)
        }
    }
    
    var bestGame: GameResult{
        get{
            let correct = storage.integer(forKey: Keys.bestCorrect.rawValue)
            let total = storage.integer(forKey: Keys.bestTotal.rawValue)
            let date = storage.object(forKey: Keys.bestDate.rawValue) as? Date ?? Date()
            
            return GameResult(correct: correct, total: total, date: date)
        }
        set{
            storage.set(newValue.correct, forKey: Keys.bestCorrect.rawValue)
            storage.set(newValue.total, forKey: Keys.bestTotal.rawValue)
            storage.set(newValue.date, forKey: Keys.bestDate.rawValue)
        }
    }
    
    var totalAccuracy: Double{
        let total = storage.integer(forKey: Keys.totalQuestions.rawValue)
        let correct = storage.integer(forKey: Keys.totalCorrect.rawValue)
        guard total > 0 else { return 0 }
        return (Double(correct) / Double(total)) * 100
    }
    
    
    func store(correct count: Int, total amount: Int) {
        let newCorrect = storage.integer(forKey: Keys.totalCorrect.rawValue) + count
        let newTotal = storage.integer(forKey: Keys.totalQuestions.rawValue) + amount
        storage.set(newCorrect, forKey: Keys.totalCorrect.rawValue)
        storage.set(newTotal, forKey: Keys.totalQuestions.rawValue)
        
        gamesCount += 1
        
        let currentGame = GameResult(correct: count, total: amount, date: Date())
        if currentGame.bestRecord(bestGame) {
            bestGame = currentGame
        }
        
    }
}
