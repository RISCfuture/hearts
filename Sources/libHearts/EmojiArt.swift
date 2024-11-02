import Foundation
@preconcurrency import CoreImage
import libCommon

public actor EmojiArt {
    public static let defaultCoherency: Float = 0.2
    public var backgroundColor = Color.black
    public func setBackgroundColor(_ color: Color) { backgroundColor = color }

    public let characters: Set<Character>
    
    public init(coherency: Float = EmojiArt.defaultCoherency) async throws {
        try await self.init(characters: ColorData.shared.emojiWithCoherency(coherency))
    }
    
    public init(characters: Set<Character>) throws {
        self.characters = characters
    }
    
    public init(group: String) async throws {
        try await self.init(characters: Groups.shared.characters(for: group))
    }
    
    public init(groups: Array<String>) async throws {
        try await self.init(characters: Groups.shared.characters(for: groups))
    }
    
    public func process(image: CIImage) async throws -> String {
        let chars = try await withThrowingTaskGroup(of: (Int, Character).self, returning: Array<Character>.self) { group in
            guard let cgImage = cgImage(from: image),
                  let pixels = cgImagePixels(cgImage) else { throw Error.badImage }

            var array = Array(repeating: Character("."), count: Int(image.extent.width * image.extent.height))

            for (n, pixel) in pixels.enumerated() {
                group.addTask {
                    let char = await self.closestEmoji(for: try pixel.premultiply(background: self.backgroundColor)) ?? " "
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
    
    private func closestEmoji(for color: Color) async -> Character? {
        var min: Character? = nil, minDist: Float? = nil
        for character in characters {
            let charColor = await ColorData.shared.for(character)!,
                dist = distance2(charColor.mean, color)

            guard min != nil, minDist != nil else {
                min = character
                minDist = dist
                continue
            }
            if dist < minDist! {
                min = character
                minDist = dist
            }
        }

        return min
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
