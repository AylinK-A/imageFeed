import UIKit

protocol ImagesListCellDelegate: AnyObject {
    func imagesListCellDidTapLike(_ cell: ImagesListCell)
}

final class ImagesListCell: UITableViewCell {

    @IBOutlet private weak var imageCellView: UIImageView!
    @IBOutlet private weak var dateCellView: UILabel!
    @IBOutlet private weak var buttonCellView: UIButton!
    
    weak var delegate: ImagesListCellDelegate?
   
    @IBAction func buttonSwitchLike(_ sender: Any) {
        delegate?.imagesListCellDidTapLike(self)
    }
    
    static let reuseIdentifier = "ImagesListCell"

    private let gradientLayer = CAGradientLayer()
    private lazy var dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .long
        f.timeStyle = .none
        f.locale = Locale(identifier: "ru_RU")
        return f
    }()

    private lazy var spinner: UIActivityIndicatorView = {
        let v = UIActivityIndicatorView(style: .medium)
        v.hidesWhenStopped = true
        return v
    }()
    private var currentImageURL: String?
    
    private var shimmerLayers: [CALayer] = []

    override func awakeFromNib() {
        super.awakeFromNib()
        let start = UIColor(red: 26/255, green: 27/255, blue: 34/255, alpha: 0.0)
        let end   = UIColor(red: 26/255, green: 27/255, blue: 34/255, alpha: 0.2)
        gradientLayer.colors = [start.cgColor, end.cgColor]
        gradientLayer.locations = [0, 1]
        imageCellView.layer.addSublayer(gradientLayer)
        selectionStyle = .none

        imageCellView.addSubview(spinner)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: imageCellView.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: imageCellView.centerYAnchor)
        ])

        // ✅ для UI-тестов
        buttonCellView.accessibilityIdentifier = "LikeButton"
    }

    override func layoutSubviews() {
        super.layoutSubviews()
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
        currentImageURL = nil
        imageCellView.image = nil
        dateCellView.text = nil
        spinner.stopAnimating()
        buttonCellView.isEnabled = true
        ShimmerHelper.removeAll(&shimmerLayers)
    }

    func configure(with photo: Photo) {
        if let created = photo.createdAt {
            dateCellView.text = dateFormatter.string(from: created)
        } else {
            dateCellView.text = "—"
        }

        let likeImage = photo.isLiked
            ? UIImage(named: "Active")
            : UIImage(named: "No Active")
        buttonCellView.setImage(likeImage, for: .normal)

        imageCellView.image = UIImage(named: "Stub")
        spinner.startAnimating()

        ShimmerHelper.removeAll(&shimmerLayers)
        let shimmer = ShimmerHelper.add(to: imageCellView, cornerRadius: 12)
        shimmerLayers.append(shimmer)

        currentImageURL = photo.thumbImageURL
        let expectedURL = currentImageURL

        ImageLoader.shared.loadImage(from: photo.thumbImageURL) { [weak self] image in
            guard let self = self else { return }
            guard self.currentImageURL == expectedURL else { return }

            self.imageCellView.image = image ?? UIImage(named: "Stub")
            self.spinner.stopAnimating()
            ShimmerHelper.removeAll(&self.shimmerLayers)

            if let table = self.superview as? UITableView,
               let indexPath = table.indexPath(for: self) {
                table.reloadRows(at: [indexPath], with: .automatic)
            }
        }
    }
    
    func setLikeButtonEnabled(_ enabled: Bool) {
        buttonCellView.isEnabled = enabled
    }
}

