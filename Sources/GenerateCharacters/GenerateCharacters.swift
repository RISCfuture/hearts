import Foundation
import ArgumentParser

@main
struct GenerateCharacters: AsyncParsableCommand {
    @Option(name: .shortAndLong,
            help: "The Unicode Emoji specification version")
    var emojiVersion = "15.0"

    @Argument(help: "The .txt file to write to",
              completion: .file(extensions: [".txt"]),
              transform: { URL(filePath: $0) })
    var output = URL(filePath: "characters.txt")
    
    private var sequencesURL: URL { .init(string: "https://unicode.org/Public/emoji/\(emojiVersion)/emoji-sequences.txt")! }
    private var zwjSequencesURL: URL { .init(string: "https://unicode.org/Public/emoji/\(emojiVersion)/emoji-zwj-sequences.txt")! }
    
    mutating func run() async throws {
        let characters = try await parseURL(sequencesURL) + parseURL(zwjSequencesURL)
        
        let data = characters.data(using: .unicode)!
        try data.write(to: output)
    }
    
    private func parseURL(_ url: URL) async throws -> String {
        let session = URLSession(configuration: .ephemeral)
        let request = URLRequest(url: url)
        let (bytes, response) = try await session.bytes(for: request)
        guard let response = response as? HTTPURLResponse else {
            throw Error.invalidResponse
        }
        guard response.statusCode / 100 == 2 else {
            throw Error.invalidResponse
        }
        
        return try await parseSequences(data: bytes)
    }
    
    private func parseSequences(data: URLSession.AsyncBytes) async throws -> String {
        var string = ""
        
        for try await line in data.lines {
            guard !line.isEmpty else { continue }
            guard !line.starts(with: "#") else { continue }
            
            let codepointsString = line.split(separator: ";")[0]
            let codepointsStrings = codepointsString.trimmingCharacters(in: .whitespaces).split(separator: " ")
            let codepoints = try codepointsStrings.map { try parseCodepointString(String($0), allowRanges: true) }
            
            for codepoint in codepoints[0] {
                guard let firstScalar = UnicodeScalar(Int(codepoint)) else {
                    throw Error.unknownCharacter(codepoint)
                }
                var scalars = try codepoints.suffix(from: 1).map { cp in
                    guard cp.single else {
                        throw Error.badFormat
                    }
                    guard let scalar = UnicodeScalar(Int(cp.lowerBound)) else {
                        throw Error.unknownCharacter(cp.lowerBound)
                    }
                    return scalar
                }
                scalars.insert(firstScalar, at: 0)
                
                string.unicodeScalars.append(contentsOf: scalars)
            }
        }
        
        return string
    }
    
    private func parseCodepointString(_ string: String, allowRanges: Bool = false) throws -> ClosedRange<UInt> {
        if allowRanges {
            let substrings = string.split(separator: "..")
            switch substrings.count {
                case 1:
                    let scalar = try parseCodepointString(String(substrings[0]))
                    return scalar
                case 2:
                    let from = try parseCodepointString(String(substrings[0]))
                    let to = try parseCodepointString(String(substrings[1]))
                    return from.lowerBound...to.lowerBound
                default:
                    throw Error.badFormat
            }
        } else {
            guard let codepoint = UInt(string, radix: 16) else {
                throw Error.badFormat
            }
            return codepoint...codepoint
        }
    }
}

enum Error: Swift.Error {
    case invalidResponse
    case badFormat
    case unknownCharacter(_ codepoint: UInt)
}
