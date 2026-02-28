import UIKit

enum Font {
    static func roundedName(weight: UIFont.Weight) -> String {
        let base = UIFont.systemFont(ofSize: 17, weight: weight)
        guard let descriptor = base.fontDescriptor.withDesign(.rounded) else {
            return base.fontName
        }
        return UIFont(descriptor: descriptor, size: 17).fontName
    }
}
