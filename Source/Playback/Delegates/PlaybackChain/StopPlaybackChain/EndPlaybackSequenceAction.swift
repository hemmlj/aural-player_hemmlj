import Foundation

class EndPlaybackSequenceAction: PlaybackChainAction {
    
    private let sequencer: SequencerProtocol
    
    init(_ sequencer: SequencerProtocol) {
        self.sequencer = sequencer
    }
    
    func execute(_ context: PlaybackRequestContext, _ chain: PlaybackChain) {
        
        SyncMessenger.publishNotification(PreTrackChangeNotification(context.currentTrack, context.currentState, nil))
        
        sequencer.end()
        AsyncMessenger.publishMessage(TrackChangedAsyncMessage(context.currentTrack, context.currentState, nil))
        
        chain.complete(context)
    }
}
