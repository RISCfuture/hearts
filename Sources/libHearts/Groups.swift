import Foundation

struct Groups: Sendable {
  static let shared = try! Self()  // swiftlint:disable:this force_try

  private let groups: [String: Set<Character>]

  private init() throws {
    let dataURL = Bundle.module.url(forResource: "groups", withExtension: "json")!
    let groups =
      try JSONSerialization.jsonObject(with: Data(contentsOf: dataURL)) as! [String: String]
    self.groups = groups.reduce(into: [:]) { dict, entry in
      dict[entry.key] = Set(entry.value)
    }
  }

  func characters(for groupName: String) -> Set<Character> {
    characters(for: [groupName])
  }

  func characters(for groupNames: [String]) -> Set<Character> {
    groupNames.map { groups[$0] ?? Set() }.reduce(into: Set()) { superset, subset in
      superset.formUnion(subset)
    }
  }
}
