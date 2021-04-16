import Cocoa
import AVFoundation

/*
    Concrete implementation of RecorderProtocol
 */
class Recorder: RecorderProtocol {
    
    // The audio engine that is to be tapped for recording data
    private var graph: RecorderGraphProtocol
    
    private let dispatchQueue: DispatchQueue = DispatchQueue.global(qos: DispatchQoS.QoSClass.userInteractive)
    
    init(_ graph: RecorderGraphProtocol) {
        self.graph = graph
        FileSystemUtils.createDirectory(AppConstants.FilesAndPaths.recordingDir)
    }
    
    // TODO: What if creating the audio file fails ? Return a Bool to indicate success ?
    func startRecording(_ format: RecordingFormat) {
        
        let session = RecordingSession.start(format)
        let url = URL(fileURLWithPath: session.tempFilePath)
        
        if let recordingFile = AudioIO.createAudioFileForWriting(url, format.settings) {
        
            // Install a tap on the audio engine to start receiving audio data
            graph.nodeForRecorderTap.installTap(onBus: 0, bufferSize: 1024, format: nil, block: { buffer, when in
                AudioIO.writeAudio(buffer, recordingFile)
            })
            
            // Mark the start time of the session
            session.startTime = Date()
            
        } else {
            NSLog("Unable to create recording audio file with specified format '%@'", format.fileExtension)
        }
    }
    
    func stopRecording() {
        
        // This half-second sleep is to make up for the lag in the tap. In other words, continue to collect tapped data for half a second after the stop is requested.
        dispatchQueue.asyncAfter(deadline: DispatchTime.now() + 0.5) {
            
            self.graph.nodeForRecorderTap.removeTap(onBus: 0)
            RecordingSession.endCurrentSession()
        }
    }
    
    func saveRecording(_ url: URL) {
        
        // Rename the file from the temp URL -> user-defined URL
        let tempRecordingFilePath = RecordingSession.currentSession!.tempFilePath
        let srcURL = URL(fileURLWithPath: tempRecordingFilePath)
        FileSystemUtils.renameFile(srcURL, url)
        
        RecordingSession.invalidateCurrentSession()
    }
    
    var isRecording: Bool {
        return RecordingSession.currentSession?.active ?? false
    }
    
    var recordingInfo: RecordingInfo? {
        return !isRecording ? nil : RecordingSession.currentSession?.recordingInfo
    }
    
    // Deletes the temporary recording file if the user discards the recording when prompted to save it
    func deleteRecording() {
        
        FileSystemUtils.deleteFile(RecordingSession.currentSession!.tempFilePath)
        RecordingSession.invalidateCurrentSession()
    }
}
