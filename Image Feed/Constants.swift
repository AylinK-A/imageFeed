import UIKit

enum Constants {
    static let accessKey = "ZX18JHY1RJMv60uy8N3K3qd7MdeBwaPL6w_HYthOXsQ"
    static let secretKey = "C-FvfeGdGToXGORv4w9hne0AZoUMtfV0juAmErv2BEc"
    static let redirectURI = "urn:ietf:wg:oauth:2.0:oob"
    static let accessScope = "public+read_user+write_likes"
    static let baseURLString = "https://unsplash.com"
    static let finalURLString = baseURLString + "/oauth/token"
    static let baseAPIURLString = "https://api.unsplash.com"
    static let finaAPIlURLString = URL(string: baseAPIURLString + "/me")
    
    static let defaultBaseURL = URL(string: "https://api.unsplash.com")
}





