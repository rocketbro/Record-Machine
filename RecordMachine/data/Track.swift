//
//  Track.swift
//  RecordMachine
//
//  Created by Asher Pope on 1/3/24.
//

import Foundation
import SwiftData

@Model
class Track {
    var title: String
    var writers: String
    var lyrics: String
    var notes: String
    var album: Album?
    
    init(title: String = "", writers: String = "", lyrics: String = "", notes: String = "", album: Album? = nil) {
        self.title = title
        self.writers = writers
        self.lyrics = lyrics
        self.notes = notes
        self.album = album
    }
}
