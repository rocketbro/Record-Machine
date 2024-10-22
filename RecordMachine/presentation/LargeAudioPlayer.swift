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
    @Bindable var audioManager: AudioManager
    @State private var presentFileImporter = false
    @Query(sort: \Album.title) var albums: [Album]
    @State private var isEditing: Bool = false
    @State private var showingAlert: Bool = false
    
    
    private let displayTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var formattedTime: String {
        let hours = Int(audioManager.currentFileLength) / 3600
        let minutes = (Int(audioManager.currentFileLength) % 3600) / 60
        let seconds = Int(audioManager.currentFileLength) % 60
        
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    private var albumTitle: String {
        guard let title = audioManager.currentTrack?.album?.title else { return "" }
        
        if title == "" {
            return ""
        } else {
            return " - \(title)"
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
                            "\(track.title)",
                            width: .infinity,
                            height: 30
                        )
                        .font(.title2)
                        MarqueeText(
                            "\(album.artist)\(albumTitle)",
                            width: .infinity,
                            height: 20
                        )
                        .font(.headline)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                AudioSlider(
                    duration: audioManager.currentFileLength,
                    currentTime: .init(
                        get: { audioManager.audioPlayer?.currentTime ?? 0 },
                        set: { _ in }
                    ),
                    onEditingChanged: { editing in
                        isEditing = editing
                    },
                    onSeek: { time in
                        audioManager.audioPlayer?.currentTime = time
                        audioManager.updateNowPlayingData()
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
        audioManager.currentFileLength = 0
        audioManager.currentFileName = "Import an audio file below"
    }
}

