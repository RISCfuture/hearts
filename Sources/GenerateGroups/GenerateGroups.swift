import Foundation
import ArgumentParser
import Dispatch

fileprivate let customGroups = [
    "hearts": "❤️🧡💛💚💙💜🤎🖤🤍"
]

@main
struct GenerateGroups: AsyncParsableCommand {
    @Option(name: .shortAndLong,
            help: "The Unicode Emoji specification version")
    var emojiVersion = "16.0"

    @Argument(help: "The .json file to write to",
              completion: .file(extensions: [".json"]),
              transform: { URL(filePath: $0) })
    var output = URL(filePath: "groups.json")
    
    private var url: URL { .init(string: "https://unicode.org/Public/emoji/\(emojiVersion)/emoji-test.txt")! }
    
    mutating func run() async throws {
        let data = try await loadGroupsData()
        let groups = try await parseGroups(data: data)
        
        let jsonData = try groups.toJSON()
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
                try groups.addChar(char)
            }
        }
        
        return groups
    }

    private func parseEmoji(from line: String) throws -> Character? {
        let parts = line.split(separator: ";")
        guard parts[1].trimmingCharacters(in: .whitespaces).starts(with: "fully-qualified") else { return nil }

        let codepointsString = parts[0].trimmingCharacters(in: .whitespaces)
        let codepointsStrings = codepointsString.split(separator: " ")
        let codepoints = try codepointsStrings.map {
            guard let val = Int($0, radix: 16) else { throw Error.badFormat }
            return val
        }.map {
            guard let scalar = UnicodeScalar($0) else { throw Error.badFormat }
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

class Group {
    var name: String
    private var subgroups: Array<Subgroup> = []
    private var subgroupsMutex = DispatchSemaphore(value: 1)
    
    
    init(name: String) {
        self.name = name
    }
    
    func subgroup(_ name: String) -> Subgroup {
        subgroupsMutex.wait()
        defer { subgroupsMutex.signal() }
        
        if let subgroup = subgroups.first(where: { $0.name == name }) {
            return subgroup
        } else {
            let subgroup = Subgroup(name: name)
            subgroups.append(subgroup)
            return subgroup
        }
    }
    
    func eachSubgroup(callback: (Subgroup) -> Void) {
        subgroupsMutex.wait()
        defer { subgroupsMutex.signal() }
        
        for subgroup in subgroups { callback(subgroup) }
    }
    
    var allChars: String {
        subgroupsMutex.wait()
        defer { subgroupsMutex.signal() }
        
        return subgroups.map { $0.allChars }.joined()
    }
    
    class Subgroup {
        var name: String
        private var characters: Array<Character> = []
        private var charsMutex = DispatchSemaphore(value: 1)
        
        init(name: String) {
            self.name = name
        }
        
        func addChar(_ char: Character) {
            charsMutex.wait()
            defer { charsMutex.signal() }
            
            characters.append(char)
        }
        
        var allChars: String {
            charsMutex.wait()
            defer { charsMutex.signal() }
            
            return String(characters)
        }
    }
}

class Groups {
    private var groups: Array<Group> = []
    private var groupsMutex = DispatchSemaphore(value: 1)
    
    var currentGroup: String? = nil {
        willSet { groupsMutex.wait() }
        didSet { groupsMutex.signal() }
    }
    var currentSubgroup: String? = nil {
        willSet { groupsMutex.wait() }
        didSet { groupsMutex.signal() }
    }
    
    private let allowedNameChars = CharacterSet.alphanumerics.union(CharacterSet.newlines)
    
    func addChar(_ char: Character) throws {
        groupsMutex.wait()
        defer { groupsMutex.signal() }
        
        guard let currentGroup = currentGroup,
              let currentSubgroup = currentSubgroup else {
            throw Error.badFormat
        }
        group(currentGroup).subgroup(currentSubgroup).addChar(char)
    }
    
    func group(_ name: String) -> Group {
        let normalizedName = name.lowercased()
            .replacingCharacters(in: allowedNameChars.inverted, with: " ")
            .replacingCharacters(in: .whitespaces, with: "-", collapseConsecutive: true)
        
        if let group = groups.first(where: { $0.name == normalizedName }) {
            return group
        } else {
            let group = Group(name: normalizedName)
            groups.append(group)
            return group
        }
    }
    
    func toJSON() throws -> Data {
        groupsMutex.wait()
        defer { groupsMutex.signal() }
        
        var dict = Dictionary<String, String>()
        
        for group in groups {
            dict[group.name] = group.allChars
            group.eachSubgroup { subgroup in
                dict[subgroup.name] = subgroup.allChars
            }
        }
        
        dict.merge(customGroups, uniquingKeysWith: { $0 + $1 })
        
        return try JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys])
    }
}
