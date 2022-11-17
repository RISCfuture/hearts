import Foundation
import CoreImage
import libCommon

public class EmojiArt {
    public static let defaultCoherency: Float = 0.2
    public var backgroundColor = Color.black
    
    public let characters: Set<Character>
    
    public convenience init(coherency: Float = EmojiArt.defaultCoherency) throws {
        try self.init(characters: ColorData.shared.emojiWithCoherency(coherency))
    }
    
    public init(characters: Set<Character>) throws {
        self.characters = characters
    }
    
    public convenience init(group: String) throws {
        try self.init(characters: Groups.shared.characters(for: group))
    }
    
    public convenience init(groups: Array<String>) throws {
        try self.init(characters: Groups.shared.characters(for: groups))
    }
    
    public func process(image: CIImage) async throws -> String {
        let chars = try await withThrowingTaskGroup(of: (Int, Character).self, returning: Array<Character>.self) { group in
            guard let cgImage = cgImage(from: image),
                  let pixels = cgImagePixels(cgImage) else { throw Error.badImage }

            var array = Array(repeating: Character("."), count: Int(image.extent.width * image.extent.height))

            for (n, pixel) in pixels.enumerated() {
                group.addTask {
                    let char = self.closestEmoji(for: try pixel.premultiply(background: self.backgroundColor)) ?? " "
                    return (n, char)
                }
            }

            for try await pair in group { array[pair.0] = pair.1 }
            return array
        }
        
        return chars
            .inGroupsOf(Int(image.extent.width))
            .map { String($0) }
            .joined(separator: "\n")
    }
    
    private func closestEmoji(for color: Color) -> Character? {
        characters.min(by: { char1, char2 in
            let char1Color = ColorData.shared.for(char1)!
            let char2Color = ColorData.shared.for(char2)!
            let dist1 = distance2(char1Color.mean, color)
            let dist2 = distance2(char2Color.mean, color)
            return dist1 < dist2
        })
    }
    
    private func distance2(_ a: Color, _ b: Color) -> Float {
        // https://en.wikipedia.org/wiki/Color_difference
        
        let rMean = (a.red + b.red)/2
        let delR2 = pow(a.red - b.red, 2),
            delG2 = pow(a.green - b.green, 2),
            delB2 = pow(a.blue - b.blue, 2)
        
        let rFactor, gFactor, bFactor: Float
        if rMean < 0.5 {
            rFactor = 2
            gFactor = 4
            bFactor = 3
        } else {
            rFactor = 3
            gFactor = 4
            bFactor = 2
        }
        
        return rFactor*delR2 + gFactor*delG2 + bFactor*delB2
    }
}
