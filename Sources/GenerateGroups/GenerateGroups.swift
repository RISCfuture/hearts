import ArgumentParser
import Foundation

private let customGroups = [
  "hearts": "❤️🧡💛💚🩵💙💜🤎🖤🤍"
]

@main
struct GenerateGroups: AsyncParsableCommand {
  @Option(
    name: .shortAndLong,
    help: "The Unicode Emoji specification version"
  )
  var emojiVersion = "16.0"

  @Argument(
    help: "The .json file to write to",
    completion: .file(extensions: [".json"]),
    transform: { .init(filePath: $0) }
  )
  var output = URL(filePath: "groups.json")

  private var url: URL {
    .init(string: "https://unicode.org/Public/emoji/\(emojiVersion)/emoji-test.txt")!
  }

  mutating func run() async throws {
    let data = try await loadGroupsData()
    let groups = try await parseGroups(data: data)

    let jsonData = try await groups.toJSON()
    try jsonData.write(to: output)
  }

  private func loadGroupsData() async throws -> URLSession.AsyncBytes {
    let session = URLSession(configuration: .ephemeral)
    let request = URLRequest(url: url)
    let (bytes, response) = try await session.bytes(for: request)
    guard let response = response as? HTTPURLResponse else {
      throw Error.invalidResponse
    }
    guard response.statusCode / 100 == 2 else {
      throw Error.invalidResponse
    }

    return bytes
  }

  private func parseGroups(data: URLSession.AsyncBytes) async throws -> Groups {
    let groups = Groups()

    for try await line in data.lines {
      guard !line.isEmpty else { continue }

      if line.starts(with: "# group: ") {
        let group = String(line.suffix(from: line.index(line.startIndex, offsetBy: 9)))
        groups.currentGroup = group
      } else if line.starts(with: "# subgroup: ") {
        let subgroup = String(line.suffix(from: line.index(line.startIndex, offsetBy: 12)))
        groups.currentSubgroup = subgroup
      } else if line.starts(with: "#") {
        continue
      } else {
        guard let char = try parseEmoji(from: line) else { continue }
        try await groups.addChar(char)
      }
    }

    return groups
  }

  private func parseEmoji(from line: String) throws -> Character? {
    let parts = line.split(separator: ";")
    guard parts[1].trimmingCharacters(in: .whitespaces).starts(with: "fully-qualified") else {
      return nil
    }

    let codepointsString = parts[0].trimmingCharacters(in: .whitespaces)
    let codepointsStrings = codepointsString.split(separator: " ")
    let codepoints = try codepointsStrings.map { codepointStr in
      guard let val = Int(codepointStr, radix: 16) else { throw Error.badFormat }
      return val
    }
    .map { codepoint in
      guard let scalar = UnicodeScalar(codepoint) else { throw Error.badFormat }
      return scalar
    }

    var string = ""
    string.unicodeScalars.append(contentsOf: codepoints)
    return string.first!
  }
}

enum Error: Swift.Error {
  case invalidResponse
  case badFormat
}

actor Group {
  var name: String
  private var subgroups: [Subgroup] = []

  var allChars: String {
    get async {
      var allChars = ""
      for subgroup in subgroups {
        await allChars.append(contentsOf: subgroup.allChars)
      }
      return allChars
    }
  }

  init(name: String) {
    self.name = name
  }

  func subgroup(_ name: String) async -> Subgroup {
    for subgroup in subgroups where await subgroup.name == name {
      return subgroup
    }

    let subgroup = Subgroup(name: name)
    subgroups.append(subgroup)
    return subgroup
  }

  func eachSubgroup(callback: (Subgroup) async -> Void) async {
    for subgroup in subgroups { await callback(subgroup) }
  }

  actor Subgroup {
    var name: String
    private var characters: [Character] = []

    var allChars: String {
      return String(characters)
    }

    init(name: String) {
      self.name = name
    }

    func addChar(_ char: Character) {
      characters.append(char)
    }
  }
}

class Groups {
  private var groups: [Group] = []
  private var groupsMutex = DispatchSemaphore(value: 1)

  var currentGroup: String? {
    willSet { groupsMutex.wait() }
    didSet { groupsMutex.signal() }
  }
  var currentSubgroup: String? {
    willSet { groupsMutex.wait() }
    didSet { groupsMutex.signal() }
  }

  private let allowedNameChars = CharacterSet.alphanumerics.union(CharacterSet.newlines)

  func addChar(_ char: Character) async throws {
    guard let currentGroup,
      let currentSubgroup
    else {
      throw Error.badFormat
    }
    await group(currentGroup).subgroup(currentSubgroup).addChar(char)
  }

  func group(_ name: String) async -> Group {
    let normalizedName = name.lowercased()
      .replacingCharacters(in: allowedNameChars.inverted, with: " ")
      .replacingCharacters(in: .whitespaces, with: "-", collapseConsecutive: true)

    for group in groups where await group.name == normalizedName {
      return group
    }
    let group = Group(name: normalizedName)
    groups.append(group)
    return group
  }

  func toJSON() async throws -> Data {
    var dict = [String: String]()

    for group in groups {
      await dict[group.name] = await group.allChars
      await group.eachSubgroup { subgroup in
        await dict[subgroup.name] = subgroup.allChars
      }
    }

    dict.merge(customGroups, uniquingKeysWith: { $0 + $1 })

    return try JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys])
  }
}
