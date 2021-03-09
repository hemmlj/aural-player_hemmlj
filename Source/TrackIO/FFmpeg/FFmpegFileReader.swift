import Cocoa

class FFmpegFileReader: FileReaderProtocol {
    
    private let genericMetadata_ignoreKeys: [String] = ["title", "artist", "duration", "disc", "track", "album", "genre"]
    
    let commonFFmpegParser = CommonFFmpegMetadataParser()
    let id3Parser = ID3FFmpegParser()
    let wmParser = WMParser()
    let vorbisParser = VorbisCommentParser()
    let apeParser = ApeV2Parser()
    let defaultParser = DefaultFFmpegMetadataParser()

    private let allParsers: [FFmpegMetadataParser]
    private let wmFileParsers: [FFmpegMetadataParser]
    private let vorbisFileParsers: [FFmpegMetadataParser]
    private let apeFileParsers: [FFmpegMetadataParser]
    
    private var parsersByExt: [String: [FFmpegMetadataParser]] = [:]
    
    init() {
        
        allParsers = [commonFFmpegParser, id3Parser, vorbisParser, apeParser, wmParser, defaultParser]
        wmFileParsers = [commonFFmpegParser, wmParser, id3Parser, vorbisParser, apeParser, defaultParser]
        vorbisFileParsers = [commonFFmpegParser, vorbisParser, apeParser, id3Parser, wmParser, defaultParser]
        apeFileParsers = [commonFFmpegParser, apeParser, vorbisParser, id3Parser, wmParser, defaultParser]
        
        parsersByExt =
        [
            "wma": wmFileParsers,
            "flac": vorbisFileParsers,
            "dsf": vorbisFileParsers,
            "ogg": vorbisFileParsers,
            "opus": vorbisFileParsers,
            "ape": apeFileParsers,
            "mpc": apeFileParsers
        ]
    }
    
    private func cleanUp(_ string: String?) -> String? {
        
        if let theTrimmedString = string?.trim() {
            return theTrimmedString.isEmpty ? nil : theTrimmedString
        }
        
        return nil
    }
    
    func getPlaylistMetadata(for file: URL) throws -> PlaylistMetadata {
        
        let fctx = try FFmpegFileContext(for: file)
        
        guard fctx.bestAudioStream != nil else {
            throw NoAudioStreamError()
        }
        
        var metadata = PlaylistMetadata()
        
        let meta = FFmpegMappedMetadata(for: fctx)
        let allParsers = parsersByExt[meta.fileType] ?? self.allParsers
        allParsers.forEach {$0.mapTrack(meta)}
        
        let relevantParsers = allParsers.filter {$0.hasEssentialMetadataForTrack(meta)}
        
        metadata.title = cleanUp(relevantParsers.firstNonNilMappedValue {$0.getTitle(meta)})
        metadata.artist = cleanUp(relevantParsers.firstNonNilMappedValue {$0.getArtist(meta)})
        metadata.album = cleanUp(relevantParsers.firstNonNilMappedValue {$0.getAlbum(meta)})
        metadata.genre = cleanUp(relevantParsers.firstNonNilMappedValue {$0.getGenre(meta)})

        metadata.isProtected = relevantParsers.firstNonNilMappedValue {$0.isDRMProtected(meta)}
        
        var trackNumberAndTotal = relevantParsers.firstNonNilMappedValue {$0.getTrackNumber(meta)}
        if let trackNum = trackNumberAndTotal?.number, trackNumberAndTotal?.total == nil,
            let totalTracks = relevantParsers.firstNonNilMappedValue({$0.getTotalTracks(meta)}) {
            
            trackNumberAndTotal = (trackNum, totalTracks)
        }
        
        metadata.trackNumber = trackNumberAndTotal?.number
        metadata.totalTracks = trackNumberAndTotal?.total
        
        var discNumberAndTotal = relevantParsers.firstNonNilMappedValue {$0.getDiscNumber(meta)}
        if let discNum = discNumberAndTotal?.number, discNumberAndTotal?.total == nil,
            let totalDiscs = relevantParsers.firstNonNilMappedValue({$0.getTotalDiscs(meta)}) {
            
            discNumberAndTotal = (discNum, totalDiscs)
        }
        
        metadata.discNumber = discNumberAndTotal?.number
        metadata.totalDiscs = discNumberAndTotal?.total
        
        metadata.duration = meta.fileCtx.duration
        metadata.durationIsAccurate = metadata.duration > 0 && meta.fileCtx.estimatedDurationIsAccurate
        
        metadata.chapters = fctx.chapters.map {Chapter($0)}
        
        return metadata
        
        // TODO: Set some fields on track to indicate whether or not the duration provided is accurate.
        
//        if track.duration == 0 || meta.fileCtx.isRawAudioFile {
//
//            if let durationFromMetadata = relevantParsers.firstNonNilMappedValue({$0.getDuration(meta)}), durationFromMetadata > 0 {
//
//                track.duration = durationFromMetadata
//
//            } else {
//
//                // Use brute force to compute duration
//                DispatchQueue.global(qos: .userInitiated).async {
//
//                    if let duration = meta.fileCtx.bruteForceDuration {
//
//                        track.duration = duration
//
//                        var notif = Notification(name: Notification.Name("trackUpdated"))
//                        notif.userInfo = ["track": track]
//
//                        NotificationCenter.default.post(notif)
//                    }
//                }
//            }
//        }
    }
    
    func getAuxiliaryMetadata(for file: URL, loadingAudioInfoFrom playbackContext: PlaybackContextProtocol? = nil, loadArt: Bool) -> AuxiliaryMetadata {
        
        var metadata = AuxiliaryMetadata()
        
        do {
            
            let fctx = try FFmpegFileContext(for: file)
            let meta = FFmpegMappedMetadata(for: fctx)
            
            let allParsers = parsersByExt[meta.fileType] ?? self.allParsers
            allParsers.forEach {$0.mapTrack(meta)}
            
            let relevantParsers = allParsers.filter {$0.hasGenericMetadataForTrack(meta)}
            
            metadata.lyrics = cleanUp(relevantParsers.firstNonNilMappedValue {$0.getLyrics(meta)})
            
            var genericMetadata: [String: MetadataEntry] = [:]
            
            for parser in relevantParsers {
                
                let parserMetadata = parser.getGenericMetadata(meta)
                parserMetadata.forEach {(k,v) in genericMetadata[k] = v}
            }
            
            metadata.genericMetadata = genericMetadata
            
            let audioInfo = AudioInfo()
            
            audioInfo.format = fctx.formatLongName
            audioInfo.codec = (playbackContext as? FFmpegPlaybackContext)?.audioCodec.longName ?? fctx.bestAudioStream?.codecLongName ?? fctx.formatName
            audioInfo.bitRate = roundedInt(Double(fctx.bitRate) / Double(Size.KB))
            
            if let audioStream = fctx.bestAudioStream {
                
                audioInfo.sampleRate = audioStream.sampleRate
                audioInfo.frames = Int64(Double(audioStream.sampleRate) * fctx.duration)
                
                audioInfo.numChannels = Int(audioStream.channelCount)
                audioInfo.channelLayout = FFmpegChannelLayoutsMapper.readableString(for: Int64(audioStream.channelLayout), channelCount: audioStream.channelCount)
            }
            
            metadata.audioInfo = audioInfo
            
            if loadArt {
                
                if let imageStream = meta.imageStream,
                   let imageData = imageStream.attachedPic.data,
                   let image = NSImage(data: imageData) {
                    
                    let imgMetadata = ParserUtils.getImageMetadata(imageData as NSData)
                    metadata.art = CoverArt(image, imgMetadata)
                }
            }
            
        } catch {}
        
        return metadata
    }
    
    func getArt(for file: URL) -> CoverArt? {
        
        do {
            
            let fctx = try FFmpegFileContext(for: file)
            let meta = FFmpegMappedMetadata(for: fctx)
            
            if let imageStream = meta.imageStream,
               let imageData = imageStream.attachedPic.data,
               let image = NSImage(data: imageData) {
                
                let metadata = ParserUtils.getImageMetadata(imageData as NSData)
                return CoverArt(image, metadata)
            }
            
        } catch {
            return nil
        }
        
        return nil
    }
    
    func getPlaybackMetadata(for file: URL) throws -> PlaybackContextProtocol {
        
        let plbkCtx = try FFmpegPlaybackContext(for: file)
        
        if let fileCtx = plbkCtx.fileContext {
            
            let meta = FFmpegMappedMetadata(for: fileCtx)
            
            let allParsers = parsersByExt[meta.fileType] ?? self.allParsers
            allParsers.forEach {$0.mapTrack(meta)}
            
            let relevantParsers = allParsers.filter {$0.hasEssentialMetadataForTrack(meta)}
            
            if relevantParsers.firstNonNilMappedValue({$0.isDRMProtected(meta)}) ?? false {
                throw DRMProtectionError(file)
            }
        }
        
        return plbkCtx
    }
}