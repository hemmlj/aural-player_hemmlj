import Cocoa
import AVFoundation

/*
    Manages audio scheduling, and playback. See PlaybackSchedulerProtocol for more details on all the functions provided.
 
    NOTE - This class is only used on macOS 10.12 and older systems. It will be deprecated and/or decommissioned at some
    point in the future.
 */
class LegacyPlaybackScheduler: PlaybackScheduler {

    // A timer used to check if track playback has completed. This is required because the playerNode sends completion notifications prematurely, before track
    // playback has been completed. This problem has been fixed in PlaybackScheduler. It is the reason why this class is now deprecated, and only in use on macOS Sierra systems.
    private var completionPollTimer: RepeatingTaskExecutor?
    
    // The interval at which the completionPollTimer repeats its task.
    static let completionPollTimerIntervalMillis: Int = 125     // 1/8th of a second
    
    // Interval used for comparing two Double values (to avoid problems with Double precision resulting in equal values being considered inequal)
    // If two Double track seek times are within 0.001 seconds of each other, we'll consider them equal (used to detect the completion of playback of a loop or segment)
    static let timeComparisonTolerance: Double = 0.001

    override init(_ playerNode: AuralPlayerNode) {
        super.init(playerNode)
    }
    
    override func pause() {

        playerNode.pause()
        
        // If the completion timer is running, pause it
        completionPollTimer?.pause()
    }

    override func resume() {
        
        playerNode.play()
        
        // If the completion timer is paused, resume it
        completionPollTimer?.startOrResume()
    }

    override func stop() {
        
        playerNode.stop()
        
        // Completion timer is no longer relevant for this playback session which has ended.
        destroyCompletionTimer()
    }
    
    override func endLoop(_ session: PlaybackSession, _ loopEndTime: Double, _ beginPlayback: Bool) {
        
        destroyCompletionTimer()
        super.endLoop(session, loopEndTime, beginPlayback)
    }
    
    // MARK: Completion handler functions -------------------------------------------------------

    override func segmentCompleted(_ session: PlaybackSession) {
        
        // If the segment-associated session is not the same as the current session
        // (possible if stop() was called, eg. old segments that complete when seeking), don't do anything
        guard PlaybackSession.isCurrent(session) else {
            
            destroyCompletionTimer()
            return
        }
            
        // Start the completion poll timer
        completionPollTimer = RepeatingTaskExecutor(intervalMillis: LegacyPlaybackScheduler.completionPollTimerIntervalMillis, task: {
            
            self.pollForTrackCompletion()
            
        }, queue: completionHandlerQueue)
        
        // Don't start the timer if player is paused
        if playerNode.isPlaying {
            completionPollTimer?.startOrResume()
        }
    }
    
    private func pollForTrackCompletion() {
        
        guard let curSession = PlaybackSession.currentSession else {
            
            destroyCompletionTimer()
            return
        }
            
        let trackDuration = curSession.track.duration
        let curPos = seekPosition
        
        if curPos > (trackDuration - LegacyPlaybackScheduler.timeComparisonTolerance) && playerNode.isPlaying {
            
            // Notify observers that the track has finished playing. Don't do this if paused and seeking to the end.
            trackCompleted(curSession)
            destroyCompletionTimer()
        }
    }
    
    override func loopSegmentCompleted(_ session: PlaybackSession) {

        // Validate the session and check for a complete loop
        guard PlaybackSession.isCurrent(session) && session.hasCompleteLoop() else {
            
            destroyCompletionTimer()
            return
        }
            
        // Start the completion poll timer
        completionPollTimer = RepeatingTaskExecutor(intervalMillis: LegacyPlaybackScheduler.completionPollTimerIntervalMillis, task: {
            
            self.pollForLoopCompletion()
            
        }, queue: completionHandlerQueue)
        
        // Don't start the timer if player is paused
        if playerNode.isPlaying {
            completionPollTimer?.startOrResume()
        }
    }
    
    func pollForLoopCompletion() {
        
        guard let session = PlaybackSession.currentSession, let loop = session.loop, let loopEndTime = loop.endTime else {
            
            destroyCompletionTimer()
            return
        }
        
        if seekPosition > (loopEndTime - LegacyPlaybackScheduler.timeComparisonTolerance) && playerNode.isPlaying {
            restartLoop(session, loop.startTime, loopEndTime)
        }
    }
    
    private func destroyCompletionTimer() {
        
        completionPollTimer?.stop()
        completionPollTimer = nil
    }
}
