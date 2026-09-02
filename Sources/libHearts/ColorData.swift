import Foundation
import libCommon

struct ColorData: Sendable {
  static let shared = try! Self()  // swiftlint:disable:this force_try

  private let characters: [Character: EmojiColorData]

  private init() throws {
    let dataURL = Bundle.module.url(forResource: "colors", withExtension: "json")!
    let data = try JSONSerialization.jsonObject(with: Data(contentsOf: dataURL)) as! [[Any]]

    characters = try data.reduce(into: [:]) { chars, item in
      let str = item[0] as! String
      let r = item[1] as! NSNumber
      let g = item[2] as! NSNumber
      let b = item[3] as! NSNumber
      let sdr = item[4] as! NSNumber
      let sdg = item[5] as! NSNumber
      let sdb = item[6] as! NSNumber

      chars[str.first!] = try .init(
        mean: .init(red: r.floatValue, green: g.floatValue, blue: b.floatValue),
        standardDeviation: .init(red: sdr.floatValue, green: sdg.floatValue, blue: sdb.floatValue)
      )
    }
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

  struct EmojiColorData: Sendable {
    let mean: Color
    let standardDeviation: Color

    func hasCoherency(_ coherency: Float) -> Bool {
      standardDeviation.red <= coherency && standardDeviation.green <= coherency
        && standardDeviation.blue <= coherency
    }
  }
}
