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
    var title: String = "Untitled"
    var artist: String = "Unknown artist"
    var genre: MusicGenre = MusicGenre.acoustic
    var releaseDate: Date = Date.now
    var linerNotes: String = ""
    var artwork: Data? = nil
    var trackListing = [Track]()
    
    init(title: String = "", artist: String = "", genre: MusicGenre = .acoustic, releaseDate: Date = .now, linerNotes: String = "") {
        self.title = title
        self.artist = artist
        self.genre = genre
        self.releaseDate = releaseDate
        self.linerNotes = linerNotes
    }
}
