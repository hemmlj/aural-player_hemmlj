import Cocoa
import AVFoundation

fileprivate let key_title: String = "info-title"

fileprivate let key_artist: String = "info-artist"

fileprivate let key_album: String = "info-album"

fileprivate let key_genre: String = "info-genre"

fileprivate let key_trackNumber: String = "info-track number"

fileprivate let key_year: String = "info-year"

fileprivate let key_duration: String = "info-approximate duration in seconds"

@available(OSX 10.13, *)
class AudioToolboxParser: AVFMetadataParser {
    
    let keySpace: AVMetadataKeySpace = .audioFile
    
    private let readableKeys: [String: String] = [
        "info-comments" : "Comment"
    ]
    
    private let essentialFieldKeys: Set<String> = {
        [key_title, key_artist, key_album, key_genre, key_duration, key_trackNumber, key_year]
    }()

    func getTitle(_ meta: AVFMappedMetadata) -> String? {
        meta.audioToolbox[key_title]?.stringValue
    }
    
    func getArtist(_ meta: AVFMappedMetadata) -> String? {
        meta.audioToolbox[key_artist]?.stringValue
    }
    
    func getAlbum(_ meta: AVFMappedMetadata) -> String? {
        meta.audioToolbox[key_album]?.stringValue
    }
    
    func getGenre(_ meta: AVFMappedMetadata) -> String? {
        meta.audioToolbox[key_genre]?.stringValue
    }
    
    func getTrackNumber(_ meta: AVFMappedMetadata) -> (number: Int?, total: Int?)? {
        
        if let trackNumItem = meta.audioToolbox[key_trackNumber] {
            return ParserUtils.parseDiscOrTrackNumber(trackNumItem)
        }
        
        return nil
    }
    
    func getYear(_ meta: AVFMappedMetadata) -> Int? {
        
        if let item = meta.audioToolbox[key_year] {
            return ParserUtils.parseYear(item)
        }
        
        return nil
    }
    
    func getDuration(_ meta: AVFMappedMetadata) -> Double? {
        
        if let item = meta.audioToolbox[key_duration], let durationStr = item.stringValue {
            return ParserUtils.parseDuration(durationStr)
        }
        
        return nil
    }
    
    func getChapterTitle(_ items: [AVMetadataItem]) -> String? {
        return items.first(where: {$0.keySpace == .audioFile && $0.keyAsString == key_title})?.stringValue
    }
    
    func getGenericMetadata(_ meta: AVFMappedMetadata) -> [String: MetadataEntry] {
        
        var metadata: [String: MetadataEntry] = [:]
        
        for item in meta.audioToolbox.values {
            
            if let key = item.keyAsString, let value = item.valueAsString, !essentialFieldKeys.contains(key) {
                
                let rKey = readableKeys[key] ?? key.replacingOccurrences(of: "info-", with: "").capitalizingFirstLetter()
                metadata[key] = MetadataEntry(.audioToolbox, rKey, value)
            }
        }
        
        return metadata
    }
}