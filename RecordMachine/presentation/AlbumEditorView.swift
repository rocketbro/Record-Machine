//
//  AlbumEditorView.swift
//  RecordMachine
//
//  Created by Asher Pope on 1/3/24.
//

import SwiftUI
import SwiftData
import PhotosUI

struct AlbumEditorView: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    @Environment(\.modelContext) var modelContext
    @Environment(AudioManager.self) var audioManager
    @Bindable var album: Album
    @Binding var navPath: NavigationPath
    @State private var artworkSelection: PhotosPickerItem?
    
    enum KeyboardFocus {
        case title, artist, linerNotes
    }
    @FocusState private var keyboardFocus: KeyboardFocus?
    
    private var orderedTracks: [Track] {
        return album.trackListing.sorted(by: { $0.index < $1.index })
    }
    
    private var hasArtwork: Bool {
        album.artwork != nil
    }
    
    var body: some View {
        Form {
            
            // MARK: Album Artwork & Title
            if sizeClass == .compact {
                VStack(alignment: .center) {
                    AlbumImage(album: album)
                    
                    TextField("Add Title", text: $album.title, axis: .vertical)
                        .font(.largeTitle.bold())
                        .focused($keyboardFocus, equals: .title)
                        .submitLabel(.return)
                        .onSubmit { keyboardFocus = nil }
                    
                    TextField("Add Artist", text: $album.artist, axis: .vertical)
                        .font(.headline)
                        .focused($keyboardFocus, equals: .artist)
                        .submitLabel(.return)
                        .onSubmit { keyboardFocus = nil }
                    
                    HStack {
                        
                        Button(action: playAlbum, label: {
                            Text("\(Image(systemName: "play.fill")) Play")
                                .frame(maxWidth: .infinity)
                                .bold()
                        })
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        
                        PhotosPicker(selection: $artworkSelection, matching: .not(.videos)) {
                            Text("\(Image(systemName: "photo")) Artwork")
                                .frame(maxWidth: .infinity)
                                .bold()
                        }
                        .photosPickerStyle(.presentation)
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        
                        .onChange(of: artworkSelection) {
                            Task {
                                if let loaded = try? await artworkSelection?.loadTransferable(type: Data.self) {
                                    album.artwork = loaded
                                    audioManager.updateNewTrackData()
                                } else {
                                    print("Artwork load failed")
                                }
                            }
                        }
                    }
                    .padding(.vertical)
                    .monospaced(false)
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
                .multilineTextAlignment(.center)
            }
            
            if sizeClass == .regular {
                HStack(alignment: .center) {
                    AlbumImage(album: album, width: 400, height: 400)
                    Spacer()
                    VStack(alignment: .center) {
                        TextField("Add Title", text: $album.title, axis: .vertical)
                            .font(.largeTitle.bold())
                            .focused($keyboardFocus, equals: .title)
                            .submitLabel(.return)
                            .onSubmit { keyboardFocus = nil }
                        
                        TextField("Add Artist", text: $album.artist, axis: .vertical)
                            .font(.headline)
                            .focused($keyboardFocus, equals: .artist)
                            .submitLabel(.return)
                            .onSubmit { keyboardFocus = nil }
                        
                        HStack {
                            
                            Button(action: playAlbum, label: {
                                Text("\(Image(systemName: "play.fill")) Play")
                                    .frame(maxWidth: .infinity)
                                    .bold()
                            })
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                            
                            PhotosPicker(selection: $artworkSelection, matching: .not(.videos)) {
                                Text("\(Image(systemName: "photo")) Artwork")
                                    .frame(maxWidth: .infinity)
                                    .bold()
                            }
                            .photosPickerStyle(.presentation)
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                            
                            .onChange(of: artworkSelection) {
                                Task {
                                    if let loaded = try? await artworkSelection?.loadTransferable(type: Data.self) {
                                        album.artwork = loaded
                                        audioManager.updateNewTrackData()
                                    } else {
                                        print("Artwork load failed")
                                    }
                                }
                            }
                        }
                        .padding(.vertical)
                        .monospaced(false)
                        
                    }
                    .padding(.horizontal, 55)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
                .multilineTextAlignment(.center)
            }
            
            // MARK: Album detail editor
            
            Section {
                Picker("Genre", selection: $album.genre) {
                    ForEach(MusicGenre.allCases, id: \.self) {
                        Text($0.rawValue)
                    }
                }
                .pickerStyle(.navigationLink)
                
                DatePicker("Release Date:", selection: $album.releaseDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                
            } header: {
                Text("Album Details")
            }
            
            Section {
                List {
                    ForEach(orderedTracks) { track in
                        TrackListItem(track: track, trackList: orderedTracks)
                    }
                    .onDelete(perform: deleteTracks)
                    .onMove(perform: moveTrack)
                }
                
                
                Button("Add Track") {
                    let newTrack = Track(index: orderedTracks.count + 1, album: album)
                    newTrack.genre = album.genre
                    album.trackListing.append(newTrack)
                    audioManager.queue.append(newTrack)
                    navPath.append(newTrack)
                }
            } header: {
                Text("Track Listing")
            }
            
            Section {
                TextEditor(text: $album.linerNotes)
                    .frame(minHeight: 300)
                    .focused($keyboardFocus, equals: .linerNotes)
            } header: {
                Text("Liner Notes")
            }
        }
        .navigationTitle("Edit Album")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Track.self) {
            TrackEditorView(track: $0, path: $navPath)
        }
        .toolbar {
            
            if keyboardFocus != nil {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { keyboardFocus = nil }
                }
            }
            
            
            ToolbarItem {
                Menu {
                    Button(action: iPod, label: {
                        Label(audioManager.showingPlayer ? "Hide miniplayer" : "Show miniplayer", systemImage: "ipod")
                    })
                    
//                    Button(action: {}, label: {
//                        Label("Share album", systemImage: "square.and.arrow.up")
//                    })
//                    .disabled(true)
//                    
//                    Button(action: {}, label: {
//                        Label("Export album data", systemImage: "doc.text.image")
//                    })
//                    .disabled(true)
                    
                    Button(role: .destructive, action: {
                        album.artwork = nil
                        artworkSelection = nil
                        audioManager.updateNewTrackData()
                    }) {
                        Label("Delete artwork", systemImage: "trash")
                    }
                    .disabled(album.artwork == nil)
                    
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
    
    
    func deleteTracks(_ indexSet: IndexSet) {
        if audioManager.isPlaying {
            let track = album.trackListing[indexSet.first!]
            if audioManager.currentTrack == track {
                audioManager.skipToNext()
            }
        }
        album.trackListing.remove(atOffsets: indexSet)
    }
    
    func moveTrack(from source: IndexSet, to destination: Int) {
        // Create a new array to work with
        var updatedTracks = orderedTracks
        updatedTracks.move(fromOffsets: source, toOffset: destination)
        
        // Update all indices in the ModelContext
        @Bindable var album = self.album
        
        for (position, track) in updatedTracks.enumerated() {
            track.index = position + 1
        }
        if audioManager.isPlaying {
            audioManager.queue = updatedTracks
        }
        
    }
    
    func iPod() {
        if audioManager.currentTrack == nil {
            audioManager.loadQueue(for: album)
        }
        withAnimation {
            audioManager.showingPlayer.toggle()
        }
    }
    
    func playAlbum() {
        withAnimation {
            if let track = orderedTracks.first {
                audioManager.playTrack(track)
            }
            if !audioManager.showingPlayer {
                audioManager.showingPlayer.toggle()
            }
        }
    }
}
