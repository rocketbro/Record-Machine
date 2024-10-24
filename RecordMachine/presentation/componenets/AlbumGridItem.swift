//
//  AlbumGridItem.swift
//  RecordMachine
//
//  Created by Asher Pope on 10/24/24.
//

import SwiftUI

struct AlbumGridItem: View {
    let album: Album
    var body: some View {
        VStack(alignment: .leading) {
            AlbumImage(album: album)
                .frame(width: 50, height: 50)
            Text(album.title)
                .bold()
                .font(.caption)
            Text(album.artist)
                .font(.caption)
        }
    }
}
