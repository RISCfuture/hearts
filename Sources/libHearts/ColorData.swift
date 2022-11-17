import Foundation
import libCommon

final class ColorData {
    static let shared = try! ColorData()
    
    private let dataURL = Bundle.module.url(forResource: "colors", withExtension: "json")!
    private let characters: Dictionary<Character, EmojiColorData>
    
    var allEmoji: Set<Character> { Set(characters.keys) }
    
    private init() throws {
        var chars = Dictionary<Character, EmojiColorData>()
        
        let data = try JSONSerialization.jsonObject(with: Data(contentsOf: dataURL)) as! Array<Array<Any>>
        for item in data {
            let str = item[0] as! String
            let r = item[1] as! NSNumber
            let g = item[2] as! NSNumber
            let b = item[3] as! NSNumber
            let sdr = item[4] as! NSNumber
            let sdg = item[5] as! NSNumber
            let sdb = item[6] as! NSNumber
            
            chars[str.first!] = try .init(mean: .init(red: r.floatValue, green: g.floatValue, blue: b.floatValue),
                                      standardDeviation: .init(red: sdr.floatValue, green: sdg.floatValue, blue: sdb.floatValue))
        }
        
        self.characters = chars
    }
    
    func `for`(_ character: Character) -> EmojiColorData? {
        return characters[character]
    }
    
    func emojiWithCoherency(_ coherency: Float) -> Set<Character> {
        characters.reduce(into: Set()) { `set`, entry in
            if entry.value.hasCoherency(coherency) {
                set.insert(entry.key)
            }
        }
    }
    
    struct EmojiColorData {
        let mean: Color
        let standardDeviation: Color
        
        func hasCoherency(_ coherency: Float) -> Bool {
            standardDeviation.red <= coherency &&
            standardDeviation.green <= coherency &&
            standardDeviation.blue <= coherency
        }
    }
}
