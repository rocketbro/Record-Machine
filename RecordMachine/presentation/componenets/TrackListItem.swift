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
    @Binding var runAnimation: Bool
    
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
            
            // Song Title
            Text("\(track.title.isEmpty ? "Unknown Track" : track.title)")
                .onTapGesture {
                    audioManager.playTrack(track, tracklist: trackList)
                    if !audioManager.showingPlayer {
                        withAnimation {
                            audioManager.showingPlayer.toggle()
                        }
                    }
                }
            
            Spacer()
            
            // Menu
            TrackMenu(track: track)
        }
    }
}
