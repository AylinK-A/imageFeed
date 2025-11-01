import UIKit

final class TabBarController: UITabBarController {

    override func awakeFromNib() {
        super.awakeFromNib()
        setupViewControllers()
        configureAppearance()
    }

    private func setupViewControllers() {
        let storyboard = UIStoryboard(name: "Main", bundle: .main)

        let imagesListViewController = storyboard.instantiateViewController(withIdentifier: "ImagesListViewController") as! ImagesListViewController
        imagesListViewController.tabBarItem = UITabBarItem(
            title: "",
            image: UIImage(named: "ImagesList"),
            selectedImage: nil
        )

        let imagesService = ImageListService()
        let imagesPresenter = ImagesListPresenter(service: imagesService)
        imagesListViewController.presenter = imagesPresenter
        imagesPresenter.view = imagesListViewController

        let profileViewController = ProfileViewController()
        profileViewController.tabBarItem = UITabBarItem(
            title: "",
            image: UIImage(named: "ActiveProfile"),
            selectedImage: nil
        )
        let presenter = ProfilePresenter(
            profileService: ProfileService.shared,
            imageServiceType: ProfileImageService.self,
            imageService: ProfileImageService.shared,
            logoutService: ProfileLogoutService.shared
        )
        profileViewController.presenter = presenter
        presenter.view = profileViewController

        self.viewControllers = [imagesListViewController, profileViewController]
    }

    private func configureAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .ypBlack
        appearance.shadowColor = .clear
        appearance.backgroundEffect = nil

        tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = appearance
        }

        tabBar.isTranslucent = false
        tabBar.tintColor = .ypBlue
        tabBar.unselectedItemTintColor = .ypGrey
    }
}

