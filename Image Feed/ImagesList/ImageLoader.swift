import UIKit

final class ImageLoader {
    static let shared = ImageLoader()

    private let cache = NSCache<NSString, UIImage>()
    private init() {}

    func loadImage(from urlString: String, completion: @escaping (UIImage?) -> Void) {
        if let cached = cache.object(forKey: urlString as NSString) {
            completion(cached)
            return
        }
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self,
                  let data,
                  let image = UIImage(data: data) else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            self.cache.setObject(image, forKey: urlString as NSString)
            DispatchQueue.main.async { completion(image) }
        }.resume()
    }
}

