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
    @Environment(AudioManager.self) private var audioManager
    @Query(sort: \Album.title) var albums: [Album]
    @State private var navPath = NavigationPath()
    @State private var showOnboarding: Bool = false
    @AppStorage("isFirstLaunch") var isFirstLaunch: Bool = true
    
    // Create a grid layout with 2 columns of equal width
//    let columns = [
//        GridItem(.flexible()),
//        GridItem(.flexible())
//    ]
    
    var body: some View {
        
        
        ZStack(alignment: .bottom) {
            // Main content
            NavigationStack(path: $navPath) {
                
                
//                LazyVGrid(columns: columns, spacing: 16) {
//                    ForEach(albums.indices, id: \.self) { index in
//                        NavigationLink(value: albums[index]) {
//                            AlbumGridItem(album: albums[index])
//                        }
//                    }
//                }
//                .padding()
                
                
                
                
                List {
                    ForEach(albums) { album in
                        NavigationLink(value: album) {
                            VStack {
                                HStack {
                                    if let artworkData = album.artwork {
                                        if let uiImage = UIImage(data: artworkData) {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 50, height: 50)
                                                .clipped()
                                                .cornerRadius(4)
                                            
                                        }
                                    }
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
                .navigationTitle("Records")
                .navigationDestination(for: Album.self) {
                    AlbumEditorView(album: $0, navPath: $navPath)
                }
                .toolbar {
                    ToolbarItem {
                        Button("Add Album", systemImage: "plus", action: addAlbum)
                    }
                    ToolbarItem {
                        Button("Toggle Player", systemImage: "ipod") {
                            withAnimation {
                                audioManager.showingPlayer.toggle()
                            }
                        }
                    }
                }
                .sheet(isPresented: audioManager.sheetBinding) {
                    LargeAudioPlayer()
                }
                .onAppear {
                    if isFirstLaunch {
                        showOnboarding = true
                        isFirstLaunch = false
                    } else {
                        print("Not first launch.")
                    }
                }
                .sheet(isPresented: $showOnboarding) {
                    OnBoarding(isPresented: $showOnboarding)
                }
            }
            
            if audioManager.showingPlayer {
                withAnimation {
                    VStack {
                        Spacer()
                        MiniAudioPlayer()
                            .padding(.horizontal, 6)
                            .padding(.bottom, 6)
                            .shadow(color: .black.opacity(0.35), radius: 20)
                            .transition(.move(edge: .bottom))
                            .onAppear {
                                if audioManager.currentTrack == nil {
                                    guard let album = albums.first else { return }
                                    audioManager.loadQueue(for: album)
                                }
                            }
                            .onTapGesture {
                                audioManager.showFullPlayer.toggle()
                            }
                    }
                    .zIndex(2)
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
