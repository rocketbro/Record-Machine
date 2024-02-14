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
    @Bindable var album: Album
    @Binding var navPath: NavigationPath
    @State private var artworkSelection: PhotosPickerItem?
    
    enum KeyboardFocus {
        case title, artist, linerNotes
    }
    
    @FocusState private var keyboardFocus: KeyboardFocus?
    
    var body: some View {
        Form {
            
            // MARK: Album Artwork & Title
            if sizeClass == .compact {
                VStack(alignment: .center) {
                    ZStack {
                        if let artworkData = album.artwork, let uiImage = UIImage(data: artworkData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(1/1, contentMode: .fill)
                                .blur(radius: 50)
                        }
                        
                        if let artworkData = album.artwork, let uiImage = UIImage(data: artworkData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(1/1, contentMode: .fill)
                                .cornerRadius(8)
                                .padding()
                        }
                    }
                    
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
                    ZStack {
                        if let artworkData = album.artwork, let uiImage = UIImage(data: artworkData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(1/1, contentMode: .fill)
                                .blur(radius: 50)
                        }
                        
                        if let artworkData = album.artwork, let uiImage = UIImage(data: artworkData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(1/1, contentMode: .fill)
                                .cornerRadius(8)
                                .padding()
                        }
                    }
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
                    TextField("Title", text: $album.title, axis: .vertical)
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(primaryOrange)
                        .focused($keyboardFocus, equals: .title)
                        .onSubmit { keyboardFocus = nil }
                        
                }
                
                HStack {
                    Text("Artist:")
                    Spacer()
                    TextField("Artist", text: $album.artist, axis: .vertical)
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(primaryOrange)
                        .focused($keyboardFocus, equals: .artist)
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
                    ForEach(album.trackListing) { track in
                        NavigationLink(value: track) {
                            Text("\((album.trackListing.firstIndex(of: track) ?? 0) + 1). \(track.title.isEmpty ? "Unknown Track" : track.title)")
                        }
                    }
                    .onDelete(perform: deleteTracks)
                    .onMove(perform: move)
                }
                
                
                Button("Add Song") {
                    let newTrack = Track(album: album)
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
            ToolbarItem {
                PhotosPicker(selection: $artworkSelection, matching: .not(.videos)) {
                    Image(systemName: album.artwork == nil ? "photo.badge.plus" : "photo")
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
                    NavigationLink("Play album", destination: RecordPlayerView(album: album))
                    Button("Export album") { /* export code here */ }
                        .disabled(true)
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
        }
    }
    
    func deleteTracks(_ indexSet: IndexSet) {
        album.trackListing.remove(atOffsets: indexSet)
    }
    
    func move(from source: IndexSet, to destination: Int) {
//        var tl = album.trackListing
//        for index in source {
//            if tl[index] == tl.first {
//                tl[index].trackNumber = 0
//                for trackIndex in tl.indices {
//                    tl[trackIndex].trackNumber += 1
//                }
//            }
//        }
        album.trackListing.move(fromOffsets: source, toOffset: destination)
    }
}
