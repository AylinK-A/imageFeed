import UIKit
import Kingfisher
import SwiftKeychainWrapper

final class ProfileViewController: UIViewController {
    
    var delegate = SplashViewController()
    private var oauth2TokenStorage = OAuth2TokenStorage()
    private let profileService = ProfileService.shared
    private let profileImageService = ProfileImageService.shared
    
    private var nameLabel = UILabel()
    private var loginNameLabel = UILabel()
    private var descriptionLabel = UILabel()
    private var profileImage = UIImage(named: "Ekat_nov")
    private var imageView = UIImageView()
    private var profileImageServiceObserver: NSObjectProtocol?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        profileImageServiceObserver = NotificationCenter.default.addObserver(
            forName: ProfileImageService.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else {
                debugPrint("no self in viewDidLoad -> ProfileViewController")
                return }
            self.updateAvatar()
        }
        view.backgroundColor = UIColor(red: 26/255.0, green: 27/255.0, blue: 34/255.0, alpha: 1)
        profileSetup()
    }
    
    private func updateAvatar() {
        guard
            let profileImageURL = profileImageService.avatarURL,
            let url = URL(string: profileImageURL)
        else {
            debugPrint("No url for image in profileImageURL \(String(describing: profileImageService.avatarURL))")
            return
        }
        let processor = RoundCornerImageProcessor(cornerRadius: 36, backgroundColor: .clear)
        imageView.kf.indicatorType = .activity
        imageView.kf.setImage(with: url,
                              options: [
                                .processor(processor),
                                .cacheSerializer(FormatIndicatedCacheSerializer.png)
                              ])
    }
    
    private func profileSetup() {
        view.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.heightAnchor.constraint(equalToConstant: 70).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: 70).isActive = true
        imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16).isActive = true
        imageView.topAnchor.constraint(equalTo: view.topAnchor, constant: 75).isActive = true
        
        let arrowButton = UIButton()
        let buttonImage = UIImage(named: "Exit")
        arrowButton.setImage(buttonImage, for: .normal)
        arrowButton.addTarget(self, action: #selector(logoutAction), for: .touchUpInside) // logout action
        view.addSubview(arrowButton)
        arrowButton.translatesAutoresizingMaskIntoConstraints = false
        arrowButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24).isActive = true
        arrowButton.centerYAnchor.constraint(equalTo: imageView.centerYAnchor).isActive = true
        
        nameLabel.text = "Екатерина Новикова"
        nameLabel.text = ""
        nameLabel.font = UIFont(name: "SFPro-Bold", size: 23)
        nameLabel.textColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        
        view.addSubview(nameLabel)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16).isActive = true
        nameLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8).isActive = true
        
        loginNameLabel.text = "@ekaterina_nov"
        loginNameLabel.text = ""
        loginNameLabel.font = UIFont(name: "SF Pro", size: 13)
        loginNameLabel.textColor = UIColor(red: 174/255.0, green: 175/255.0, blue: 180/255.0, alpha: 1.0)
        
        view.addSubview(loginNameLabel)
        loginNameLabel.translatesAutoresizingMaskIntoConstraints = false
        loginNameLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16).isActive = true
        loginNameLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8).isActive = true
        
        descriptionLabel.text = "Hello, world!"
        descriptionLabel.text = ""
        descriptionLabel.font = UIFont(name: "SF Pro", size: 13)
        descriptionLabel.textColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        
        view.addSubview(descriptionLabel)
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16).isActive = true
        descriptionLabel.topAnchor.constraint(equalTo: loginNameLabel.bottomAnchor, constant: 8).isActive = true
        
        guard let profile = profileService.profile else {return}
        updateProfileDetails(profile: profile)
        
    }
    
    private func updateProfileDetails(profile: Profile) {        
        nameLabel.text = (profile.name != nil) ? profile.name : "Екатерина Новикова"
        loginNameLabel.text = (profile.loginName != nil) ? profile.loginName : "@ekaterina_nov"
        descriptionLabel.text = (profile.bio != nil) ? profile.bio : "Hello, world!"
        updateAvatar()
    }
    
    private func checkIfTokenIsRemoved() {
        let keyValue = "bearerToken"
        let isSuccess: String? = KeychainWrapper.standard.string(forKey: keyValue)
        guard isSuccess != nil else {
            debugPrint("token value is nil: isSuccess -> ProfileViewController")
            return
        }
    }

    @objc private func logoutAction() {
        oauth2TokenStorage.token = ""
        let _: Bool = KeychainWrapper.standard.removeObject(forKey: "bearerToken")
        self.dismiss(animated: true)
        guard let window = UIApplication.shared.windows.first else {
            assertionFailure("Invalid windows configuration")
            return
        }
        let splashViewController = SplashViewController()
        splashViewController.modalTransitionStyle = .crossDissolve
        splashViewController.modalPresentationStyle = .fullScreen
        window.rootViewController = splashViewController
    }
    
}
