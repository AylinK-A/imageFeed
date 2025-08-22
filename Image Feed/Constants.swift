//
//  Constants.swift
//  Image Feed
//
//  Created by Айлин Кызылай on 12.08.2025.
//
import Foundation

enum Constants{
    static let accessKey = "ZX18JHY1RJMv60uy8N3K3qd7MdeBwaPL6w_HYthOXsQ"
    static let secretKey = "C-FvfeGdGToXGORv4w9hne0AZoUMtfV0juAmErv2BEc"
    static let redirectURI = "urn:ietf:wg:oauth:2.0:oob"
    static let accessScope = "public+read_user+write_likes"
    static let tokenURL = URL(string: "https://unsplash.com/oauth/token")!
    static let defaultBaseURL: URL = {
        guard let url = URL(string: "https://api.unsplash.com") else {
            preconditionFailure("Invalid Unsplash base URL")
        }
        return url
    }()
}
