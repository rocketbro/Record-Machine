//
//  AlbumImage.swift
//  RecordMachine
//
//  Created by Asher Pope on 10/21/24.
//

import SwiftUI

struct AlbumImage: View {
    @Environment(AudioManager.self) var audioManager
    let album: Album
    var width: CGFloat = 300
    var height: CGFloat = 300
    var cornerRadius: CGFloat = 8
    
    private var albumTitle: String {
        guard let title = audioManager.currentTrack?.album?.title else { return "Unknown Album" }
        
        if title == "" {
            return "Unknown Album"
        } else {
            return "\(title)"
        }
    }
    
    private var artist: String {
        guard let artist = audioManager.currentTrack?.album?.artist else { return "Unknown Artist" }
        
        if artist == "" {
            return "Unknown Artist"
        } else {
            return "\(artist)"
        }
    }
    
    var body: some View {
        if let artworkData = album.artwork {
            ZStack {
                if let uiImage = UIImage(data: artworkData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: width, height: height)
                        .clipped()
                        .blur(radius: 50)
                }
                
                if let uiImage = UIImage(data: artworkData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: width, height: height)
                        .clipped()
                        .cornerRadius(cornerRadius)
                        .padding()
                    
                }
            }
            .aspectRatio(1/1, contentMode: .fit)
        } else {
            ZStack {
                
                VStack(spacing: 30) {
                    Text(albumTitle)
                        .font(.title)
                    Text(artist)
                        .font(.title3)
                }
                .frame(width: width, height: height)
                .background(.ultraThinMaterial)
                .clipped()
                .blur(radius: 50)
                
                
                VStack(spacing: 30) {
                    Text(albumTitle)
                        .font(.title)
                    Text(artist)
                        .font(.title3)
                }
                
                .frame(width: width, height: height)
                .background(.ultraThinMaterial)
                .clipped()
                .cornerRadius(cornerRadius)
                .padding()
                
                
            }
            .aspectRatio(1/1, contentMode: .fit)
        }
    }
}
