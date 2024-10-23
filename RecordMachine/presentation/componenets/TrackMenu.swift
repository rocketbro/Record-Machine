//
//  TrackMenu.swift
//  RecordMachine
//
//  Created by Asher Pope on 10/23/24.
//

import SwiftUI

struct TrackMenu: View {
    let track: Track
    
    var body: some View {
        Menu {
            NavigationLink(value: track) {
                Label("Edit track details", systemImage: "pencil")
            }
            
            Button(action: {}, label: {
                Label("Share track", systemImage: "square.and.arrow.up")
            }).disabled(true)
            
        } label: {
            Image(systemName: "ellipsis")
                .tint(.white)
        }
    }
}
