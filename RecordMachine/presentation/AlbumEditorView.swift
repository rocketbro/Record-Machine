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
                    
                    Text(album.title.isEmpty ? "Unknown Album" : album.title)
                        .font(.title.bold())
                    
                    Text(album.artist.isEmpty ? "Unknown Artist" : album.artist)
                        .font(.headline)
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
                        Text(album.title.isEmpty ? "Unknown Album" : album.title)
                            .font(.largeTitle.bold())
                        
                        Text(album.artist.isEmpty ? "Unknown Artist" : album.artist)
                            .font(.headline)
                        
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
                HStack {
                    Text("Title:")
                    Spacer()
                    TextField("Title", text: $album.title)
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(primaryOrange)
                        .focused($keyboardFocus, equals: .title)
                        .submitLabel(.done)
                        .onSubmit { keyboardFocus = nil }
                }
                
                HStack {
                    Text("Artist:")
                    Spacer()
                    TextField("Artist", text: $album.artist)
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(primaryOrange)
                        .focused($keyboardFocus, equals: .artist)
                        .submitLabel(.done)
                        .onSubmit { keyboardFocus = nil }
                }
                
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
                        NavigationLink(value: track) {
                            Text("\((orderedTracks.firstIndex(of: track) ?? 0) + 1). \(track.title.isEmpty ? "Unknown Track" : track.title)")
                        }
                    }
                    .onDelete(perform: deleteTracks)
                    .onMove(perform: moveTrack)
                }
                
                
                Button("Add Song") {
                    let newTrack = Track(index: orderedTracks.count + 1, album: album)
                    newTrack.genre = album.genre
                    album.trackListing.append(newTrack)
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
            
            if keyboardFocus == .linerNotes {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { keyboardFocus = nil }
                }
            }
            
            ToolbarItem {
                PhotosPicker(selection: $artworkSelection, matching: .not(.videos)) {
                    Label(
                        hasArtwork ? "Change artwork" : "add artwork",
                        systemImage: hasArtwork ? "photo" : "photo.badge.plus"
                    )
                }
                .photosPickerStyle(.presentation)
                .padding(.vertical)
                .onChange(of: artworkSelection) {
                    Task {
                        if let loaded = try? await artworkSelection?.loadTransferable(type: Data.self) {
                            album.artwork = loaded
                        } else {
                            print("Artwork load failed")
                        }
                    }
                }
            }
            
            ToolbarItem {
                Menu {
                    Button(role: .destructive, action: {
                        album.artwork = nil
                        artworkSelection = nil
                    }) {
                        Label("Delete artwork", systemImage: "trash")
                    }
                    .disabled(album.artwork == nil)
                    
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
            
            ToolbarItem {
                Button(action: iPod) {
                    Image(systemName: "ipod")
                }
            }
        }
    }
    
    
    func deleteTracks(_ indexSet: IndexSet) {
        album.trackListing.remove(atOffsets: indexSet)
    }
    
    func moveTrack(from source: IndexSet, to destination: Int) {
        // Create a new array to work with
        var updatedTracks = orderedTracks
        updatedTracks.move(fromOffsets: source, toOffset: destination)
        
        // Update all indices in the ModelContext
        @Bindable var album = self.album  // Add this if album is a @Model
        
        for (position, track) in updatedTracks.enumerated() {
            track.index = position + 1  // Assuming indices start at 1
        }
        
    }
    
    func iPod() {
        withAnimation {
            if audioManager.isPlaying {
                if let currentTrack = audioManager.currentTrack {
                    print(currentTrack.title)
                    if let album = currentTrack.album {
                        print(album.title)
                        print(self.album == album)
                        if album != self.album {
                            audioManager.loadQueue(for: album)
                        }
                        
                    }
                }
            } else {
                audioManager.loadQueue(for: album)
            }
            audioManager.showingPlayer.toggle()
        }
    }
}
