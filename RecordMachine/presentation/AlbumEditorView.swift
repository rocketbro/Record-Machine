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
    @Bindable var album: Album
    @Binding var navPath: NavigationPath
    @State private var artworkSelection: PhotosPickerItem?
    
    var body: some View {
        Form {
            VStack(alignment: .center) {
                if let artworkData = album.artwork, let uiImage = UIImage(data: artworkData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(1/1, contentMode: .fill)
                        .cornerRadius(12)
                }
                
                Text(album.title.isEmpty ? "Unknown Album" : album.title)
                    .font(.title.bold())
                
                Text(album.artist.isEmpty ? "Unknown Artist" : album.artist)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .listRowBackground(Color.clear)
            .multilineTextAlignment(.center)
            
            Section {
                HStack {
                    Text("Title:")
                    Spacer()
                    TextField("Title", text: $album.title, axis: .vertical)
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(primaryOrange)
                }
                HStack {
                    Text("Artist:")
                    Spacer()
                    TextField("Artist", text: $album.artist, axis: .vertical)
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(primaryOrange)
                }
                
                DatePicker("Release Date:", selection: $album.releaseDate)
                    .datePickerStyle(.compact)
                
                PhotosPicker("Update Artwork", selection: $artworkSelection, matching: .not(.videos))
                    .photosPickerStyle(.presentation)
                    .onChange(of: artworkSelection) {
                        Task {
                            if let loaded = try? await artworkSelection?.loadTransferable(type: Data.self) {
                                album.artwork = loaded
                            } else {
                                print("Artwork load failed")
                            }
                        }
                    }
                
            } header: {
                Text("Album Details")
            }
            
            Section {
//                List($album.trackListing, editActions: .all) { $track in
//                    NavigationLink(value: track) {
//                        Text(track.title)
//                    }
//                }
                List {
                    ForEach(album.trackListing) { track in
                        NavigationLink(value: track) {
                            Text(track.title)
                        }
                    }
                    .onDelete(perform: deleteTracks)
                    .onMove(perform: move)
                }
                
                
                Button("Add Song") {
                    let newTrack = Track(album: album)
                    album.trackListing.append(newTrack)
                    navPath.append(newTrack)
                }
            } header: {
                Text("Track Listing")
            }
            
            Section {
                TextField("Liner Notes", text: $album.linerNotes, axis: .vertical)
            } header: {
                Text("Liner Notes")
            }
        }
        .navigationTitle("Edit Album")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Track.self) {
            TrackEditorView(track: $0)
        }
    }
    
    func deleteTracks(_ indexSet: IndexSet) {
        album.trackListing.remove(atOffsets: indexSet)
    }
    
    func move(from source: IndexSet, to destination: Int) {
        album.trackListing.move(fromOffsets: source, toOffset: destination)
    }
}
