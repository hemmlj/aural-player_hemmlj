import Cocoa

class MusicBrainzCache: NotificationSubscriber {
    
    let preferences: MusicBrainzPreferences
    
    // For a given artist / release title combo, cache art for later use (other tracks from the same album).
    private var releasesCache: ConcurrentCompositeKeyMap<String, CachedCoverArtResult> = ConcurrentCompositeKeyMap()
    private var recordingsCache: ConcurrentCompositeKeyMap<String, CachedCoverArtResult> = ConcurrentCompositeKeyMap()
    
    var onDiskReleasesCache: ConcurrentCompositeKeyMap<String, URL> = ConcurrentCompositeKeyMap()
    var onDiskRecordingsCache: ConcurrentCompositeKeyMap<String, URL> = ConcurrentCompositeKeyMap()
    
    private let baseDir: URL = AppConstants.FilesAndPaths.baseDir.appendingPathComponent("musicBrainzCache", isDirectory: true)
    
    private let diskIOOpQueue: OperationQueue = {

        let queue = OperationQueue()
        queue.underlyingQueue = DispatchQueue.global(qos: .utility)
        queue.maxConcurrentOperationCount = SystemUtils.numberOfPhysicalCores
        
        return queue
    }()
    
    init(state: MusicBrainzCacheState, preferences: MusicBrainzPreferences) {
        
        self.preferences = preferences
        Messenger.subscribe(self, .application_exitRequest, self.onAppExit(_:))
        
        guard preferences.enableCoverArtSearch && preferences.enableOnDiskCoverArtCache else {
            
            FileSystemUtils.deleteDir(self.baseDir)
            return
        }
        
        FileSystemUtils.createDirectory(self.baseDir)
        
        // Initialize the cache with entries that were previously persisted to disk.
            
        for entry in state.releases {
            
            diskIOOpQueue.addOperation {
                
                // Ensure that the image file exists and that it contains a valid image.
                if FileSystemUtils.fileExists(entry.file), let coverArt = CoverArt(imageFile: entry.file) {
                    
                    // Entry is valid, enter it into the cache.
                    
                    self.releasesCache[entry.artist, entry.title] = CachedCoverArtResult(art: coverArt)
                    self.onDiskReleasesCache[entry.artist, entry.title] = entry.file
                }
            }
        }
            
        for entry in state.recordings {
            
            diskIOOpQueue.addOperation {
                
                // Ensure that the image file exists and that it contains a valid image.
                if FileSystemUtils.fileExists(entry.file), let coverArt = CoverArt(imageFile: entry.file) {
                    
                    // Entry is valid, enter it into the cache.
                    
                    self.recordingsCache[entry.artist, entry.title] = CachedCoverArtResult(art: coverArt)
                    self.onDiskRecordingsCache[entry.artist, entry.title] = entry.file
                }
            }
        }
        
        // Read all the cached image files concurrently and wait till all the concurrent ops are finished.
        diskIOOpQueue.waitUntilAllOperationsAreFinished()
            
        self.cleanUpUnmappedFiles()
    }
    
    func getForRelease(artist: String, title: String) -> CachedCoverArtResult? {
        releasesCache[artist, title]
    }
    
    func getForRecording(artist: String, title: String) -> CachedCoverArtResult? {
        recordingsCache[artist, title]
    }
    
    func putForRelease(artist: String, title: String, coverArt: CoverArt?) {
        
        releasesCache[artist, title] = coverArt != nil ? CachedCoverArtResult(art: coverArt) : .noArt
        
        if preferences.enableOnDiskCoverArtCache, let foundArt = coverArt {
            persistForRelease(artist: artist, title: title, coverArt: foundArt)
        }
    }
    
    func persistForRelease(artist: String, title: String, coverArt: CoverArt) {
        
        // Write the file to disk (on-disk caching)
        diskIOOpQueue.addOperation {
            
            FileSystemUtils.createDirectory(self.baseDir)
            
            let nowString = Date().serializableString_hms()
            let randomNum = Int.random(in: 0..<10000)
            
            let outputFileName = String(format: "release-%@-%@-%@-%d.jpg", artist, title, nowString, randomNum)
            let file = self.baseDir.appendingPathComponent(outputFileName)
            
            do {
                
                try coverArt.image.writeToFile(fileType: .jpeg, file: file)
                self.onDiskReleasesCache[artist, title] = file
                
            } catch {
                NSLog("Error writing image file \(file.path) to the MusicBrainz on-disk cache: \(error)")
            }
        }
    }
    
    func putForRecording(artist: String, title: String, coverArt: CoverArt?) {
        
        recordingsCache[artist, title] = coverArt != nil ? CachedCoverArtResult(art: coverArt) : .noArt
        
        if preferences.enableOnDiskCoverArtCache, let foundArt = coverArt {
            persistForRecording(artist: artist, title: title, coverArt: foundArt)
        }
    }
    
    func persistForRecording(artist: String, title: String, coverArt: CoverArt) {
        
        // Write the file to disk (on-disk caching)
        diskIOOpQueue.addOperation {
            
            FileSystemUtils.createDirectory(self.baseDir)
            
            let nowString = Date().serializableString_hms()
            let randomNum = Int.random(in: 0..<10000)
            
            let outputFileName = String(format: "recording-%@-%@-%@-%d.jpg", artist, title, nowString, randomNum)
            let file = self.baseDir.appendingPathComponent(outputFileName)
            
            do {
                
                try coverArt.image.writeToFile(fileType: .jpeg, file: file)
                self.onDiskRecordingsCache[artist, title] = file
                
            } catch {
                NSLog("Error writing image file \(file.path) to the MusicBrainz on-disk cache: \(error)")
            }
        }
    }
    
    func onDiskCachingEnabled() {
        
        // Go through the in-memory cache. For all entries that have not been persisted to disk, persist them.
        
        for (artist, releaseTitle, coverArtResult) in releasesCache.entries {
                
            if let coverArt = coverArtResult.art, onDiskReleasesCache[artist, releaseTitle] == nil {
                persistForRelease(artist: artist, title: releaseTitle, coverArt: coverArt)
            }
        }
        
        for (artist, recordingTitle, coverArtResult) in recordingsCache.entries {
            
            if let coverArt = coverArtResult.art, onDiskRecordingsCache[artist, recordingTitle] == nil {
                persistForRecording(artist: artist, title: recordingTitle, coverArt: coverArt)
            }
        }
    }
    
    func onDiskCachingDisabled() {
        
        // Caching is disabled
        
        onDiskReleasesCache.removeAll()
        onDiskRecordingsCache.removeAll()
        
        diskIOOpQueue.addOperation {
            FileSystemUtils.deleteDir(self.baseDir)
        }
    }
    
    func cleanUpUnmappedFiles() {
        
        diskIOOpQueue.addOperation {
            
            // Clean up files that are unmapped.
            
            if let allFiles = FileSystemUtils.getContentsOfDirectory(self.baseDir) {
                
                let mappedFiles: Set<URL> = Set(self.onDiskReleasesCache.entries.map {$0.2} + self.onDiskRecordingsCache.entries.map {$0.2})
                
                let unmappedFiles = allFiles.filter {!mappedFiles.contains($0)}
                
                // Delete unmapped files.
                for file in unmappedFiles {
                    FileSystemUtils.deleteFile(file.path)
                }
            }
        }
    }
    
    // This function is invoked when the user attempts to exit the app.
    func onAppExit(_ request: AppExitRequestNotification) {
        
        // Wait till all disk I/O operations have completed, before allowing
        // the app to exit.
        diskIOOpQueue.waitUntilAllOperationsAreFinished()
        
        // Proceed with exit
        request.acceptResponse(okToExit: true)
    }
}

struct CachedCoverArtResult {
    
    let art: CoverArt?
    var hasArt: Bool {art != nil}
    
    static let noArt: CachedCoverArtResult = CachedCoverArtResult(art: nil)
}
