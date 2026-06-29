import AVFoundation
import CoreGraphics
import CoreMedia
import CoreVideo
import Foundation
import ScreenCaptureKit

enum RecorderError: Error { case noDisplay }

/// Thin ScreenCaptureKit wrapper that records a display (optionally cropped to a
/// region) plus **system audio**, writing a `.mov` directly via `SCRecordingOutput`
/// — no manual AVAssetWriter. The microphone is never captured: only
/// `capturesAudio` (system audio) is enabled, and the app's own audio is excluded.
final class Recorder {
    private(set) var isRecording = false
    private var stream: SCStream?
    private var recordingOutput: SCRecordingOutput?
    private var observer: StreamObserver?
    private var currentURL: URL?

    /// Fires if the capture stops on its own (e.g. the stream errors out), so the
    /// app can reset its UI. Always delivered on the main queue.
    var onUnexpectedStop: ((Error?) -> Void)?

    /// Begin capturing `displayID`. `cropRect` (display points, top-left origin)
    /// limits capture to a region; pass nil for the whole display. `scale` is the
    /// display's backing scale (points → pixels). Throws if the display can't be
    /// resolved or ScreenCaptureKit refuses to start (e.g. permission missing).
    func start(displayID: CGDirectDisplayID, cropRect: CGRect?, scale: CGFloat, outputURL: URL) async throws {
        guard !isRecording else { return }

        let content = try await SCShareableContent.current
        guard let display = content.displays.first(where: { $0.displayID == displayID })
            ?? content.displays.first(where: { $0.displayID == CGMainDisplayID() })
            ?? content.displays.first
        else { throw RecorderError.noDisplay }

        let config = SCStreamConfiguration()
        config.capturesAudio = true               // system audio
        config.excludesCurrentProcessAudio = true // never record our own sounds
        config.showsCursor = true
        config.minimumFrameInterval = CMTime(value: 1, timescale: 60) // up to 60fps
        config.pixelFormat = kCVPixelFormatType_32BGRA

        if let cropRect {
            config.sourceRect = cropRect
            config.width = max(2, Int((cropRect.width * scale).rounded()))
            config.height = max(2, Int((cropRect.height * scale).rounded()))
        } else {
            config.width = Int(CGFloat(display.width) * scale)
            config.height = Int(CGFloat(display.height) * scale)
        }

        let filter = SCContentFilter(display: display, excludingWindows: [])

        let observer = StreamObserver()
        observer.onError = { [weak self] error in
            DispatchQueue.main.async { self?.handleUnexpectedStop(error) }
        }

        let stream = SCStream(filter: filter, configuration: config, delegate: observer)

        let recConfig = SCRecordingOutputConfiguration()
        recConfig.outputURL = outputURL
        recConfig.outputFileType = .mov
        recConfig.videoCodecType = .hevc

        let output = SCRecordingOutput(configuration: recConfig, delegate: observer)
        try stream.addRecordingOutput(output)
        try await stream.startCapture()

        self.stream = stream
        self.recordingOutput = output
        self.observer = observer
        self.currentURL = outputURL
        self.isRecording = true
    }

    /// Stop capturing and finalize the file. Returns the written URL (nil if not
    /// recording). `stopCapture` flushes and closes the recording output.
    @discardableResult
    func stop() async -> URL? {
        guard isRecording, let stream else { return nil }
        let url = currentURL
        isRecording = false
        try? await stream.stopCapture()
        cleanup()
        return url
    }

    private func handleUnexpectedStop(_ error: Error?) {
        guard isRecording else { return }
        isRecording = false
        cleanup()
        onUnexpectedStop?(error)
    }

    private func cleanup() {
        stream = nil
        recordingOutput = nil
        observer = nil
        currentURL = nil
    }
}

/// Bridges ScreenCaptureKit's stream + recording-output delegates. We drive the
/// lifecycle from start/stopCapture, so we only care about error callbacks here.
private final class StreamObserver: NSObject, SCStreamDelegate, SCRecordingOutputDelegate {
    var onError: ((Error) -> Void)?

    func stream(_ stream: SCStream, didStopWithError error: Error) { onError?(error) }
    func recordingOutput(_ recordingOutput: SCRecordingOutput, didFailWithError error: Error) { onError?(error) }
}
