//
//  TrackEditorView.swift
//  RecordMachine
//
//  Created by Asher Pope on 1/3/24.
//

import SwiftUI
import SwiftData

struct TrackEditorView: View {
    @Bindable var track: Track
    @Query var albums: [Album]
    
    var body: some View {
        Form {
            Section {
                HStack {
                    Text("Title:")
                    Spacer()
                    TextField("Title", text: $track.title, axis: .vertical)
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(primaryOrange)
                }
                HStack {
                    Text("Writers:")
                    Spacer()
                    TextField("Writers", text: $track.writers, axis: .vertical)
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(primaryOrange)
                }
                
                Picker("Album:", selection: $track.album) {
                    ForEach(albums) { album in
                        Text(album.title)
                    }
                }
                .pickerStyle(.navigationLink)
                
                TextField("Misc Notes", text: $track.notes, axis: .vertical)
            } header: {
                Text("Track Info")
            }
            
            Section {
                TextEditor(text: $track.lyrics)
                    .frame(minHeight: 500)
            } header: {
                Text("Lyrics")
            }
        }
        .navigationTitle("Edit Track")
        .navigationBarTitleDisplayMode(.inline)
    }
}
