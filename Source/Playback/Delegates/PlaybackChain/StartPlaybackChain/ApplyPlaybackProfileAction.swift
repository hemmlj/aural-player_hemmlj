import Foundation

/*
    Applies a playback profile for a track (i.e. any previously remembered playback settings, e.g. seek position)
    to an executing playback chain.
 */
class ApplyPlaybackProfileAction: PlaybackChainAction {
    
    private let profiles: PlaybackProfiles
    private let preferences: PlaybackPreferences
    
    init(_ profiles: PlaybackProfiles, _ preferences: PlaybackPreferences) {
        
        self.profiles = profiles
        self.preferences = preferences
    }
    
    func execute(_ context: PlaybackRequestContext, _ chain: PlaybackChain) {
        
        if let newTrack = context.requestedTrack {
            
            let params = context.requestParams
            
            // Check for an existing playback profile for the requested track, and only apply the profile
            // if no start position is defined in the request params.
            if let profile = profiles.get(newTrack), params.startPosition == nil {
                
                // Validate the playback profile before applying it
                params.startPosition = (profile.lastPosition >= newTrack.duration ? 0 : profile.lastPosition)
            }
        }
        
        chain.proceed(context)
    }
}
