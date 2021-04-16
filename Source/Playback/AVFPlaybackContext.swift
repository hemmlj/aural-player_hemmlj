import AVFoundation

///
/// Provides information necessary for playback of a natively supported track using AVFoundation.
///
class AVFPlaybackContext: PlaybackContextProtocol {
    
    let file: URL
    var audioFile: AVAudioFile!

    let audioFormat: AVAudioFormat
    
    let sampleRate: Double
    let frameCount: AVAudioFramePosition
    let computedDuration: Double
    
    var duration: Double {computedDuration}
    
    init(for file: URL) throws {

        self.file = file
        self.audioFile = try AVAudioFile(forReading: file)

        self.audioFormat = audioFile.processingFormat
        self.sampleRate = audioFormat.sampleRate
        self.frameCount = audioFile.length
        self.computedDuration = Double(frameCount) / sampleRate
    }
    
    // Called when preparing for playback
    func open() throws {
        
        if audioFile == nil {
            audioFile = try AVAudioFile(forReading: file)
        }
    }
    
    // Called upon completion of playback
    func close() {
        audioFile = nil
    }
    
    deinit {
        close()
    }
}
