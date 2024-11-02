import Foundation
import CoreGraphics
import CoreText
import ArgumentParser
import Progress
import libCommon

@main
struct GenerateColors: AsyncParsableCommand {
    @Argument(help: "The .json file to write to",
              completion: .file(extensions: [".json"]),
              transform: { URL(filePath: $0) })
    var output = URL(filePath: "colors.json")
    
    private static let charactersURL = Bundle.module.url(forResource: "characters", withExtension: "txt")!
    
    private var characters: String {
        let data = try! Data(contentsOf: Self.charactersURL)
        return String(data: data, encoding: .unicode)!
    }
    
    mutating func run() async throws {
        await ProgressWrapper.shared.setTotal(characters.count)

        let averages = try await averageColors().map { (character, data) in
            [String(character),
             data.mean.red, data.mean.green, data.mean.blue,
             data.standardDeviation.red, data.standardDeviation.green, data.standardDeviation.blue]
        }
        
        let data = try JSONSerialization.data(withJSONObject: averages, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: output)
    }
    
    private func characterToImage(_ character: Character, extent: Int = 216) async throws -> CGImage {
        return try await withCheckedThrowingContinuation { continuation in
            guard let colorspace = CGColorSpace(name: CGColorSpace.sRGB) else {
                continuation.resume(with: .failure(Error.drawingError))
                return
            }
            guard let context = CGContext(data: nil,
                                          width: extent,
                                          height: extent,
                                          bitsPerComponent: 8,
                                          bytesPerRow: 0,
                                          space: colorspace,
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
                continuation.resume(with: .failure(Error.drawingError))
                return
            }
            
            let path = CGPath(rect: CGRect(x: 0, y: 0, width: extent, height: extent), transform: nil)
            let font = CTFont(.system, size: CGFloat(Double(extent)*0.75))
            let attributes = [
                kCTFontAttributeName: font
            ]
            let cfString = String(character) as CFString
            let attrString = CFAttributedStringCreate(nil, cfString, attributes as CFDictionary)!
            
            let framesetter = CTFramesetterCreateWithAttributedString(attrString)
            let frame = CTFramesetterCreateFrame(framesetter, CFRange(location: 0, length: CFStringGetLength(cfString)), path, nil)
            CTFrameDraw(frame, context)
            
            context.flush()
            
            guard let image = context.makeImage() else {
                continuation.resume(with: .failure(Error.drawingError))
                return
            }
            
            continuation.resume(with: .success(image))
        }
    }
    
    private func characterImages() async throws -> Array<(Character, CGImage)> {
        try await withThrowingTaskGroup(of: (Character, CGImage).self) { group in
            var images = Array<(Character, CGImage)>()
            images.reserveCapacity(characters.count)
            
            for character in characters {
                group.addTask {
                    let image = try await characterToImage(character)
                    await ProgressWrapper.shared.next()
                    return (character, image)
                }
            }
            
            for try await entry in group { images.append(entry) }
            
            return images
        }
    }
    
    private func averageColors() async throws -> Array<(Character, AverageColorData)> {
        let images = try await characterImages()
        return try await withThrowingTaskGroup(of: (Character, AverageColorData).self) { group in
            var data = Array<(Character, AverageColorData)>()
            data.reserveCapacity(images.count)
            
            for (character, image) in images {
                group.addTask {
                    let avg = try averageColors(image: image)
                    await ProgressWrapper.shared.next()
                    return (character, avg)
                }
            }
            
            for try await entry in group {
                if !entry.1.isEmpty { data.append(entry) }
            }
            
            return data
        }
    }
    
    private func averageColors(image: CGImage) throws -> AverageColorData {
        var sumR = 0.0, sumG = 0.0, sumB = 0.0, sumA = 0.0
        var count = 1
        
        guard let pixels = cgImagePixels(image) else { throw Error.pixelDataError }
        for color in pixels {
            count += 1
            sumR += Double(color.red)
            sumG += Double(color.green)
            sumB += Double(color.blue)
            sumA += Double(color.alpha)
        }
        
        let meanR = sumR/sumA,
            meanG = sumG/sumA,
            meanB = sumB/sumA
        var devR = 0.0,
            devG = 0.0,
            devB = 0.0
        var nonzeroAlphas = 0
        
        for color in pixels {
            devR += pow(Double(color.red) - meanR, 2)*Double(color.alpha)
            devG += pow(Double(color.green) - meanG, 2)*Double(color.alpha)
            devB += pow(Double(color.blue) - meanB, 2)*Double(color.alpha)
            if !color.alpha.isZero { nonzeroAlphas += 1 }
        }
        
        let bessel = Double(nonzeroAlphas - 1)/Double(nonzeroAlphas)
        
        let stdDevR = sqrt(devR/(bessel * sumA)),
            stdDevG = sqrt(devG/(bessel * sumA)),
            stdDevB = sqrt(devB/(bessel * sumA))
        
        return .init(mean: try .init(red: Float(meanR),
                                     green: Float(meanG),
                                     blue: Float(meanB)),
                     standardDeviation: try .init(red: Float(stdDevR),
                                                  green: Float(stdDevG),
                                                  blue: Float(stdDevB)))
    }
}

struct AverageColorData {
    var mean: Color
    var standardDeviation: Color
    
    var isEmpty: Bool {
        mean.red == 0 && mean.green == 0 && mean.blue == 0 &&
            standardDeviation.red == 0 && standardDeviation.green == 0 && standardDeviation.blue == 0
    }
}

enum Error: Swift.Error {
    case drawingError
    case pixelDataError
}

actor ProgressWrapper {
    private var progress: ProgressBar!
    private static let operations = 2
    
    private init() {
        
    }
    
    static let shared = ProgressWrapper()
    
    func setTotal(_ count: Int) {
        progress = ProgressBar(count: count * Self.operations)
    }
    
    func next() {
        progress.next()
    }
}
