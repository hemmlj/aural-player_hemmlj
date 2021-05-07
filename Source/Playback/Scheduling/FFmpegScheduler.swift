import AVFoundation

///
/// Takes care of scheduling audio samples for playback of non-native tracks using FFmpeg to perform decoding.
///
class FFmpegScheduler: PlaybackSchedulerProtocol {
    
    ///
    /// The number of audio buffers currently scheduled for playback by the player, for a given session.
    ///
    /// Used to determine:
    /// 1. when playback has completed.
    /// 2. whether or not a scheduling task was successful and whether or not playback should begin.
    ///
    var scheduledBufferCounts: [PlaybackSession: AtomicCounter<Int>] = [:]
    
    // Player node used for actual playback
    let playerNode: AuralPlayerNode
    
    // Indicates whether or not a track completed while the player was paused.
    // This is required because, in rare cases, some file segments may complete when they've reached close to the end, even if the last frame has not played yet.
    var trackCompletedWhilePaused: Bool = false
    
    let sampleConverter: SampleConverterProtocol
    
    ///
    /// A **serial** operation queue on which all *deferred* scheduling tasks are enqueued, i.e. tasks scheduling buffers that will be played back at a later time.
    ///
    /// ```
    /// The use of this queue allows monitoring and cancellation of scheduling tasks
    /// (e.g. when seeking invalidates previous scheduling tasks).
    /// ```
    /// # Notes #
    ///
    /// 1. Uses the global dispatch queue.
    ///
    /// 2. This is a *serial* queue, meaning that only one operation can execute at any given time. This is very important, because we don't want a race condition when scheduling buffers.
    ///
    /// 3. Scheduling tasks for *immediate* playback will **not** be enqueued on this queue. They will be run immediately on the main thread.
    ///
    lazy var schedulingOpQueue: OperationQueue = {
        
        let queue = OperationQueue()
        queue.underlyingQueue = DispatchQueue.global(qos: .userInitiated)
        queue.qualityOfService = .userInitiated
        queue.maxConcurrentOperationCount = 1
        
        return queue
    }()
    
    init(playerNode: AuralPlayerNode, sampleConverter: SampleConverterProtocol) {
        
        self.playerNode = playerNode
        self.sampleConverter = sampleConverter
    }
    
    func playTrack(_ session: PlaybackSession, _ startPosition: Double) {
        
        guard let thePlaybackCtx = session.track.playbackContext as? FFmpegPlaybackContext, let decoder = thePlaybackCtx.decoder else {

            // This should NEVER happen. If it does, it indicates a bug (track was not prepared for playback).
            NSLog("Unable to play track \(session.track.displayName) because it has no playback context.")
            return
        }
        
        stop()
        scheduledBufferCounts[session] = AtomicCounter<Int>()
        decoder.framesNeedTimestamps.setValue(false)
        
        initiateDecodingAndScheduling(for: session, context: thePlaybackCtx, decoder: decoder, from: startPosition == 0 ? nil : startPosition)
        
        // Check that at least one audio buffer was successfully scheduled, before beginning playback.
        if let bufferCount = scheduledBufferCounts[session], bufferCount.isPositive {
            playerNode.play()
            
        } else {
            
            // This should NEVER happen. If it does, it indicates a bug (some kind of race condition)
            // or that something's wrong with the file.
            NSLog("WARNING: No buffers scheduled for track \(session.track.displayName) ... cannot begin playback.")
        }
    }
    
    ///
    /// Initiates decoding and scheduling for the current playback session, either from the start of the file, or from a given seek position.
    ///
    /// - Parameter seekPosition: An (optional) time value, specified in seconds, denoting a seek position within the
    ///                             currently playing file's audio stream. May be nil. A nil value indicates start decoding
    ///                             and scheduling from the beginning of the stream.
    ///
    /// ```
    /// Each scheduled buffer, when it finishes playing, will recursively decode / schedule one more
    /// buffer. So, in essence, this function initiates a recursive decoding / scheduling loop that
    /// terminates only when there is no more audio to play, i.e. EOF.
    /// ```
    ///
    /// # Notes #
    ///
    /// If the **seekPosition** parameter given is greater than the currently playing file's audio stream duration, this function
    /// will signal completion of playback for the file.
    ///
    func initiateDecodingAndScheduling(for session: PlaybackSession, context: FFmpegPlaybackContext, decoder: FFmpegDecoder, from seekPosition: Double? = nil) {
        
        do {
            
            // If a seek position was specified, ask the decoder to seek
            // within the stream.
            if let theSeekPosition = seekPosition {
                
                try decoder.seek(to: theSeekPosition)
                
                // If the seek took the decoder to EOF, signal completion of playback
                // and don't do any scheduling.
                if decoder.eof {
                    
                    if playerNode.isPlaying {
                        trackCompleted(session)
                        
                    } else {
                        
                        playerNode.seekToEndOfTrack(session)
                        trackCompletedWhilePaused = true
                    }
                    
                    return
                }
            }
            
            // Schedule one buffer for immediate playback
            decodeAndScheduleOneBuffer(for: session, context: context, decoder: decoder, from: seekPosition ?? 0, immediatePlayback: true, maxSampleCount: context.sampleCountForImmediatePlayback)
            
            // Schedule a second buffer asynchronously, for later, to avoid a gap in playback.
            decodeAndScheduleOneBufferAsync(for: session, context: context, decoder: decoder, maxSampleCount: context.sampleCountForDeferredPlayback)
            
        } catch {
            
            NSLog("Decoder threw error: \(error) while seeking to position \(seekPosition ?? 0) for track \(session.track.displayName) ... cannot initiate scheduling.")
        }
    }
    
    ///
    /// Asynchronously decodes and schedules a single audio buffer, of the given size (sample count), for playback.
    ///
    /// - Parameter maxSampleCount: The maximum number of samples to be decoded and scheduled for playback.
    ///
    /// # Notes #
    ///
    /// 1. If the decoder has already reached EOF prior to this function being called, nothing will be done. This function will
    /// simply return.
    ///
    /// 2. Since the task is enqueued on an OperationQueue (whose underlying queue is the global DispatchQueue),
    /// this function will not block the caller, i.e. the main thread, while the task executes.
    ///
    func decodeAndScheduleOneBufferAsync(for session: PlaybackSession, context: FFmpegPlaybackContext, decoder: FFmpegDecoder, maxSampleCount: Int32) {
        
        if decoder.eof {return}
        
        self.schedulingOpQueue.addOperation {
            self.decodeAndScheduleOneBuffer(for: session, context: context, decoder: decoder, immediatePlayback: false, maxSampleCount: maxSampleCount)
        }
    }

    ///
    /// Decodes and schedules a single audio buffer, of the given size (sample count), for playback.
    ///
    /// - Parameter maxSampleCount: The maximum number of samples to be decoded and scheduled for playback.
    ///
    /// ```
    /// Delegates to the decoder to decode and buffer a pre-determined (maximum) number of samples.
    ///
    /// Once the decoding is done, an AVAudioPCMBuffer is created from the decoder output, which is
    /// then actually sent to the audio engine for scheduling.
    /// ```
    /// # Notes #
    ///
    /// 1. If the decoder has already reached EOF prior to this function being called, nothing will be done. This function will
    /// simply return.
    ///
    /// 2. If the decoder reaches EOF when invoked from this function call, the number of samples decoded (and subsequently scheduled)
    /// may be less than the maximum sample count specified by the **maxSampleCount** parameter. However, in rare cases, the actual
    /// number of samples may be slightly larger than the maximum, because upon reaching EOF, the decoder will drain the codec's
    /// internal buffers which may result in a few additional samples that will be allowed as this is the terminal buffer.
    ///
    func decodeAndScheduleOneBuffer(for session: PlaybackSession, context: FFmpegPlaybackContext, decoder: FFmpegDecoder, from seekPosition: Double? = nil, immediatePlayback: Bool, maxSampleCount: Int32) {
        
        if decoder.eof {return}
        
        // Ask the decoder to decode up to the given number of samples.
        let frameBuffer: FFmpegFrameBuffer = decoder.decode(maxSampleCount: maxSampleCount)

        // Transfer the decoded samples into an audio buffer that the audio engine can schedule for playback.
        if let playbackBuffer = AVAudioPCMBuffer(pcmFormat: context.audioFormat, frameCapacity: AVAudioFrameCount(frameBuffer.sampleCount)) {
            
            if frameBuffer.needsFormatConversion {
                sampleConverter.convert(samplesIn: frameBuffer, andCopyTo: playbackBuffer)
                
            } else {
                frameBuffer.copySamples(to: playbackBuffer)
            }

            // Pass off the audio buffer to the audio engine for playback. The completion handler is executed when
            // the buffer has finished playing.
            //
            // Note that:
            //
            // 1 - the completion handler recursively triggers another decoding / scheduling task.
            // 2 - the completion handler will be invoked by a background thread.
            // 3 - the completion handler will execute even when the player is stopped, i.e. the buffer
            //      has not really completed playback but has been removed from the playback queue.

            // TODO: Fix the last 2 parameters ... seek posn not showing correctly.
            playerNode.scheduleBuffer(playbackBuffer, for: session, completionHandler: self.bufferCompletionHandler(session), seekPosition, immediatePlayback)

            // Upon scheduling the buffer, increment the counter.
            scheduledBufferCounts[session]?.increment()
        }
    }
    
    func bufferCompleted(_ session: PlaybackSession) {
        
        // If the buffer-associated session is not the same as the current session
        // (possible if stop() was called, eg. old buffers that complete when seeking), don't do anything.
        guard PlaybackSession.isCurrent(session), let playbackCtx = session.track.playbackContext as? FFmpegPlaybackContext,
              let decoder = playbackCtx.decoder else {return}
        
        // Audio buffer has completed playback, so decrement the counter.
        scheduledBufferCounts[session]?.decrement()
        
        if !decoder.eof {

            // If EOF has not been reached, continue recursively decoding / scheduling.
            self.decodeAndScheduleOneBufferAsync(for: session, context: playbackCtx, decoder: decoder, maxSampleCount: playbackCtx.sampleCountForDeferredPlayback)

        } else if let bufferCount = scheduledBufferCounts[session], bufferCount.isZero {
            
            // EOF has been reached, and all buffers have completed playback.
            // Signal playback completion (on the main thread).

            DispatchQueue.main.async {
                self.trackCompleted(session)
            }
        }
    }
    
    // Signal track playback completion
    func trackCompleted(_ session: PlaybackSession) {
        Messenger.publish(.player_trackPlaybackCompleted, payload: session)
    }
    
    func pause() {
        playerNode.pause()
    }
    
    func resume() {
        
        // Check if track completion occurred while paused.
        if trackCompletedWhilePaused, let curSession = PlaybackSession.currentSession {
            
            // Reset the flag and signal completion.
            trackCompletedWhilePaused = false
            trackCompleted(curSession)
            
        } else {
            playerNode.play()
        }
    }
    
    func stop() {
        
        stopScheduling()
        playerNode.stop()
        
        (PlaybackSession.currentSession?.track.playbackContext as? FFmpegPlaybackContext)?.decoder?.stop()
        
        scheduledBufferCounts.removeAll()
        trackCompletedWhilePaused = false
    }
    
    func seekToTime(_ session: PlaybackSession, _ seconds: Double, _ beginPlayback: Bool) {
        
        // Check if there's a complete loop defined. If so, defer to playLoop().
        if let loop = session.loop, loop.isComplete {
            
            playLoop(session, seconds, beginPlayback)
            return
        }
        
        guard let thePlaybackCtx = session.track.playbackContext as? FFmpegPlaybackContext, let decoder = thePlaybackCtx.decoder else {

            // This should NEVER happen. If it does, it indicates a bug (track was not prepared for playback).
            NSLog("Unable to seek within track \(session.track.displayName) because it has no playback context.")
            return
        }
        
        stop()
        
        scheduledBufferCounts[session] = AtomicCounter<Int>()
        decoder.framesNeedTimestamps.setValue(false)
        
        initiateDecodingAndScheduling(for: session, context: thePlaybackCtx, decoder: decoder, from: seconds)
        
        if let bufferCount = scheduledBufferCounts[session], bufferCount.isPositive, beginPlayback {
            playerNode.play()
        }
    }
    
    ///
    /// Cancels all (previously queued) decoding / scheduling operations on the OperationQueue, and blocks until they have been terminated.
    ///
    ///  ```
    ///  After calling this function, we can be assured that no unwanted scheduling will take place asynchronously.
    ///
    ///  This condition is important because ...
    ///
    ///  When seeking, for instance, we would want to first stop any previous scheduling tasks
    ///  that were already executing ... before scheduling new buffers from the new seek position. Otherwise, chunks
    ///  of audio from the previous seek position would suddenly start playing.
    ///
    ///  Similarly, when a file is playing and a new file is suddenly chosen for playback, we would want to stop all
    ///  scheduling for the old file and be sure that only audio from the new file would be scheduled.
    ///  ```
    ///
    func stopScheduling() {
        
        if schedulingOpQueue.operationCount > 0 {
            
            schedulingOpQueue.cancelAllOperations()
            schedulingOpQueue.waitUntilAllOperationsAreFinished()
        }
    }
    
    // Computes a segment completion handler closure, given a playback session.
    func bufferCompletionHandler(_ session: PlaybackSession) -> SessionCompletionHandler {
        
        return {(_ session: PlaybackSession) -> Void in
            self.bufferCompleted(session)
        }
    }
}
