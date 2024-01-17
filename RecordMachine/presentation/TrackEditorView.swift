//
//  TrackEditorView.swift
//  RecordMachine
//
//  Created by Asher Pope on 1/3/24.
//

import SwiftUI
import SwiftData

struct TrackEditorView: View {
    @Environment(\.modelContext) var modelContext
    @Bindable var track: Track
    @Binding var path: NavigationPath
    @Query var albums: [Album]
    @State private var fileName: String = "Import an audio file below"
    @State private var showingAudioPlayer = false
        
    var body: some View {
        ZStack {
            Form {
                Section {
                    HStack {
                        Text("Title:")
                        Spacer()
                        TextField("Title", text: $track.title, axis: .vertical)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(primaryOrange)
                    }
                    HStack {
                        Text("Writers:")
                        Spacer()
                        TextField("Writers", text: $track.writers, axis: .vertical)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(primaryOrange)
                    }
                    
                    HStack {
                        Text("BPM:")
                        Spacer()
                        TextField("BPM", value: $track.bpm, format: .number)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(primaryOrange)
                    }
                    
                    Picker("Key", selection: $track.key) {
                        ForEach(MusicKey.allCases, id: \.self) {
                            Text($0.rawValue)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    
                    Picker("Genre", selection: $track.genre) {
                        ForEach(MusicGenre.allCases, id: \.self) {
                            Text($0.rawValue)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    
                    Picker("Album", selection: $track.album) {
                        ForEach(albums) { album in
                            Text(album.title).tag(album as Album?)
                        }
                        Text("None").tag(nil as Album?)
                    }
                    .pickerStyle(.navigationLink)
                    
                    TextField("Track notes", text: $track.notes, axis: .vertical)
                } header: {
                    Text("Track Info")
                }
                
                Section {
                    TextEditor(text: $track.lyrics)
                        .frame(minHeight: 500)
                } header: {
                    Text("Lyrics")
                }
            }
            .navigationTitle("Edit Track")
            .navigationBarTitleDisplayMode(.inline)
            .zIndex(1)
            .toolbar {
                ToolbarItem {
                    Button(action: {
                        withAnimation {
                            showingAudioPlayer.toggle()
                        }
                    }) {
                        Image(systemName: showingAudioPlayer ? "hifispeaker.2.fill" : "hifispeaker.2")
                    }
                }
            }
            .onAppear {
                if track.audioUrl != nil {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation { showingAudioPlayer.toggle() }
                    }
                }
            }
            
            if showingAudioPlayer {
                withAnimation {
                    VStack {
                        Spacer()
                        AudioFilePlayer(track: track, fileName: $fileName)
                            .padding(.horizontal)
                            .shadow(color: .black.opacity(0.35), radius: 20)
                            .transition(.move(edge: .bottom))
                    }
                    .zIndex(2)
                }
            }
            
        }
    }
    
}
