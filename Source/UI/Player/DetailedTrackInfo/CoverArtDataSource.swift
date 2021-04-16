import Cocoa

/*
 Data source and delegate for the Detailed Track Info popover view
 */
class CoverArtDataSource: TrackInfoDataSource {
    
    override var tableId: TrackInfoTab {return .coverArt}
    
    // Overriden to force table refresh (needed because cover art may be refreshed after table has loaded once)
    override func numberOfRows(in tableView: NSTableView) -> Int {
        
        // If no track is playing, no rows to display
        
        if let track = DetailedTrackInfoViewController.shownTrack {
            
            // A track is playing, add its info to the info array, as key-value pairs
            
            self.displayedTrack = track
            
            info.removeAll()
            info.append(contentsOf: infoForTrack(track))
            
            return info.count
        }
        
        return 0
    }
    
    override func infoForTrack(_ track: Track) -> [(key: String, value: String)] {
        
        guard let artInfo = track.art?.metadata else {return []}
        
        var trackInfo: [(key: String, value: String)] = []
        
        if let type = artInfo.type {
            trackInfo.append((key: "Type", value: type))
        }
        
        if let dimensions = artInfo.dimensions {
            
            let dimStr = String(format: "%.0f x %.0f", round(dimensions.width), round(dimensions.height))
            trackInfo.append((key: "Dimensions", value: dimStr))
        }
        
        if let resolution = artInfo.resolution {
            
            let resStr = String(format: "%.0f x %.0f DPI", round(resolution.width), round(resolution.height))
            trackInfo.append((key: "Resolution", value: resStr))
        }
        
        if let colorSpace = artInfo.colorSpace {
            trackInfo.append((key: "Color Space", value: colorSpace))
        }
        
        if let colorProfile = artInfo.colorProfile {
            trackInfo.append((key: "Color Profile", value: colorProfile))
        }
        
        if let bitDepth = artInfo.bitDepth {
            trackInfo.append((key: "Bit Depth", value: String(format: "%d-bit", bitDepth)))
        }
        
        if let hasAlpha = artInfo.hasAlpha {
            trackInfo.append((key: "Has Alpha?", value: hasAlpha ? "Yes" : "No"))
        }
        
        return trackInfo
    }
    
    private func channelLayout(_ numChannels: Int) -> String {
        
        switch numChannels {
            
        case 1: return "Mono (1 ch)"
            
        case 2: return "Stereo (2 ch)"
            
        case 6: return "5.1 (6 ch)"
            
        case 8: return "7.1 (8 ch)"
            
        case 10: return "9.1 (10 ch)"
            
        default: return String(format: "%d channels", numChannels)
            
        }
    }
}
