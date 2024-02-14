//
//  RecordPlayerView.swift
//  RecordMachine
//
//  Created by Asher Pope on 1/18/24.
//

import SwiftUI
import AVFoundation


struct RecordPlayerView: View {
    @Bindable var album: Album
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var fileLength: Double = 0
    @State private var currentTrackUrl: URL? = nil
    @State private var fileName: String = ""
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var formattedTime: String {
        let hours = Int(fileLength) / 3600
        let minutes = (Int(fileLength) % 3600) / 60
        let seconds = Int(fileLength) % 60
        
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    var playlist: [URL] {
        var list = [URL]()
        for track in album.trackListing {
            if let url = track.audioUrl {
                list.append(url)
            }
        }
        return list
    }
    
    var body: some View {
        NavigationStack {
            // MARK: Status Window
            VStack {
                Text("\(formattedTime)")
                    .font(.title3)
                    .onReceive(timer) { _ in
                        if isPlaying {
                            if fileLength > 0 {
                                fileLength -= 1
                            }
                        }
                    }
                
                Text(fileName)
                    .font(.caption)
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
            .background(.black)
            .cornerRadius(6)
            .onChange(of: audioPlayer?.currentTime) {
                guard let audioPlayer = audioPlayer else {
                    return
                }
                if audioPlayer.currentTime == audioPlayer.duration {
                    loadNextTrack()
                }
            }
            
            // MARK: Transport Controls
            HStack(alignment: .center) {
                
                Spacer()
                
                Button(action: playPause) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.title2)
                        .frame(width: 24, height: 6)
                        .padding()
                        .background(.gray.opacity(0.25))
                        .cornerRadius(4)
                        .tint(.green)
                }
                .onAppear {
                    loadNextTrack()
                }
                
                Button(action: restartAudioPlayer) {
                    Image(systemName: "backward.fill")
                        .font(.title2)
                        .frame(width: 24, height: 6)
                        .padding()
                        .background(.gray.opacity(0.25))
                        .cornerRadius(4)
                        .tint(.white)
                }
                
                Spacer()
                
                
            }
        }
    }
    
    func prepareAudioPlayer() {
        guard let url = currentTrackUrl else {
            print("\(currentTrackUrl!) is nil.")
            return
        }
        
        print("\nAudio file url: \(url)\n")
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            fileLength = audioPlayer?.duration ?? 0
            fileName = url.lastPathComponent
        } catch {
            print("Error creating audio player: \(error.localizedDescription)")
            currentTrackUrl = nil
        }
    }
    
    func playPause() {
        guard let audioPlayer = audioPlayer else {
            print("Audio player is nil.")
            return
        }
        
        if audioPlayer.isPlaying {
            audioPlayer.pause()
            isPlaying = false
        } else {
            audioPlayer.play()
            isPlaying = true
        }
    }
    
    func restartAudioPlayer() {
        guard let audioPlayer = audioPlayer else {
            print("Audio player is nil.")
            return
        }
        audioPlayer.currentTime = 0
        fileLength = audioPlayer.duration
    }
    
    func stopAudioPlayer() {
        guard let audioPlayer = audioPlayer else {
            print("Audio player is nil.")
            return
        }
        audioPlayer.stop()
        isPlaying = false
    }
    
    func loadNextTrack() {
        if isPlaying {
            stopAudioPlayer()
        }
        if (currentTrackUrl == nil) && (!playlist.isEmpty) {
            currentTrackUrl = playlist.first
            prepareAudioPlayer()
            return
            
        } else if playlist.first(where: {$0 == currentTrackUrl}) != playlist.last {
            let index: Int = playlist.firstIndex(of: (currentTrackUrl)!)!
            currentTrackUrl = playlist[index]
            prepareAudioPlayer()
            return
            
        } else {
            print("\nError: please check url (\(currentTrackUrl!)) and playlist (\(playlist))\n")
            return
        }
    }
}
