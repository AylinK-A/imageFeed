import UIKit

final class ImagesListCell: UITableViewCell {

    @IBOutlet private weak var imageCellView: UIImageView!
    @IBOutlet private weak var dateCellView: UILabel!
    @IBOutlet private weak var buttonCellView: UIButton!

    static let reuseIdentifier = "ImagesListCell"

    private let gradientLayer = CAGradientLayer()
    private lazy var dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .long
        f.timeStyle = .none
        f.locale = Locale(identifier: "ru_RU")
        return f
    }()

    override func awakeFromNib() {
        super.awakeFromNib()
        // Градиент — сверху прозрачный, снизу лёгкий затемнитель
        let start = UIColor(red: 26/255, green: 27/255, blue: 34/255, alpha: 0.0)
        let end   = UIColor(red: 26/255, green: 27/255, blue: 34/255, alpha: 0.2)
        gradientLayer.colors = [start.cgColor, end.cgColor]
        gradientLayer.locations = [0, 1]
        imageCellView.layer.addSublayer(gradientLayer)
        selectionStyle = .none
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Подгоняем градиент под низ изображения (30pt высотой)
        let height: CGFloat = 30
        gradientLayer.frame = CGRect(
            x: 0,
            y: imageCellView.bounds.height - height,
            width: imageCellView.bounds.width,
            height: height
        )
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageCellView.image = nil
        dateCellView.text = nil
        // like оставим дефолтным; при configure обновится
    }

    /// Новый метод конфигурации: принимает модель Photo
    func configure(with photo: Photo) {
        // 1) Дата
        if let created = photo.createdAt {
            dateCellView.text = dateFormatter.string(from: created)
        } else {
            dateCellView.text = "—"
        }

        // 2) Иконка лайка
        let likeImage = photo.isLiked
            ? UIImage(named: "Active")
            : UIImage(named: "No Active")
        buttonCellView.setImage(likeImage, for: .normal)

        // 3) Превью (thumb) — грузим и кэшируем
        ImageLoader.shared.loadImage(from: photo.thumbImageURL) { [weak self] image in
            self?.imageCellView.image = image
        }
    }
}

