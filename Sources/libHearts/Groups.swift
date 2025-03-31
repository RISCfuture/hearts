import Foundation

actor Groups {
    static let shared = try! Groups() // swiftlint:disable:this force_try

    private let dataURL = Bundle.module.url(forResource: "groups", withExtension: "json")!
    private let groups: [String: Set<Character>]

    private init() throws {
        let groups = try JSONSerialization.jsonObject(with: Data(contentsOf: dataURL)) as! [String: String]
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
