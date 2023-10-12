import Foundation
import CoreGraphics
import CoreImage

package func cgImage(from ciImage: CIImage) -> CGImage? {
    let context = CIContext()
    return context.createCGImage(ciImage, from: ciImage.extent)
}

package func cgImagePixels(_ image: CGImage) -> PixelSequence? {
    let bitmapInfo = CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
    guard let context = CGContext(data: nil,
                                  width: image.width,
                                  height: image.height,
                                  bitsPerComponent: 8,
                                  bytesPerRow: image.width*4,
                                  space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: bitmapInfo) else {
      return nil
    }
    context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
    guard let data = context.data else { return nil }
    
    return .init(Data(bytes: data, count: image.width * image.height * 4))
}

package struct PixelSequence: Sequence {
    private let data: Data
    
    init(_ data: Data) {
        self.data = data
    }
    
    package func makeIterator() -> Iterator {
        .init(data: data)
    }
    
    package typealias Element = ColorAlpha
    
    package struct Iterator: IteratorProtocol {
        private let data: Data
        private var counter = 0
        
        init(data: Data) {
            self.data = data
        }
        
        package mutating func next() -> ColorAlpha? {
            if counter*4 + 3 >= data.count { return nil }
            defer { counter += 1 }
            
            let r = data[counter*4],
                g = data[counter*4 + 1],
                b = data[counter*4 + 2],
                a = data[counter*4 + 3]
            
            let rf = Float(r)/256,
                gf = Float(g)/256,
                bf = Float(b)/256,
                af = Float(a)/256
            
            return .init(red: rf,
                         green: gf,
                         blue: bf,
                         alpha: af)
        }
        
        package typealias Element = ColorAlpha
    }
}

package struct ColorAlpha {
    package let red: Float
    package let green: Float
    package let blue: Float
    package let alpha: Float
    
    internal init(red: Float, green: Float, blue: Float, alpha: Float) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
    
    package func premultiply(background: Color) throws -> Color {
        return try .init(red: red*alpha + background.red*(1-alpha),
                     green: green*alpha + background.green*(1-alpha),
                     blue: blue*alpha + background.blue*(1-alpha))
    }
}

public struct Color: Codable {
    public let red: Float
    public let green: Float
    public let blue: Float
    
    package static let black = try! Color(red: 0, green: 0, blue: 0)
    
    package init(red: Float, green: Float, blue: Float) throws {
        guard Self.validColorComponent(red) &&
                Self.validColorComponent(green) &&
                Self.validColorComponent(blue) else { throw Error.invalidColor }
        
        self.red = red
        self.green = green
        self.blue = blue
    }
    
    package init(_ values: Array<Float>) throws {
        guard values.count == 3 else { throw Error.invalidColor }
        try self.init(red: values[0], green: values[1], blue: values[2])
    }
    
    private static func validColorComponent(_ component: Float) -> Bool {
        return (0.0...1.0).contains(component)
    }
}
