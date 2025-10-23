import UIKit

enum ShimmerHelper {
    @discardableResult
    static func add(to view: UIView,
                    cornerRadius: CGFloat = 8,
                    colors: [CGColor] = [
                        UIColor(red: 0.682, green: 0.686, blue: 0.706, alpha: 1).cgColor,
                        UIColor(red: 0.531, green: 0.533, blue: 0.553, alpha: 1).cgColor,
                        UIColor(red: 0.431, green: 0.433, blue: 0.453, alpha: 1).cgColor
                    ],
                    locations fromLocations: [NSNumber] = [0, 0.1, 0.3],
                    toLocations: [NSNumber] = [0, 0.8, 1],
                    duration: CFTimeInterval = 1.0) -> CAGradientLayer {

        view.layoutIfNeeded()

        let gradient = CAGradientLayer()
        gradient.frame = view.bounds
        gradient.colors = colors
        gradient.locations = fromLocations
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint   = CGPoint(x: 1, y: 0.5)
        gradient.cornerRadius = cornerRadius
        gradient.masksToBounds = true

        view.layer.addSublayer(gradient)

        // Анимация с бесконечным повтором
        let anim = CABasicAnimation(keyPath: "locations")
        anim.fromValue = fromLocations
        anim.toValue   = toLocations
        anim.duration  = duration
        anim.repeatCount = .infinity
        gradient.add(anim, forKey: "locationsChange")

        return gradient
    }

    static func remove(_ layer: CALayer?) {
        layer?.removeAllAnimations()
        layer?.removeFromSuperlayer()
    }

    static func removeAll(_ layers: inout [CALayer]) {
        layers.forEach { $0.removeAllAnimations(); $0.removeFromSuperlayer() }
        layers.removeAll()
    }
}

