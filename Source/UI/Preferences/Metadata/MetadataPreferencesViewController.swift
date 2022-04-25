import Cocoa

class MetadataPreferencesViewController: NSViewController, PreferencesViewProtocol {
    
    @IBOutlet weak var btnEnableMusicBrainzCoverArtSearch: NSButton!
    
    @IBOutlet weak var timeoutStepper: NSStepper!
    @IBOutlet weak var lblTimeout: NSTextField!
    
    @IBOutlet weak var btnEnableMusicBrainzOnDiskCoverArtCache: NSButton!
    @IBOutlet weak var btnDisableMusicBrainzOnDiskCoverArtCache: NSButton!
    
    private let playbackInfo: PlaybackInfoDelegateProtocol = ObjectGraph.playbackInfoDelegate
    private let trackReader: TrackReader = ObjectGraph.trackReader
    private let musicBrainzCache: MusicBrainzCache = ObjectGraph.musicBrainzCache
    
    override var nibName: String? {return "MetadataPreferences"}
    
    var preferencesView: NSView {
        return self.view
    }
    
    func resetFields(_ preferences: Preferences) {
        
        let musicBrainzPrefs = preferences.metadataPreferences.musicBrainz
        
        timeoutStepper.integerValue = musicBrainzPrefs.httpTimeout
        lblTimeout.stringValue = "\(timeoutStepper.integerValue) sec"
       
        btnEnableMusicBrainzCoverArtSearch.onIf(musicBrainzPrefs.enableCoverArtSearch)
        
        if musicBrainzPrefs.enableOnDiskCoverArtCache {
            btnEnableMusicBrainzOnDiskCoverArtCache.on()
        } else {
            btnDisableMusicBrainzOnDiskCoverArtCache.on()
        }
    }
    
    @IBAction func musicBrainzTimeoutStepperAction(_ sender: NSStepper) {
        lblTimeout.stringValue = "\(timeoutStepper.integerValue) sec"
    }
    
    // Needed for radio button group
    @IBAction func musicBrainzOnDiskCacheCoverArtAction(_ sender: NSButton) {}
    
    func save(_ preferences: Preferences) throws {
        
        let prefs: MusicBrainzPreferences = preferences.metadataPreferences.musicBrainz
        
        prefs.httpTimeout = timeoutStepper.integerValue
        
        let wasSearchDisabled: Bool = !prefs.enableCoverArtSearch
        prefs.enableCoverArtSearch = btnEnableMusicBrainzCoverArtSearch.isOn
        
        prefs.enableOnDiskCoverArtCache = btnEnableMusicBrainzOnDiskCoverArtCache.isOn
        
        // If searching was disabled before but has been switched on, let's search for art for the playing track, if required.
        if wasSearchDisabled && prefs.enableCoverArtSearch, let playingTrack = playbackInfo.playingTrack {
            trackReader.loadArtAsync(for: playingTrack, immediate: true)
        }
        
        if prefs.enableCoverArtSearch && prefs.enableOnDiskCoverArtCache {
            musicBrainzCache.onDiskCachingEnabled()
        } else {
            musicBrainzCache.onDiskCachingDisabled()
        }
    }
}
