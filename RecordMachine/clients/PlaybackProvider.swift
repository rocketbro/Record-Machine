import Foundation
import AVFoundation
import MediaPlayer

@MainActor
protocol PlaybackProvider {
    var isPlaying: Bool { get }
    var currentTime: TimeInterval { get }
    var duration: TimeInterval { get }
    var title: String? { get }
    var artist: String? { get }
    
    func play()
    func pause()
    func seek(to time: TimeInterval)
    func stop()
    func updateNowPlayingData()
}

@MainActor
class LocalPlaybackProvider: NSObject, PlaybackProvider, @preconcurrency AVAudioPlayerDelegate {
    private var player: AVAudioPlayer?
    private var track: Track?
    
    var isPlaying: Bool { player?.isPlaying ?? false }
    var currentTime: TimeInterval { player?.currentTime ?? 0 }
    var duration: TimeInterval { player?.duration ?? 0 }
    var title: String? { track?.title }
    var artist: String? { track?.album?.artist }
    
    func load(_ track: Track) throws {
        print("LocalPlaybackProvider: Loading track - \(track.title)")
        self.track = track
        guard let url = track.audioUrl else { 
            print("LocalPlaybackProvider: No URL provided")
            throw PlaybackError.invalidURL 
        }
        
        print("LocalPlaybackProvider: Attempting to create player with URL: \(url)")
        print("LocalPlaybackProvider: File exists: \(FileManager.default.fileExists(atPath: url.path))")
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            print("LocalPlaybackProvider: Successfully created AVAudioPlayer")
            player.delegate = self
            player.prepareToPlay()
            self.player = player
        } catch {
            print("LocalPlaybackProvider: Failed to create player: \(error.localizedDescription)")
            throw PlaybackError.playerError(error)
        }
    }
    
    func play() {
        print("LocalPlaybackProvider: Playing track")
        player?.play()
    }
    
    func pause() {
        print("LocalPlaybackProvider: Pausing track")
        player?.pause()
    }
    
    func seek(to time: TimeInterval) {
        player?.currentTime = time
        updateNowPlayingData()
    }
    
    func stop() {
        print("LocalPlaybackProvider: Stopping track")
        player?.stop()
        player?.currentTime = 0
    }
    
    func updateNowPlayingData() {
        var info = [String: Any]()
        info[MPMediaItemPropertyTitle] = title
        info[MPMediaItemPropertyArtist] = artist
        info[MPMediaItemPropertyPlaybackDuration] = duration
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        
        if let artworkData = track?.album?.artwork,
           let artworkImage = UIImage(data: artworkData) {
            let artwork = MPMediaItemArtwork(boundsSize: artworkImage.size) { _ in
                return artworkImage
            }
            info[MPMediaItemPropertyArtwork] = artwork
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        // Notify AudioManager to handle next track
    }
}

@MainActor
class StreamingPlaybackProvider: PlaybackProvider {
    // These properties are accessed from non-isolated cleanup
    private nonisolated(unsafe) var player: AVPlayer?
    private nonisolated(unsafe) var timeObserver: Any?
    private var track: StreamTrack?
    
    private(set) var isPlaying: Bool = false
    private(set) var currentTime: TimeInterval = 0
    private(set) var duration: TimeInterval = 0
    var title: String? { track?.title }
    var artist: String? { track?.artist }
    
    func load(url: URL, track: StreamTrack) {
        self.track = track
        let playerItem = AVPlayerItem(url: url)
        
        // Remove existing time observer
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
        
        // Create or update player
        if player == nil {
            player = AVPlayer(playerItem: playerItem)
        } else {
            player?.replaceCurrentItem(with: playerItem)
        }
        
        // Add time observer
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            Task { @MainActor in
                guard let self = self else { return }
                self.currentTime = time.seconds
                if let duration = self.player?.currentItem?.duration {
                    self.duration = duration.seconds
                }
                self.updateNowPlayingData()
            }
        }
    }
    
    func play() {
        player?.play()
        isPlaying = true
    }
    
    func pause() {
        player?.pause()
        isPlaying = false
    }
    
    func seek(to time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.seek(to: cmTime)
    }
    
    func stop() {
        player?.pause()
        player?.seek(to: .zero)
        isPlaying = false
    }
    
    func updateNowPlayingData() {
        var info = [String: Any]()
        info[MPMediaItemPropertyTitle] = title
        info[MPMediaItemPropertyArtist] = artist
        info[MPMediaItemPropertyPlaybackDuration] = duration
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
    
    private func cleanupTimeObserver() {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
    }
    
    deinit {
        // AVPlayer cleanup is thread-safe
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
    }
}

enum PlaybackError: Error {
    case invalidURL
    case playerError(Error)
} 
