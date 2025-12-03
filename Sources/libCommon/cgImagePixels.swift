import CoreGraphics
import CoreImage
import Foundation

/// Converts a CIImage to a CGImage using a Core Image context.
///
/// - Parameter ciImage: The CIImage to convert.
/// - Returns: A CGImage representation, or `nil` if conversion fails.
package func cgImage(from ciImage: CIImage) -> CGImage? {
  let context = CIContext()
  return context.createCGImage(ciImage, from: ciImage.extent)
}

/// Extracts pixel data from a CGImage as a sequence of colors.
///
/// The image is drawn into an RGBA bitmap context, and the pixel data is
/// returned as an iterable sequence.
///
/// - Parameter image: The CGImage to extract pixels from.
/// - Returns: A sequence of pixel colors with alpha, or `nil` if extraction fails.
package func cgImagePixels(_ image: CGImage) -> PixelSequence? {
  let bitmapInfo =
    CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
  guard
    let context = CGContext(
      data: nil,
      width: image.width,
      height: image.height,
      bitsPerComponent: 8,
      bytesPerRow: image.width * 4,
      space: CGColorSpaceCreateDeviceRGB(),
      bitmapInfo: bitmapInfo
    )
  else {
    return nil
  }
  context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
  guard let data = context.data else { return nil }

  return .init(Data(bytes: data, count: image.width * image.height * 4))
}

/// A sequence that iterates over pixels in an image.
///
/// Each element is a `ColorAlpha` representing the RGBA values of a single pixel.
/// Pixels are returned in row-major order (left to right, top to bottom).
package struct PixelSequence: Sequence {
  package typealias Element = ColorAlpha

  private let data: Data

  init(_ data: Data) {
    self.data = data
  }

  package func makeIterator() -> Iterator {
    .init(data: data)
  }

  /// Iterator for `PixelSequence` that yields one pixel at a time.
  package struct Iterator: IteratorProtocol {
    package typealias Element = ColorAlpha

    private let data: Data
    private var counter = 0

    init(data: Data) {
      self.data = data
    }

    package mutating func next() -> ColorAlpha? {
      if counter * 4 + 3 >= data.count { return nil }
      defer { counter += 1 }

      let r = data[counter * 4]
      let g = data[counter * 4 + 1]
      let b = data[counter * 4 + 2]
      let a = data[counter * 4 + 3]

      let rf = Float(r) / 256
      let gf = Float(g) / 256
      let bf = Float(b) / 256
      let af = Float(a) / 256

      return .init(
        red: rf,
        green: gf,
        blue: bf,
        alpha: af
      )
    }
  }
}

/// An RGBA color with alpha channel.
///
/// All components are in the range 0.0 to 1.0.
package struct ColorAlpha {
  /// The red component (0.0 to 1.0).
  package let red: Float

  /// The green component (0.0 to 1.0).
  package let green: Float

  /// The blue component (0.0 to 1.0).
  package let blue: Float

  /// The alpha (transparency) component (0.0 = transparent, 1.0 = opaque).
  package let alpha: Float

  /// Blends this color with a background color based on the alpha value.
  ///
  /// Uses standard alpha compositing to produce an opaque color by blending
  /// this color's RGB values with the background color proportionally to the
  /// alpha value.
  ///
  /// - Parameter background: The background color to blend with.
  /// - Returns: An opaque `Color` representing the blended result.
  /// - Throws: `Error.invalidColor` if the resulting color components are invalid.
  package func premultiply(background: Color) throws -> Color {
    return try .init(
      red: red * alpha + background.red * (1 - alpha),
      green: green * alpha + background.green * (1 - alpha),
      blue: blue * alpha + background.blue * (1 - alpha)
    )
  }
}

/// An RGB color with components in the range 0.0 to 1.0.
///
/// `Color` represents an opaque RGB color used for color matching in the
/// emoji-art generation process. All components must be within the valid
/// range of 0.0 to 1.0.
public struct Color: Codable, Sendable {
  /// A constant representing black (0, 0, 0).
  package static let black = try! Self(red: 0, green: 0, blue: 0)  // swiftlint:disable:this force_try

  /// The red component (0.0 to 1.0).
  public let red: Float

  /// The green component (0.0 to 1.0).
  public let green: Float

  /// The blue component (0.0 to 1.0).
  public let blue: Float

  /// Creates a color with the specified RGB components.
  ///
  /// - Parameters:
  ///   - red: The red component (0.0 to 1.0).
  ///   - green: The green component (0.0 to 1.0).
  ///   - blue: The blue component (0.0 to 1.0).
  /// - Throws: `Error.invalidColor` if any component is outside the valid range.
  package init(red: Float, green: Float, blue: Float) throws {
    guard
      Self.validColorComponent(red) && Self.validColorComponent(green)
        && Self.validColorComponent(blue)
    else { throw Error.invalidColor }

    self.red = red
    self.green = green
    self.blue = blue
  }

  /// Creates a color from an array of RGB values.
  ///
  /// - Parameter values: An array of exactly 3 floats representing [red, green, blue].
  /// - Throws: `Error.invalidColor` if the array doesn't have exactly 3 elements
  ///   or if any component is outside the valid range.
  package init(_ values: [Float]) throws {
    guard values.count == 3 else { throw Error.invalidColor }
    try self.init(red: values[0], green: values[1], blue: values[2])
  }

  private static func validColorComponent(_ component: Float) -> Bool {
    return (0.0...1.0).contains(component)
  }
}
