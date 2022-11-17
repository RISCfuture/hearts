import Foundation
import CoreImage

extension Character {
    var containsEmoji: Bool { unicodeScalars.contains(where: { $0.properties.isEmoji }) }
}
