import Foundation

extension String {
  func replacingCharacters(
    in set: CharacterSet,
    with replacement: String,
    collapseConsecutive: Bool = false
  ) -> String {
    var result = ""
    for char in self {
      if set.contains(char.unicodeScalars.first!) {
        if collapseConsecutive && result.hasSuffix(replacement) { continue }
        result.append(replacement)
      } else {
        result.append(char)
      }
    }

    return result
  }

  func removingCharacters(in set: CharacterSet) -> String {
    var result = ""
    for char in self where !set.contains(char.unicodeScalars.first!) {
      result.append(char)
    }
    return result
  }
}
