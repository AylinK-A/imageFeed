import UIKit
import Kingfisher
import SwiftKeychainWrapper

final class ProfileViewController: UIViewController {
    
    private let oauth2TokenStorage = OAuth2TokenStorage()
    private let profileService = ProfileService.shared
    private let profileImageService = ProfileImageService.shared
    private let logoutService = ProfileLogoutService.shared
    
    private var nameLabel = UILabel()
    private var loginNameLabel = UILabel()
    private var descriptionLabel = UILabel()
    private var imageView = UIImageView()
    private var profileImageServiceObserver: NSObjectProtocol?
    
    private var animationLayers: [CALayer] = []
    private var didStartShimmer = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        profileImageServiceObserver = NotificationCenter.default.addObserver(
            forName: ProfileImageService.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateAvatar()
        }
        
        view.backgroundColor = UIColor(red: 26/255, green: 27/255, blue: 34/255, alpha: 1)
        profileSetup()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !didStartShimmer {
            didStartShimmer = true
            
            let avatarLayer = ShimmerHelper.add(to: imageView, cornerRadius: 35)
            animationLayers.append(avatarLayer)
            
            let nameLayer  = ShimmerHelper.add(to: nameLabel, cornerRadius: 6)
            let loginLayer = ShimmerHelper.add(to: loginNameLabel, cornerRadius: 6)
            let bioLayer   = ShimmerHelper.add(to: descriptionLabel, cornerRadius: 6)
            animationLayers.append(contentsOf: [nameLayer, loginLayer, bioLayer])
        }
    }
    
    deinit {
        if let token = profileImageServiceObserver {
            NotificationCenter.default.removeObserver(token)
        }
        ShimmerHelper.removeAll(&animationLayers)
    }
    
    // MARK: - UI
    
    private func profileSetup() {
        // Avatar
        view.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.heightAnchor.constraint(equalToConstant: 70),
            imageView.widthAnchor.constraint(equalToConstant: 70),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            imageView.topAnchor.constraint(equalTo: view.topAnchor, constant: 75)
        ])
        
        // Logout button
        let logoutButton = UIButton(type: .system)
        if let exitImage = UIImage(named: "Exit")?.withRenderingMode(.alwaysOriginal) {
            logoutButton.setImage(exitImage, for: .normal)
        }
        logoutButton.addTarget(self, action: #selector(logoutAction), for: .touchUpInside)

        view.addSubview(logoutButton)
        logoutButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            logoutButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            logoutButton.centerYAnchor.constraint(equalTo: imageView.centerYAnchor)
        ])
        
        // Name
        nameLabel.font = UIFont(name: "SFPro-Bold", size: 23)
        nameLabel.textColor = .white
        nameLabel.text = " "
        view.addSubview(nameLabel)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            nameLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8),
            nameLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            nameLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 24)
        ])
        
        // Login
        loginNameLabel.font = UIFont(name: "SF Pro", size: 13)
        loginNameLabel.textColor = UIColor(red: 174/255, green: 175/255, blue: 180/255, alpha: 1)
        loginNameLabel.text = " "
        view.addSubview(loginNameLabel)
        loginNameLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            loginNameLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            loginNameLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            loginNameLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            loginNameLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 16)
        ])
        
        // Bio
        descriptionLabel.font = UIFont(name: "SF Pro", size: 13)
        descriptionLabel.textColor = .white
        descriptionLabel.text = " "
        view.addSubview(descriptionLabel)
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            descriptionLabel.topAnchor.constraint(equalTo: loginNameLabel.bottomAnchor, constant: 8),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            descriptionLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 16)
        ])
        
        if let profile = profileService.profile {
            updateProfileDetails(profile: profile)
        }
    }
    
    private func updateProfileDetails(profile: Profile) {
        nameLabel.text = profile.name ?? "—"
        loginNameLabel.text = profile.loginName ?? "—"
        descriptionLabel.text = profile.bio ?? ""
        
        if !animationLayers.isEmpty {
            ShimmerHelper.removeAll(&animationLayers)
            let avatarLayer = ShimmerHelper.add(to: imageView, cornerRadius: 35)
            animationLayers.append(avatarLayer)
        }

        updateAvatar()
    }
    
    private func updateAvatar() {
        guard
            let profileImageURL = profileImageService.avatarURL,
            let url = URL(string: profileImageURL)
        else { return }
        
        let processor = RoundCornerImageProcessor(cornerRadius: 36, backgroundColor: .clear)
        imageView.kf.indicatorType = .activity
        imageView.kf.setImage(
            with: url,
            options: [
                .processor(processor),
                .cacheSerializer(FormatIndicatedCacheSerializer.png)
            ],
            completionHandler: { [weak self] _ in
                guard let self else { return }
                ShimmerHelper.removeAll(&self.animationLayers)
            }
        )
    }
    
    // MARK: - Logout
    
    @objc private func logoutAction() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .alert)

        let title = NSAttributedString(
            string: "Пока, пока!",
            attributes: [
                .font: UIFont.systemFont(ofSize: 17, weight: .semibold),
                .foregroundColor: UIColor.label
            ]
        )
        alert.setValue(title, forKey: "attributedTitle")

        let message = NSAttributedString(
            string: "Уверены, что хотите выйти?",
            attributes: [
                .font: UIFont.systemFont(ofSize: 13, weight: .regular),
                .foregroundColor: UIColor.black
            ]
        )
        alert.setValue(message, forKey: "attributedMessage")

        let yesAction = UIAlertAction(title: "Да", style: .default) { _ in
            ProfileLogoutService.shared.logout()
        }
        let noAction = UIAlertAction(title: "Нет", style: .default)

        alert.addAction(yesAction)
        alert.addAction(noAction)

        present(alert, animated: true)
    }
}

