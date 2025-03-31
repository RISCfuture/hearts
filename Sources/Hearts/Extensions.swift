import CoreImage
import Foundation

extension Character {
    var containsEmoji: Bool { unicodeScalars.contains(where: \.properties.isEmoji) }
}
