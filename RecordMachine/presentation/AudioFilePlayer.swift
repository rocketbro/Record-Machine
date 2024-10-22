//
//  AudioEngine.swift
//  RecordMachine
//
//  Created by Asher Pope on 1/6/24.
//

import SwiftUI
import SwiftData
import AVFoundation

struct AudioFilePlayer: View {
    @Bindable var audioManager: AudioManager
    @State private var presentFileImporter = false
    @Query(sort: \Album.title) var albums: [Album]
    @State private var trackInfoOffset: CGFloat = 0
    @State private var fileNameOffset: CGFloat = 0
    
    
    private let displayTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var formattedTime: String {
        let hours = Int(audioManager.currentFileLength) / 3600
        let minutes = (Int(audioManager.currentFileLength) % 3600) / 60
        let seconds = Int(audioManager.currentFileLength) % 60
        
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    private var artistDisplay: String {
        guard let artist = audioManager.currentTrack?.album?.artist else { return " - Unknown Artist" }
        
        if artist == "" {
            return ""
        } else {
            return " - \(artist)"
        }
    }
    
    var body: some View {
        if let track = audioManager.currentTrack {
            VStack(alignment: .center) {
                VStack(spacing: 0) {
                    MarqueeText("\(track.title)\(artistDisplay)", offset: $trackInfoOffset)
                        .font(.caption)
                    
                    Text("\(formattedTime)")
                        .font(.title3)
                        .onReceive(displayTimer) { _ in
                            if audioManager.isPlaying {
                                if audioManager.currentFileLength > 0 {
                                    audioManager.currentFileLength -= 1
                                }
                            }
                        }
                    
                    MarqueeText(audioManager.currentFileName, offset: $fileNameOffset)
                        .font(.caption)
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
                .background(.black)
                .cornerRadius(6)
                
                HStack(alignment: .center) {
                    
                    Spacer()
                    
                    Button(action: audioManager.playPause) {
                        Image(systemName: audioManager.isPlaying ? "pause.fill" : "play.fill")
                            .font(.title2)
                            .frame(width: 24, height: 6)
                            .padding()
                            .background(.gray.opacity(0.25))
                            .cornerRadius(4)
                            .tint(.green)
                    }
                    .disabled(track.audioUrl == nil)
                    
                    Button(action: rewind) {
                        Image(systemName: "backward.fill")
                            .font(.title2)
                            .frame(width: 24, height: 6)
                            .padding()
                            .background(.gray.opacity(0.25))
                            .cornerRadius(4)
                            .tint(.white)
                    }
                    .disabled(track == audioManager.queue.first)
//                    .onReceive(rewindTimer) { _ in
//                        if shouldSkipBackward {
//                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                                shouldSkipBackward = false
//                                print("Should skip backward = false")
//                            }
//                        }
//                    }
                    
                    Button(action: skip) {
                        Image(systemName: "forward.fill")
                            .font(.title2)
                            .frame(width: 24, height: 6)
                            .padding()
                            .background(.gray.opacity(0.25))
                            .cornerRadius(4)
                            .tint(.white)
                    }
                    .disabled(track == audioManager.queue.last)
                    
                    Button(action: {
                        audioManager.stopAudioPlayer()
                        presentFileImporter.toggle()
                    }) {
                        Image(systemName: "waveform.badge.plus")
                            .font(.title2)
                            .frame(width: 24, height: 6)
                            .padding()
                            .background(.gray.opacity(0.25))
                            .cornerRadius(4)
                            .tint(.white)
                    }
                    .fileImporter(isPresented: $presentFileImporter, allowedContentTypes: [UTType.mp3, UTType.mpeg4Audio, UTType.aiff, UTType.wav, UTType.audio]) { result in
                        switch result {
                        case .success(let url):
                            if url.startAccessingSecurityScopedResource() {
                                let localUrl = copyToDocumentDirectory(sourceUrl: url)
                                if let localUrl = localUrl {
                                    print(localUrl)
                                    track.audioUrl = localUrl
                                }
                                audioManager.prepareAudioPlayer()
                            }
                            url.stopAccessingSecurityScopedResource()
                        case .failure(let error):
                            print(error)
                        }
                    }
                    
                    Button(action: {
                        audioManager.stopAudioPlayer()
                        deleteFromDocumentDirectory(at: track.audioUrl!)
                        track.audioUrl = nil
                        audioManager.currentFileLength = 0
                        audioManager.currentFileName = "Import an audio file below"
                    }) {
                        Image(systemName: "trash.fill")
                            .font(.title2)
                            .frame(width: 24, height: 6)
                            .padding()
                            .background(.gray.opacity(0.25))
                            .cornerRadius(4)
                            .tint(.red)
                    }
                    .disabled(track.audioUrl == nil)
                    
                    Spacer()
                    
                    
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .background(primaryOrange.opacity(0.25))
            .cornerRadius(8)
            .frame(maxWidth: 500)
        } else {
            Text("To use the audio player, create an album and add a track.")
        }
        
    }
    
    func rewind() {
        audioManager.rewindButton()
    }
    
    func skip() {
        audioManager.skipToNext()
        trackInfoOffset = 0
        fileNameOffset = 0
    }
}
