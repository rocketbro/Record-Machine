//
//  AudioEngine.swift
//  RecordMachine
//
//  Created by Asher Pope on 1/6/24.
//

import SwiftUI
import SwiftData
import AVFoundation

struct MiniAudioPlayer: View {
    @Environment(AudioManager.self) var audioManager
    @State private var presentFileImporter = false
    @Query(sort: \Album.title) var albums: [Album]
    
    var remainingDuration: Double {
        audioManager.currentFileLength - audioManager.audioPlayerCurrentTime
    }
    
    var formattedTime: String {
        let hours = Int(audioManager.audioPlayerCurrentTime) / 3600
        let minutes = (Int(audioManager.audioPlayerCurrentTime) % 3600) / 60
        let seconds = Int(audioManager.audioPlayerCurrentTime) % 60
        
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    private var artist: String {
        guard let artist = audioManager.currentTrack?.album?.artist else { return " - Unknown Artist" }
        
        if artist == "" {
            return " - Unknown Artist"
        } else {
            return " - \(artist)"
        }
    }
    
    private var trackTitle: String {
        guard let title = audioManager.currentTrack?.title else { return "Unknown Track" }
        
        if title == "" {
            return "Unknown Track"
        } else {
            return "\(title)"
        }
    }
    
    var body: some View {
        if let track = audioManager.currentTrack {
            HStack {
                    VStack(alignment: .center, spacing: 0) {
                        MarqueeText(
                            "\(trackTitle)\(artist)",
                            width: 120
                        )
                            .font(.caption)
                        
                        Text("\(formattedTime)")
                            .font(.title3)
                        
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                    .background(.black)
                    .cornerRadius(6)
                    
                    HStack(alignment: .center) {
                        
                        Spacer()
                        
                        if track.audioUrl != nil {
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
                        } else {
                            Button(action: { presentFileImporter.toggle() }) {
                                Image(systemName: "waveform.badge.plus")
                                    .font(.title2)
                                    .frame(width: 24, height: 6)
                                    .padding()
                                    .background(.gray.opacity(0.25))
                                    .cornerRadius(4)
                                    .tint(.white)
                            }.fileImporter(isPresented: $presentFileImporter, allowedContentTypes: [UTType.mp3, UTType.mpeg4Audio, UTType.aiff, UTType.wav, UTType.audio]) { result in
                                switch result {
                                case .success(let url):
                                    if url.startAccessingSecurityScopedResource() {
                                        let localUrl = DocumentsManager.copyToDocumentDirectory(sourceUrl: url)
                                        if let localUrl = localUrl {
                                            print(localUrl)
                                            track.audioUrl = localUrl
                                            if !audioManager.isPlaying || audioManager.currentTrack == track {
                                                audioManager.prepareAudioPlayer()
                                            }
                                        }
                                    }
                                    url.stopAccessingSecurityScopedResource()
                                case .failure(let error):
                                    print(error)
                                }
                            }
                        }
                        
                        Button(action: skip) {
                            Image(systemName: "forward.fill")
                                .font(.title2)
                                .frame(width: 24, height: 6)
                                .padding()
                                .background(.gray.opacity(0.25))
                                .cornerRadius(4)
                                .tint(.white)
                        }
                        
                    }
                
            }
            .padding()
            .background(.ultraThinMaterial)
            .background(primaryOrange.opacity(0.25))
            .cornerRadius(8)
            .frame(maxWidth: 500)
        } else {
            Text("To use the audio player, create an album and add a track.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .padding()
                .background(.ultraThinMaterial)
                .background(primaryOrange.opacity(0.25))
                .cornerRadius(8)
                .frame(maxWidth: 500)
        }
        
    }
    
    func rewind() {
        audioManager.rewindButton()
    }
    
    func skip() {
        audioManager.skipToNext()
    }
}
