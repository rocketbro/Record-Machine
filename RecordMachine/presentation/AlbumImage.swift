//
//  AlbumImage.swift
//  RecordMachine
//
//  Created by Asher Pope on 10/21/24.
//

import SwiftUI

struct AlbumImage: View {
    let album: Album
    var width: CGFloat = 300
    var height: CGFloat = 300
    var cornerRadius: CGFloat = 8
    
    var body: some View {
        ZStack {
            if let artworkData = album.artwork, let uiImage = UIImage(data: artworkData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: width, height: height)
                    .clipped()
                    .blur(radius: 50)
            }
            
            if let artworkData = album.artwork, let uiImage = UIImage(data: artworkData) {
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
    }
}
