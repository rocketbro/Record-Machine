//
//  MiniPlayerView.swift
//  RecordMachine
//
//  Created by Asher Pope on 10/21/24.
//

//import SwiftUI
//
//struct MiniPlayerView: View {
//    @Bindable var audioManager: AudioManager
//    
//    var body: some View {
//        HStack(spacing: 16) {
//            // Album artwork
//            if let currentTrack = audioManager.currentTrack {
//                if let album = audioManager.currentTrack?.album {
//                    AlbumImage(album: album)
//                    
//                    
//                    // Track info
//                    VStack(alignment: .leading) {
//                        Text(currentTrack.title)
//                            .lineLimit(1)
//                        Text(album.artist)
//                            .font(.caption)
//                            .foregroundStyle(.secondary)
//                            .lineLimit(1)
//                    }
//                }
//            }
//            
//            Spacer()
//            
//            // Playback controls
//            HStack(spacing: 24) {
//                Button(action: audioManager.togglePlayPause) {
//                    Image(systemName: audioManager.isPlaying ? "pause.fill" : "play.fill")
//                        .font(.title2)
//                }
//                
//                Button(action: audioManager.skipToNext) {
//                    Image(systemName: "forward.fill")
//                        .font(.title2)
//                }
//            }
//            .padding(.horizontal)
//        }
//        .padding(.horizontal)
//        .gesture(
//            DragGesture()
//                .onEnded { value in
//                    if value.translation.height > 50 {
//                        // Dismiss player
//                        withAnimation {
//                            audioManager.isPlaying = false
//                        }
//                    } else if value.translation.height < -50 {
//                        // Expand to full player
//                        audioManager.showFullPlayer = true
//                    }
//                }
//        )
//        .sheet(isPresented: $audioManager.showFullPlayer) {
//            //FullPlayerView()
//        }
//    }
//}
