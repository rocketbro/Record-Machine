//
//  LargeAudioPlayer.swift
//  RecordMachine
//
//  Created by Asher Pope on 10/22/24.
//

import SwiftUI
import SwiftData
import AVFoundation

struct LargeAudioPlayer: View {
    @Environment(AudioManager.self) var audioManager
    @State private var presentFileImporter = false
    @Query(sort: \Album.title) var albums: [Album]
    @State private var isEditing: Bool = false
    @State private var showingAlert: Bool = false
    
    
    private var trackTitle: String {
        guard let title = audioManager.currentTrack?.title else { return "Unknown Track" }
        
        if title == "" {
            return "Unknown Track"
        } else {
            return "\(title)"
        }
    }
    
    private var albumTitle: String {
        guard let title = audioManager.currentTrack?.album?.title else { return " - Unknown Album" }
        
        if title == "" {
            return " - Unknown Album"
        } else {
            return " - \(title)"
        }
    }
    
    private var artist: String {
        guard let artist = audioManager.currentTrack?.album?.artist else { return "Unknown Artist" }
        
        if artist == "" {
            return "Unknown Artist"
        } else {
            return "\(artist)"
        }
    }
    
    var body: some View {
        if let track = audioManager.currentTrack {
            VStack(spacing: 18) {
                
                if let album = track.album {
                    Spacer()
                    
                    AlbumImage(album: album)
                        .scaleEffect(audioManager.isPlaying ? 1.1 : 1)
                        .animation(.easeOut(duration: 0.75), value: audioManager.isPlaying)
                    
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 0) {
                        MarqueeText(
                            "\(trackTitle)",
                            width: 325,
                            height: 30
                        )
                        .font(.title2)
                        MarqueeText(
                            "\(artist)\(albumTitle)",
                            width: 325,
                            height: 20
                        )
                        .font(.headline)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                AudioSlider(
                    onEditingChanged: { editing in
                        isEditing = editing
                    },
                    onSeek: { time in
                        audioManager.seek(to: time)
                    }
                )
                .padding()
                
                HStack(alignment: .center) {
                    
                    Spacer()
                    
                    Button(action: rewind) {
                        Image(systemName: "backward.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                            .tint(.white)
                    }
                    .disabled(track == audioManager.queue.first)
                    
                    Spacer()
                    
                    Button(action: playPause) {
                        Image(systemName: audioManager.isPlaying ? "pause.fill" : "play.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                            .tint(.white)
                    }
                    .contentTransition(.symbolEffect(.replace))
                    .disabled(track.audioUrl == nil)
                    
                    Spacer()
                    
                    Button(action: skip) {
                        Image(systemName: "forward.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                            .tint(.white)
                    }
                    .disabled(track == audioManager.queue.last)
                    
                    Spacer()
                    
                }
                
                Spacer()
                Spacer()
                
                HStack {
                    Spacer()
                    
                    Button(action: {
                        showingAlert.toggle()
                    }) {
                        Image(systemName: "trash.fill")
                            .font(.title2)
                            .tint(.red)
                    }
                    .disabled(track.audioUrl == nil)
                    .alert("Remove Audio File", isPresented: $showingAlert, actions: {
                        Button("Remove", role: .destructive, action: deleteAudioUrl)
                        Button("Cancel", role: .cancel) { }
                    }, message: {
                        Text("This will remove the file \(audioManager.currentFileName). External files remain unchanged.")
                    })
                    
                    Spacer()
                    Spacer()
                    Spacer()
                    
                    Button(action: {
                        audioManager.stopAudioPlayer()
                        presentFileImporter.toggle()
                    }) {
                        Image(systemName: "waveform.badge.plus")
                            .font(.title2)
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
                    
                    Spacer()
                }
                
            }
            .padding()
        } else {
            Text("To use the audio player, create an album and add a track.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .padding()
        }
        
    }
    
    func playPause() {
        withAnimation {
            audioManager.playPause()
        }
    }
    
    func rewind() {
        audioManager.rewindButton()
    }
    
    func skip() {
        audioManager.skipToNext()
    }
    
    func deleteAudioUrl() {
        guard let track = audioManager.currentTrack else {
            return
        }
        audioManager.stopAudioPlayer()
        deleteFromDocumentDirectory(at: track.audioUrl!)
        track.audioUrl = nil
        audioManager.resetPlayer()
    }
}

