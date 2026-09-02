import AVFoundation
import CoreImage
import CoreMedia
import Foundation

/// Basic facts about a video file, available before decoding starts.
public struct VideoInfo: Sendable {

  /// The file the information describes.
  public let url: URL

  /// The display size of the video in pixels, with any rotation applied.
  public let size: CGSize

  /// The transform that rotates decoded frames into their display orientation.
  let preferredTransform: CGAffineTransform

  /// The display width divided by the display height.
  public var aspectRatio: Double { size.width / size.height }

  /// Loads the display size and orientation of the first video track in the file at `url`.
  ///
  /// - Parameter url: A local video file.
  /// - Throws: ``Error/badVideo`` if the file has no video track, or the track has no size.
  public static func load(url: URL) async throws -> Self {
    let track = try await AVURLAsset(url: url).firstVideoTrack()
    let (naturalSize, transform) = try await track.load(.naturalSize, .preferredTransform)
    let size = naturalSize.applying(transform).absolute
    guard size.width > 0, size.height > 0 else { throw Error.badVideo }
    return .init(url: url, size: size, preferredTransform: transform)
  }

  /// The size, in pixels, of a frame `width` pixels wide at this video's aspect ratio.
  ///
  /// - Parameter width: The frame width in pixels.
  /// - Returns: A size at least one pixel tall.
  public func frameSize(width: UInt) -> CGSize {
    .init(width: Int(width), height: max(1, Int((Double(width) / aspectRatio).rounded())))
  }

  /// The size to decode at so that, once rotated, a frame is `displaySize`.
  func decodeSize(for displaySize: CGSize) -> CGSize {
    displaySize.applying(preferredTransform.inverted()).absolute
  }
}

/// One decoded frame of video.
public struct VideoFrame: TimedFrame, Sendable {

  /// When this frame is due, measured from the start of the video.
  public let presentationTime: Duration

  /// The decoded frame, in its display orientation.
  public let image: CIImage
}

/// The decoded frames of a video file, in presentation order.
///
/// Frames are pulled from an `AVAssetReader` as they are requested, so the
/// sequence never decodes further ahead than its consumer. Pair it with
/// ``_Concurrency/AsyncSequence/pacedToRealtime(clock:)`` for playback.
///
/// ```swift
/// let video = try await VideoInfo.load(url: url)
/// for try await frame in VideoFrames(video: video, size: video.frameSize(width: 80)) {
///   print(try await emojiArt.process(image: frame.image))
/// }
/// ```
///
/// > Important: `AVAssetReader` only reads local files, so the video's URL
/// > must be a file URL.
public struct VideoFrames: AsyncSequence, Sendable {

  /// The element type of the sequence.
  public typealias Element = VideoFrame

  private let video: VideoInfo
  private let size: CGSize

  /// Creates a sequence that decodes `video`.
  ///
  /// - Parameters:
  ///   - video: The video to decode.
  ///   - size: The display size, in pixels, of each frame. The decoder scales
  ///     frames, so this should be the size you intend to render.
  public init(video: VideoInfo, size: CGSize) {
    self.video = video
    self.size = size
  }

  /// Creates an iterator that opens the file on its first call to `next()`.
  public func makeAsyncIterator() -> Iterator {
    .init(video: video, size: size)
  }

  /// The iterator for ``VideoFrames``. It owns the underlying asset reader.
  public final class Iterator: AsyncIteratorProtocol {
    private let video: VideoInfo
    private let size: CGSize
    private var reader: AVAssetReader?
    private var output: AVAssetReaderTrackOutput?

    private var outputSettings: [String: Any] {
      let decodeSize = video.decodeSize(for: size)
      return [
        kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
        kCVPixelBufferWidthKey as String: Int(decodeSize.width),
        kCVPixelBufferHeightKey as String: Int(decodeSize.height)
      ]
    }

    init(video: VideoInfo, size: CGSize) {
      self.video = video
      self.size = size
    }

    /// Decodes and returns the next frame, or `nil` once the video ends.
    ///
    /// - Throws: ``Error/badVideo`` if the file cannot be opened or decoded.
    @concurrent
    public func next() async throws -> VideoFrame? {
      let output = try await startReadingIfNeeded()
      guard let sampleBuffer = output.copyNextSampleBuffer() else {
        try verifyReaderFinished()
        return nil
      }
      return try frame(from: sampleBuffer)
    }

    private func startReadingIfNeeded() async throws -> AVAssetReaderTrackOutput {
      if let output { return output }

      let asset = AVURLAsset(url: video.url)
      let track = try await asset.firstVideoTrack()
      let reader = try AVAssetReader(asset: asset)
      let output = AVAssetReaderTrackOutput(track: track, outputSettings: outputSettings)
      guard reader.canAdd(output) else { throw Error.badVideo }
      reader.add(output)
      guard reader.startReading() else { throw Error.badVideo }

      self.reader = reader
      self.output = output
      return output
    }

    private func verifyReaderFinished() throws {
      guard reader?.status == .completed else { throw Error.badVideo }
    }

    private func frame(from sampleBuffer: CMSampleBuffer) throws -> VideoFrame {
      let time = sampleBuffer.presentationTimeStamp
      guard time.isNumeric, let pixelBuffer = sampleBuffer.imageBuffer else { throw Error.badVideo }
      return .init(
        presentationTime: .seconds(time.value) / Int(time.timescale),
        image: CIImage(cvPixelBuffer: pixelBuffer).oriented(by: video.preferredTransform)
      )
    }
  }
}

extension AVAsset {
  fileprivate func firstVideoTrack() async throws -> AVAssetTrack {
    guard let track = (try? await loadTracks(withMediaType: .video))?.first else {
      throw Error.badVideo
    }
    return track
  }
}

extension CGSize {
  fileprivate var absolute: CGSize { .init(width: abs(width), height: abs(height)) }
}

extension CIImage {
  /// Rotates the image by the linear part of a track's preferred transform.
  ///
  /// AVFoundation's transforms are expressed with the origin at the top left,
  /// while Core Image's origin is at the bottom left, so the rotation direction
  /// is mirrored. The result is moved back to the origin.
  fileprivate func oriented(by transform: CGAffineTransform) -> CIImage {
    let mirrored = CGAffineTransform(
      a: transform.a,
      b: -transform.b,
      c: -transform.c,
      d: transform.d,
      tx: 0,
      ty: 0
    )
    let rotated = transformed(by: mirrored)
    return rotated.transformed(
      by: .init(translationX: -rotated.extent.minX, y: -rotated.extent.minY)
    )
  }
}
