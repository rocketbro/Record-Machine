//
//  Album.swift
//  RecordMachine
//
//  Created by Asher Pope on 1/3/24.
//

import SwiftUI
import SwiftData

@Model
class Album {
    var title: String
    var artist: String
    var releaseDate: Date
    var linerNotes: String
    var artwork: Data?
    var trackListing = [Track]()
    
    init(title: String = "", artist: String = "", releaseDate: Date = .now, linerNotes: String = "") {
        self.title = title
        self.artist = artist
        self.releaseDate = releaseDate
        self.linerNotes = linerNotes
    }
}
