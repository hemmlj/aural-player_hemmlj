import Foundation

///
/// Uses an ffmpeg codec to decode a non-native track. Used by the ffmpeg scheduler in regular intervals
/// to decode small chunks of audio that can be scheduled for playback.
///
class FFmpegDecoder {
    
    ///
    /// The maximum difference between a desired seek position and an actual seek
    /// position (that results from actually performing a seek) that will be tolerated,
    /// i.e. will not require a correction.
    ///
    private static let seekPositionTolerance: Double = 0.01

    ///
    /// FFmpeg context for the file that is to be decoded
    ///
    var fileCtx: FFmpegFileContext
    
    ///
    /// The first / best audio stream in this file, if one is present. May be nil.
    ///
    let stream: FFmpegAudioStream
    
    ///
    /// Audio codec chosen by ffmpeg to decode this file.
    ///
    let codec: FFmpegAudioCodec
    
    ///
    /// Duration of the track being decoded.
    ///
    var duration: Double {fileCtx.duration}
    
    ///
    /// A flag indicating whether or not the codec has reached the end of the currently playing file's audio stream, i.e. EOF..
    ///
    var eof: Bool = false

    ///
    /// Indicates whether or not we have reached the end of the loop when scheduling buffers for the current loop (analogous to EOF for file scheduling).
    ///
    var endOfLoop: AtomicBool = AtomicBool()
    
    ///
    /// Indicates whether or not the frames that are decoded need to have timestamps on them (this is true when a segment loop is active, false when not).
    ///
    var framesNeedTimestamps: AtomicBool = AtomicBool()
    
    ///
    /// A queue data structure used to temporarily hold buffered frames as they are decoded by the codec and before passing them off to a FrameBuffer.
    ///
    /// # Notes #
    ///
    /// During a decoding loop, in the event that a FrameBuffer fills up, this queue will hold the overflow (excess) frames that can be passed off to the next
    /// FrameBuffer in the next decoding loop.
    ///
    var frameQueue: Queue<FFmpegFrame> = Queue<FFmpegFrame>()
    
    ///
    /// Given ffmpeg context for a file, initializes an appropriate codec to perform decoding.
    ///
    /// - Parameter fileContext: ffmpeg context for the audio file to be decoded by this decoder.
    ///
    /// throws if:
    ///
    /// - No audio stream is found in the file.
    /// - Unable to initialize the required codec.
    ///
    init(for fileContext: FFmpegFileContext) throws {
        
        self.fileCtx = fileContext
        
        guard let theAudioStream = fileContext.bestAudioStream else {
            throw FormatContextInitializationError(description: "\nUnable to find audio stream in file: '\(fileContext.file.path)'")
        }
        
        self.stream = theAudioStream
        self.codec = try FFmpegAudioCodec(fromParameters: stream.avStream.codecpar)
        try codec.open()
    }
    
    ///
    /// Decodes the currently playing file's audio stream to produce a given (maximum) number of samples, in a loop, and returns a frame buffer
    /// containing all the samples produced during the loop.
    ///
    /// - Parameter maxSampleCount: Maximum number of samples to be decoded
    ///
    /// # Notes #
    ///
    /// 1. If the codec reaches EOF during the loop, the number of samples produced may be less than the maximum sample count specified by
    /// the **maxSampleCount** parameter. However, in rare cases, the actual number of samples may be slightly larger than the maximum,
    /// because upon reaching EOF, the decoder will drain the codec's internal buffers which may result in a few additional samples that will be
    /// allowed as this is the terminal buffer.
    ///
    func decode(maxSampleCount: Int32) -> FFmpegFrameBuffer {
        
        let audioFormat: FFmpegAudioFormat = FFmpegAudioFormat(sampleRate: codec.sampleRate, channelCount: codec.channelCount,
                                                               channelLayout: codec.channelLayout, sampleFormat: codec.sampleFormat)
        
        // Create a frame buffer with the specified maximum sample count and the codec's sample format for this file.
        let buffer: FFmpegFrameBuffer = FFmpegFrameBuffer(audioFormat: audioFormat, maxSampleCount: maxSampleCount)
        
        // Keep decoding as long as EOF is not reached.
        while !eof {
            
            do {

                // Try to obtain a single decoded frame.
                let frame = try nextFrame()
                
                // Try appending the frame to the frame buffer.
                // The frame buffer may reject the new frame if appending it would
                // cause its sample count to exceed the maximum.
                if buffer.appendFrame(frame) {
                    
                    // The buffer accepted the new frame. Remove it from the queue.
                    _ = frameQueue.dequeue()
                    
                } else {
                    
                    // The frame buffer rejected the new frame because it is full. End the loop.
                    break
                }
                
            } catch let packetReadError as PacketReadError {
                
                // If the error signals EOF, suppress it, and simply set the EOF flag.
                self.eof = packetReadError.isEOF
                
                // If the error is something other than EOF, it either indicates a real problem or simply that there was one bad packet. Log the error.
                if !eof {NSLog("Packet read error while reading track \(fileCtx.filePath) : \(packetReadError)")}
                
            } catch {
                
                // This either indicates a real problem or simply that there was one bad packet. Log the error.
                NSLog("Decoder error while reading track \(fileCtx.filePath) : \(error)")
            }
        }
        
        // If and when EOF has been reached, drain both:
        //
        // - the frame queue (which may have overflow frames left over from the previous decoding loop), AND
        // - the codec's internal frame buffer
        //
        //, and append them to our frame buffer.
        
        if eof {
            
            var terminalFrames: [FFmpegFrame] = frameQueue.dequeueAll()
            
            do {
                
                let drainFrames = try codec.drain()
                terminalFrames.append(contentsOf: drainFrames.frames)
                
            } catch {
                NSLog("Decoder drain error while reading track \(fileCtx.filePath): \(error)")
            }
            
            // Append these terminal frames to the frame buffer (the frame buffer cannot reject terminal frames).
            buffer.appendTerminalFrames(terminalFrames)
        }
        
        return buffer
    }
    
    ///
    /// Seeks to a given position within the currently playing file's audio stream.
    ///
    /// - Parameter time: A desired seek position, specified in seconds. Must be greater than 0.
    ///
    /// - throws: A **SeekError** if the seek fails *and* EOF has *not* been reached.
    ///
    /// # Notes #
    ///
    /// 1. If the seek goes past the end of the currently playing file, i.e. **time** > stream duration, the EOF flag will be set.
    ///
    /// 2. If the EOF flag had previously been set (true), but this seek took the stream to a position before EOF,
    /// the EOF flag will be reset (false) by this function call.
    ///
    func seek(to time: Double) throws {
        
        do {
            
            // Before attempting the seek, it is necessary to ask the codec
            // to flush its internal buffers. Otherwise, stale frames may
            // be produced when decoding or the seek may fail.
            codec.flushBuffers()
            
            try fileCtx.seek(within: stream, to: time)
            
            // Because ffmpeg's seeking is not always accurate, we need to check where the seek took us to, within the stream, and
            // we may need to skip some packets / samples.
            do {
                
                // Keep track of which packets we have read, and the corresponding timestamp (in seconds) for each.
                var packetsRead: [(packet: FFmpegPacket, timestampSeconds: Double)] = []
                
                // Keep track of the last read packet's timestamp.
                var lastReadPacketTimestamp: Double = -1
                
                // Keep reading packets till the packet timestamp crosses our target seek time.
                while lastReadPacketTimestamp < time {
                    
                    if let packet = try fileCtx.readPacket(from: stream) {
                        
                        lastReadPacketTimestamp = Double(packet.pts) * stream.timeBase.ratio
                        packetsRead.append((packet, lastReadPacketTimestamp))
                    }
                }
                
                if let firstIndexAfterTargetTime = packetsRead.firstIndex(where: {$0.timestampSeconds > time}) {
                    
                    // Decode and drop all but the last packet whose timestamp < seek target time.
                    if firstIndexAfterTargetTime > 1 {
                        (0..<(firstIndexAfterTargetTime - 1)).map {packetsRead[$0].packet}.forEach {codec.decodeAndDrop(packet: $0)}
                    }
                    
                    // Decode and enqueue all usable packets, starting at either:
                    // 1 - the last packet whose timestamp < seek target time, (this case is most likely) OR
                    // 2 - the first packet whose timestamp > seek target time (rare cases),
                    // depending on where the seek took us to within the stream.
                    
                    let firstUsablePacketIndex = max(firstIndexAfterTargetTime - 1, 0)
                    var framesFromUsablePackets: [FFmpegPacketFrames] = []
                    
                    for packet in (firstUsablePacketIndex..<packetsRead.count).map({packetsRead[$0].packet}) {
                        
                        let packetFrames = try codec.decode(packet: packet)
                        
                        if framesNeedTimestamps.value {
                            setTimestampsInFrames(packetFrames.frames)
                        }
                        
                        framesFromUsablePackets.append(packetFrames)
                    }
                    
                    // If the difference between the target time and the first usable packet's timestamp is greater
                    // than our tolerance threshold, truncate and/or discard the first few frames to get to our
                    // target seek time.
                    //
                    // NOTE - This may be required because some packet sizes can be quite large (eg. 1 second or more),
                    // increasing the margin of error (i.e. granularity) when seeking.
                    if framesFromUsablePackets.count > 1, time - packetsRead[firstUsablePacketIndex].timestampSeconds > Self.seekPositionTolerance {
                        
                        // The number of samples we keep will be determined by the timestamp of the first packet whose timestamp > seek target time.
                        let numSamplesToKeep = Int32((packetsRead[firstIndexAfterTargetTime].timestampSeconds - time) * Double(codec.sampleRate))
                        framesFromUsablePackets.first?.keepLastNSamples(sampleCount: numSamplesToKeep)
                    }
                    
                    // Put all our usable frames in the queue so that they may be read later from within the decoding loop.
                    framesFromUsablePackets.flatMap{$0.frames}.forEach {frameQueue.enqueue($0)}
                }
                
            } catch {
                NSLog("Error while skipping packets after seeking within track \(fileCtx.filePath) to time: \(time) seconds: \(error)")
            }
            
            // If the seek succeeds, we have not reached EOF.
            self.eof = false
            
        } catch let seekError as SeekError {
            
            // EOF is considered harmless, only throw if another type of error occurred.
            self.eof = seekError.isEOF
            
            if !eof {
                
                NSLog("Error while skipping packets after seeking within track \(fileCtx.filePath) to time: \(time) seconds: \(seekError.code.errorDescription)")
                throw DecoderError(seekError.code)
            }
        }
    }
    
    ///
    /// Given all frames decoded from a single packet, sets each of their start / end timestamps, in seconds, for
    /// later use, e.g. when scheduling segment loops.
    ///
    private func setTimestampsInFrames(_ frames: [FFmpegFrame]) {
        
        if frames.isEmpty {return}
        
        let sampleRate = codec.sampleRate
        
        // The timestamp of the first frame will serve as a base timestamp
        let frame0PTS: Double = Double(frames[0].pts) * stream.timeBase.ratio
        frames[0].startTimestampSeconds = frame0PTS
        frames[0].endTimestampSeconds = frame0PTS + (Double(frames[0].actualSampleCount) / Double(sampleRate))
        
        // More than 1 frame in packet
        if frames.count > 1 {

            // Use sample count and sample rate to calculate timestamps
            // for each of the subsequent (after the first) frames.
            
            var currentSampleCount: Int32 = frames[0].sampleCount
            
            for index in (1..<frames.count) {
                
                let frame = frames[index]
                
                frame.startTimestampSeconds = frames[index - 1].endTimestampSeconds
                frame.endTimestampSeconds = frame.startTimestampSeconds + (Double(frame.actualSampleCount) / Double(sampleRate))
                
                currentSampleCount += frame.actualSampleCount
            }
        }
    }
    
    ///
    /// Decodes the next available packet in the stream, if required, to produce a single frame.
    ///
    /// - returns:  A single frame containing PCM samples.
    ///
    /// - throws:   A **PacketReadError** if the next packet in the stream cannot be read, OR
    ///             A **DecoderError** if a packet was read but unable to be decoded by the codec.
    ///
    /// # Notes #
    ///
    /// 1. If there are already frames in the frame queue, that were produced by a previous call to this function, no
    /// packets will be read / decoded. The first frame from the queue will simply be returned.
    ///
    /// 2. If more than one frame is produced by the decoding of a packet, the first such frame will be returned, and any
    /// excess frames will remain in the frame queue to be consumed by the next call to this function.
    ///
    /// 3. The returned frame will not be dequeued (removed from the queue) by this function. It is the responsibility of the caller
    /// to do so, upon consuming the frame.
    ///
    func nextFrame() throws -> FFmpegFrame {
        
        while frameQueue.isEmpty {
        
            if let packet = try fileCtx.readPacket(from: stream) {
                
                let frames = try codec.decode(packet: packet).frames
                
                if framesNeedTimestamps.value {
                    setTimestampsInFrames(frames)
                }
                
                frames.forEach {frameQueue.enqueue($0)}
            }
        }
        
        return frameQueue.peek()!
    }
    
    ///
    /// Responds to playback for a file being stopped, by performing any necessary cleanup.
    ///
    func stop() {
        frameQueue.clear()
    }
    
    /// Indicates whether or not this object has already been destroyed.
    private var destroyed: Bool = false
    
    ///
    /// Performs cleanup (deallocation of allocated memory space) when
    /// this object is about to be deinitialized or is no longer needed.
    ///
    func destroy() {

        // This check ensures that the deallocation happens
        // only once. Otherwise, a fatal error will be
        // thrown.
        if destroyed {return}

        codec.destroy()
        fileCtx.destroy()
        
        destroyed = true
    }

    /// When this object is deinitialized, make sure that its allocated memory space is deallocated.
    deinit {
        destroy()
    }
}
