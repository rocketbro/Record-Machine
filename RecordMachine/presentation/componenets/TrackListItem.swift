//
//  TrackListItem.swift
//  RecordMachine
//
//  Created by Asher Pope on 10/23/24.
//

import SwiftUI

struct TrackListItem: View {
    @Environment(AudioManager.self) var audioManager
    let track: Track
    let trackList: [Track]
    @State private var runAnimation: Bool = false
    
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            // Icon or index
            if audioManager.currentTrack == track {
                Image(systemName: "waveform")
                    .symbolEffect(.variableColor.iterative, isActive: runAnimation)
                    .foregroundStyle(runAnimation ? .accent : .gray)
                    .frame(width: 30)
            } else {
                Text("\((trackList.firstIndex(of: track) ?? 0) + 1)")
                    .frame(width: 30)
                    .foregroundStyle(.gray)
            }
            
            Group {
                // Song Title
                Text("\(track.title.isEmpty ? "Unknown Track" : track.title)")
                
                Spacer()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                print("TrackListItem: Selected track - \(track.title)")
                // First load the queue
                audioManager.loadQueue(for: track.album!)
                // Then find and load the specific track
                if let index = audioManager.queue.firstIndex(of: track) {
                    print("TrackListItem: Loading track at index \(index)")
                    audioManager.loadTrackAtIndex(index)
                }
                if !audioManager.showingPlayer {
                    withAnimation {
                        audioManager.showingPlayer.toggle()
                    }
                }
            }
            
            // Menu
            TrackMenu(track: track)
        }
        .onChange(of: audioManager.isPlaying) {
            withAnimation {
                if audioManager.isPlaying {
                    runAnimation = true
                } else {
                    runAnimation = false
                }
            }
        }
        .onAppear {
            if audioManager.isPlaying {
                withAnimation {
                    runAnimation = true
                }
            }
        }
    }
}
