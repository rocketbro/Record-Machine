//
//  ContentView.swift
//  RecordMachine
//
//  Created by Asher Pope on 1/3/24.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) var modelContext
    @Query var albums: [Album]
    @State private var navPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navPath) {
            List {
                ForEach(albums) { album in
                    NavigationLink(value: album) {
                        VStack {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(album.title.isEmpty ? "Unknown Album" : album.title)
                                        .font(.headline)
                                    Text(album.artist.isEmpty ? "Unknown Artist" : album.artist)
                                        .font(.subheadline)
                                }
                                Spacer()
                                Text(String(album.trackListing.count) + (album.trackListing.count == 1 ? " track" : " tracks"))
                                    .font(.subheadline)
                                    .padding(.horizontal)
                                    .padding(.vertical, 4)
                                    .background(primaryOrange)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
                .onDelete(perform: deleteAlbums)
            }
            .navigationTitle("Record Machine")
            .navigationDestination(for: Album.self) {
                AlbumEditorView(album: $0, navPath: $navPath)
            }
            .toolbar {
                ToolbarItem {
                    Button("Add Album", systemImage: "plus", action: addAlbum)
                }
            }
        }
    }
    
    func addAlbum() {
        let album = Album()
        modelContext.insert(album)
        navPath.append(album)
    }
    
    func deleteAlbums(_ indexSet: IndexSet) {
        for index in indexSet {
            let album = albums[index]
            modelContext.delete(album)
        }
    }
}

//#Preview {
//    ContentView()
//}
