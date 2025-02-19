//
//  AudioPlayerManager.swift
//  RecordMachine
//
//  Created by Asher Pope on 10/21/24.
//  To whoever has to go through this file one day,
//  I am so sorry. Good luck.
//

import SwiftUI
import AVFoundation
import MediaPlayer

@Observable @MainActor
final class AudioManager: NSObject {
    // UI State
    var showingPlayer: Bool = false
    var showFullPlayer: Bool = false
    @ObservationIgnored private var observationTask: Task<Void, Never>?
    @ObservationIgnored private var isObserving: Bool = false
    @ObservationIgnored private var rewindTimer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    @ObservationIgnored private var shouldSkipBackward: Bool = false
    
    // Playback State
    private(set) var currentTrack: Track?
    private(set) var currentStreamTrack: StreamTrack?
    private(set) var queue: [Track] = []
    private(set) var streamQueue: [StreamTrack] = []
    private(set) var currentTime: TimeInterval = 0
    private(set) var duration: TimeInterval = 0
    private(set) var isPlaying: Bool = false
    private var _currentFileLength: Double = 0
    
    // Services
    private nonisolated let streamingService = StreamingService()
    private let localProvider = LocalPlaybackProvider()
    private let streamingProvider = StreamingPlaybackProvider()
    private var currentProvider: PlaybackProvider?
    
    // Computed Properties
    var sheetBinding: Binding<Bool> {
        Binding(
            get: { self.showFullPlayer },
            set: { self.showFullPlayer = $0 }
        )
    }
    
    override init() {
        super.init()
        setupRemoteControls()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            print("AudioManager: Setting up audio session")
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            print("AudioManager: Audio session setup complete")
        } catch {
            print("AudioManager: Failed to set up audio session: \(error)")
        }
    }
    
    private func setupRemoteControls() {
        print("AudioManager: Setting up remote controls")
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.addTarget { [weak self] _ in
            print("AudioManager: Remote play command received")
            if !(self?.isPlaying ?? true) {
                self?.playPause()
                return .success
            }
            return .commandFailed
        }
        
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            print("AudioManager: Remote pause command received")
            if self?.isPlaying ?? false {
                self?.playPause()
                return .success
            }
            return .commandFailed
        }
        
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            print("AudioManager: Remote next track command received")
            self?.skipToNext()
            return .success
        }
        
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            print("AudioManager: Remote previous track command received")
            self?.skipToPrevious()
            return .success
        }
        
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            print("AudioManager: Remote seek command received")
            guard let event = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            self?.seek(to: event.positionTime)
            return .success
        }
        print("AudioManager: Remote controls setup complete")
    }
    
    // MARK: - Queue Management
    
    func loadQueue(for album: Album) {
        print("AudioManager: Loading queue for album - \(album.title)")
        stopPlayback()
        queue = album.trackListing.sorted(by: { $0.index < $1.index })
        streamQueue = []
    }
    
    func appendToQueue(_ track: Track) {
        print("AudioManager: Appending track to queue - \(track.title)")
        queue.append(track)
    }
    
    func updateQueueOrder(_ tracks: [Track]) {
        print("AudioManager: Updating queue order with \(tracks.count) tracks")
        queue = tracks
    }
    
    func loadStreamingQueue(_ tracks: [StreamTrack]) {
        print("AudioManager: Loading streaming queue with \(tracks.count) tracks")
        stopPlayback()
        streamQueue = tracks
        queue = []
        if let firstTrack = tracks.first {
            print("AudioManager: Loading first streaming track - \(firstTrack.title)")
            Task {
                try await loadStreamTrack(firstTrack)
            }
        }
    }
    
    // MARK: - Playback Control
    
    func loadTrackAtIndex(_ index: Int) {
        print("AudioManager: Loading track at index \(index)")
        guard index >= 0 && index < queue.count else {
            print("AudioManager: Invalid track index")
            return
        }
        loadTrack(queue[index])
    }
    
    private func loadTrack(_ track: Track) {
        print("AudioManager: Loading track - \(track.title)")
        currentTrack = track
        currentStreamTrack = nil
        stopObservation()
        
        guard let url = track.audioUrl else {
            print("AudioManager: No audio URL for track")
            return
        }
        
        print("AudioManager: Attempting to load audio file at \(url)")
        
        // Verify the file exists
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("AudioManager: Audio file does not exist at path")
            return
        }
        
        do {
            try localProvider.load(track)
            print("AudioManager: Successfully loaded track into provider")
            currentProvider = localProvider
            _currentFileLength = currentProvider?.duration ?? 0
            updateNewTrackData()
            if isPlaying {
                print("AudioManager: Auto-playing track as playback was active")
                currentProvider?.play()
                startPlaybackObservation()
            }
        } catch {
            print("AudioManager: Error loading track: \(error.localizedDescription)")
            print("AudioManager: File exists: \(FileManager.default.fileExists(atPath: url.path))")
            print("AudioManager: File path: \(url.path)")
        }
    }
    
    private func loadStreamTrack(_ track: StreamTrack) async throws {
        print("AudioManager: Loading streaming track - \(track.title)")
        print("AudioManager: Object path - \(track.objectPath)")
        currentTrack = nil
        currentStreamTrack = track
        stopObservation()
        
        do {
            let signedUrl = try await streamingService.getSignedUrl(for: track)
            print("AudioManager: Got signed URL for streaming track")
            print("AudioManager: Signed URL - \(signedUrl.absoluteString)")
            
            await MainActor.run {
                print("AudioManager: Attempting to load stream with URL")
                streamingProvider.load(url: signedUrl, track: track)
                currentProvider = streamingProvider
                updateNowPlayingData()
                if isPlaying {
                    print("AudioManager: Auto-playing streaming track as playback was active")
                    currentProvider?.play()
                    startPlaybackObservation()
                }
            }
        } catch {
            print("AudioManager: Error loading streaming track: \(error)")
            if let urlError = error as? URLError {
                print("AudioManager: URL Error - \(urlError.localizedDescription)")
                print("AudioManager: Error Code - \(urlError.code)")
            }
        }
    }
    
    func playPause() {
        if isPlaying {
            print("AudioManager: Pausing playback")
            currentProvider?.pause()
            isPlaying = false
            stopObservation()
        } else {
            print("AudioManager: Starting playback")
            if currentProvider == nil {
                print("AudioManager: No provider available")
                return
            }
            currentProvider?.play()
            isPlaying = true
            startPlaybackObservation()
            updateNowPlayingData()
        }
        updateNowPlayingData()
    }
    
    func skipToNext() {
        if let currentStreamTrack = currentStreamTrack,
           let currentIndex = streamQueue.firstIndex(where: { $0.id == currentStreamTrack.id }),
           currentIndex + 1 < streamQueue.count {
            print("AudioManager: Skipping to next streaming track")
            Task {
                try await loadStreamTrack(streamQueue[currentIndex + 1])
            }
        } else if let currentTrack = currentTrack,
                  let currentIndex = queue.firstIndex(of: currentTrack) {
            // If we're at the last track, loop back to start
            if currentTrack == queue.last {
                self.currentTrack = queue.first
                stopPlayback()
                restartTrack()
                return
            }
            
            // Move to next track
            let nextIndex = currentIndex + 1
            if nextIndex < queue.count {
                print("AudioManager: Skipping to next track")
                loadTrack(queue[nextIndex])
            }
        }
    }
    
    func skipToPrevious() {
        Task {
            if isPlaying {
                if shouldSkipBackward {
                    rewindToPrevious()
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                    shouldSkipBackward = false
                } else {
                    restartTrack()
                    shouldSkipBackward = true
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                    shouldSkipBackward = false
                }
            } else {
                if currentTime != 0 {
                    restartTrack()
                } else {
                    rewindToPrevious()
                }
            }
        }
    }
    
    private func rewindToPrevious() {
        if let currentStreamTrack = currentStreamTrack,
           let currentIndex = streamQueue.firstIndex(where: { $0.id == currentStreamTrack.id }),
           currentIndex > 0 {
            print("AudioManager: Skipping to previous streaming track")
            Task {
                try await loadStreamTrack(streamQueue[currentIndex - 1])
            }
        } else if let currentTrack = currentTrack,
                  let currentIndex = queue.firstIndex(of: currentTrack),
                  currentIndex > 0 {
            print("AudioManager: Skipping to previous track")
            loadTrack(queue[currentIndex - 1])
        }
    }
    
    private func restartTrack() {
        print("AudioManager: Restarting track")
        seek(to: 0)
    }
    
    func seek(to time: TimeInterval) {
        currentProvider?.seek(to: time)
        currentTime = time
        updateNowPlayingData()
    }
    
    func stopPlayback() {
        currentProvider?.stop()
        stopObservation()
        isPlaying = false
        currentTime = 0
    }
    
    // MARK: - File Management
    
    func loadLocalFile(url: URL, for track: Track) throws {
        print("\nAudioManager: Loading local file...")
        print("AudioManager: Original URL: \(url)")
        
        do {
            // First verify we can create an AVAudioPlayer with this file
            print("AudioManager: Verifying file can be loaded...")
            let testPlayer = try AVAudioPlayer(contentsOf: url)
            print("AudioManager: File verification successful")
            print("AudioManager: Duration: \(testPlayer.duration) seconds")
            print("AudioManager: Format: \(testPlayer.format)")
            
            // If successful, update the track and load it
            track.audioUrl = url
            print("AudioManager: Updated track URL to: \(url)")
            
            try localProvider.load(track)
            print("AudioManager: Track loaded into provider")
            
            currentProvider = localProvider
            currentTrack = track
            
            if isPlaying {
                print("AudioManager: Auto-playing new track")
                localProvider.play()
                startPlaybackObservation()
            }
        } catch {
            print("AudioManager: Error loading audio file: \(error)")
            print("AudioManager: Error description: \(error.localizedDescription)")
            if let nsError = error as NSError? {
                print("AudioManager: Error domain: \(nsError.domain)")
                print("AudioManager: Error code: \(nsError.code)")
                print("AudioManager: Error user info: \(nsError.userInfo)")
            }
            throw PlaybackError.playerError(error)
        }
    }
    
    // MARK: - Now Playing Info
    
    func updateNewTrackData() {
        guard let track = currentTrack else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }
        
        var nowPlayingInfo = [String: Any]()
        
        // Basic metadata
        nowPlayingInfo[MPMediaItemPropertyTitle] = track.title
        nowPlayingInfo[MPMediaItemPropertyArtist] = track.album?.artist ?? "Unknown Artist"
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = track.album?.title ?? "Unknown Album"
        
        // Add artwork if available
        if let artworkData = track.album?.artwork,
           let artworkImage = UIImage(data: artworkData) {
            let processedImage = processArtwork(artworkImage)
            let artwork = MPMediaItemArtwork(boundsSize: processedImage.size) { _ in
                return processedImage
            }
            nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
        }
        
        // Playback information
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = _currentFileLength
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    func updateNowPlayingData() {
        print("AudioManager: Updating Now Playing info")
        var nowPlayingInfo = [String: Any]()
        
        if let track = currentTrack {
            print("AudioManager: Updating Now Playing with local track: \(track.title)")
            nowPlayingInfo[MPMediaItemPropertyTitle] = track.title
            nowPlayingInfo[MPMediaItemPropertyArtist] = track.album?.artist ?? "Unknown Artist"
            nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = track.album?.title ?? "Unknown Album"
            
            // Add artwork if available
            if let artworkData = track.album?.artwork,
               let artworkImage = UIImage(data: artworkData) {
                print("AudioManager: Adding artwork to Now Playing")
                let processedImage = processArtwork(artworkImage)
                let artwork = MPMediaItemArtwork(boundsSize: processedImage.size) { _ in
                    return processedImage
                }
                nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
            }
            
            // Only add duration and time for local tracks
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = _currentFileLength
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
            
        } else if let streamTrack = currentStreamTrack {
            print("AudioManager: Updating Now Playing with stream track: \(streamTrack.title)")
            nowPlayingInfo[MPMediaItemPropertyTitle] = streamTrack.title
            nowPlayingInfo[MPMediaItemPropertyArtist] = streamTrack.artist
            nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = streamTrack.title
            
            // For streaming tracks, skip duration and time info
            // This will make the progress bar indeterminate in control center
        } else {
            print("AudioManager: Warning - No track available for Now Playing info")
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }
        
        // Always set playback rate
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        print("AudioManager: Now Playing info updated")
    }
    
    private func processArtwork(_ image: UIImage) -> UIImage {
        print("Original image orientation: \(image.imageOrientation.rawValue)")
        
        // First make the image square by cropping to center
        let squareImage: UIImage
        if image.size.width != image.size.height {
            let size = min(image.size.width, image.size.height)
            let x = (image.size.width - size) / 2
            let y = (image.size.height - size) / 2
            let square = CGRect(x: x, y: y, width: size, height: size)
            
            if let cgImage = image.cgImage?.cropping(to: square) {
                // If original was .down (3), convert to .up (0)
                let orientation = image.imageOrientation.rawValue == 3 ? .up : image.imageOrientation
                print("Middle image orientation: \(orientation.rawValue)")
                squareImage = UIImage(cgImage: cgImage, scale: image.scale, orientation: orientation)
            } else {
                squareImage = image
            }
        } else {
            squareImage = image
        }
        
        // Convert image to sRGB color space if needed
        var srgbImage: UIImage
        if squareImage.cgImage?.colorSpace?.name == CGColorSpace.displayP3 {
            UIGraphicsBeginImageContextWithOptions(squareImage.size, false, squareImage.scale)
            squareImage.draw(at: .zero)
            let newImage = UIGraphicsGetImageFromCurrentImageContext() ?? squareImage
            UIGraphicsEndImageContext()
            srgbImage = UIImage(cgImage: newImage.cgImage!, scale: newImage.scale, orientation: squareImage.imageOrientation)
        } else {
            srgbImage = squareImage
        }
        
        let targetSize = CGSize(width: 1024, height: 1024)
        
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 1.0)
        srgbImage.draw(in: CGRect(origin: .zero, size: targetSize))
        let processedImage = UIGraphicsGetImageFromCurrentImageContext() ?? srgbImage
        UIGraphicsEndImageContext()
        
        // Preserve original orientation unless it was .down
        if let finalCGImage = processedImage.cgImage {
            let finalOrientation = image.imageOrientation == .down ? .up : image.imageOrientation
            print("Final image orientation: \(finalOrientation.rawValue)")
            return UIImage(cgImage: finalCGImage, scale: processedImage.scale, orientation: finalOrientation)
        }
        
        return processedImage
    }
    
    private func startPlaybackObservation() {
        guard !isObserving else { return }
        print("AudioManager: Starting playback observation")
        isObserving = true
        
        observationTask = Task { @MainActor [weak self] in
            guard let self else { return }
            print("AudioManager: Observation task started")
            while !Task.isCancelled && isObserving {
                self.currentTime = currentProvider?.currentTime ?? 0
                self.duration = currentProvider?.duration ?? 0
                self.isPlaying = currentProvider?.isPlaying ?? false
                self.updateNowPlayingData()
                try? await Task.sleep(for: .milliseconds(250))
            }
            print("AudioManager: Observation task ended")
        }
    }
    
    private func stopObservation() {
        isObserving = false
        observationTask?.cancel()
        observationTask = nil
    }
    
    deinit {
        Task {
            await stopObservation()
        }
    }
}
