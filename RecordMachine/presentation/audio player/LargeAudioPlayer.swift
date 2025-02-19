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
        if let streamTrack = audioManager.currentStreamTrack {
            return streamTrack.title
        }
        guard let title = audioManager.currentTrack?.title else { return "Unknown Track" }
        return title.isEmpty ? "Unknown Track" : title
    }
    
    private var albumTitle: String {
        if audioManager.currentStreamTrack != nil {
            return "" // Streaming tracks don't have albums
        }
        guard let title = audioManager.currentTrack?.album?.title else { return " - Unknown Album" }
        return title.isEmpty ? " - Unknown Album" : " - \(title)"
    }
    
    private var artist: String {
        if let streamTrack = audioManager.currentStreamTrack {
            return streamTrack.artist
        }
        guard let artist = audioManager.currentTrack?.album?.artist else { return "Unknown Artist" }
        return artist.isEmpty ? "Unknown Artist" : artist
    }
    
    private var currentFileName: String {
        if let streamTrack = audioManager.currentStreamTrack {
            return streamTrack.objectPath
        }
        return audioManager.currentTrack?.audioUrl?.lastPathComponent ?? "No file selected"
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
                }
                
                VStack(alignment: .leading, spacing: 0) {
                    MarqueeText(
                        trackTitle,
                        width: 325,
                        height: 35
                    )
                    .font(.title2)
                    MarqueeText(
                        "\(artist)\(albumTitle)",
                        width: 325,
                        height: 30
                    )
                    .font(.headline)
                }
                .padding(.horizontal)
                
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
                    
                    Button(action: skipToPrevious) {
                        Image(systemName: "backward.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                            .tint(.white)
                    }
                    
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
                    
                    Button(action: skipToNext) {
                        Image(systemName: "forward.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                            .tint(.white)
                    }
                    
                    Spacer()
                }
                
                Spacer()
                Spacer()
                
                // Only show file management buttons for local tracks
                if audioManager.currentStreamTrack == nil {
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
                            Text("This will remove the file \(currentFileName). External files remain unchanged.")
                        })
                        
                        Spacer()
                        Spacer()
                        Spacer()
                        
                        Button(action: {
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
                                    let localUrl = DocumentsManager.copyToDocumentDirectory(sourceUrl: url)
                                    if let localUrl = localUrl, let track = audioManager.currentTrack {
                                        print(localUrl)
                                        do {
                                            try audioManager.loadLocalFile(url: localUrl, for: track)
                                        } catch {
                                            print("Error loading track: \(error)")
                                        }
                                    }
                                }
                                url.stopAccessingSecurityScopedResource()
                            case .failure(let error):
                                print(error)
                            }
                        }
                        
                        Spacer()
                    }
                }
            }
            .padding()
            .onAppear {
                print("LargeAudioPlayer: Displaying local track - \(track.title)")
            }
        } else if let streamTrack = audioManager.currentStreamTrack {
            VStack(spacing: 18) {
                Spacer()
                
                Image(systemName: "waveform")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .foregroundStyle(primaryOrange)
                    .symbolEffect(.bounce.up, options: .repeating, isActive: audioManager.isPlaying)
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 0) {
                    MarqueeText(
                        trackTitle,
                        width: 325,
                        height: 35
                    )
                    .font(.title2)
                    MarqueeText(
                        artist,
                        width: 325,
                        height: 30
                    )
                    .font(.headline)
                }
                .padding(.horizontal)
                
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
                    
                    Button(action: skipToPrevious) {
                        Image(systemName: "backward.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                            .tint(.white)
                    }
                    
                    Spacer()
                    
                    Button(action: playPause) {
                        Image(systemName: audioManager.isPlaying ? "pause.fill" : "play.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                            .tint(.white)
                    }
                    .contentTransition(.symbolEffect(.replace))
                    
                    Spacer()
                    
                    Button(action: skipToNext) {
                        Image(systemName: "forward.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                            .tint(.white)
                    }
                    
                    Spacer()
                }
                
                Spacer()
                Spacer()
            }
            .padding()
            .onAppear {
                print("LargeAudioPlayer: Displaying streaming track - \(streamTrack.title)")
            }
        } else {
            Text("To use the audio player, create an album and add a track.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .padding()
                .onAppear {
                    print("LargeAudioPlayer: No track available")
                }
        }
    }
    
    func playPause() {
        withAnimation {
            audioManager.playPause()
        }
    }
    
    func skipToPrevious() {
        audioManager.skipToPrevious()
    }
    
    func skipToNext() {
        audioManager.skipToNext()
    }
    
    func deleteAudioUrl() {
        guard let track = audioManager.currentTrack,
              let url = track.audioUrl else {
            return
        }
        audioManager.stopPlayback()
        DocumentsManager.deleteFromDocumentDirectory(at: url)
        track.audioUrl = nil
    }
}

