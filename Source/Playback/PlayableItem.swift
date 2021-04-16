import AVFoundation

///
/// A contract for an object that provides information (i.e. a "context") necessary for playback of a track.
///
protocol PlaybackContextProtocol {
    
    ///
    /// The file associated with this context object. Used to obtain a file handle.
    ///
    var file: URL {get}
    
    var duration: Double {get}
    
    var audioFormat: AVAudioFormat {get}
    
    var sampleRate: Double {get}
    
    var frameCount: Int64 {get}
    
    ///
    /// Prepares the context object, and its associated resources (e.g. audio file handle) for track playback.
    /// This function must be called prior to playback.
    ///
    func open() throws

    ///
    /// Releases all resources (e.g. audio file handle) associated with this context object.
    /// This function must be called after playback.
    ///
    func close()
}
