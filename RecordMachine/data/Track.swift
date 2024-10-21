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
    var index: Int
    var writers: String
    var bpm: Int
    var key: MusicKey
    var genre: MusicGenre
    var lyrics: String
    var notes: String
    var album: Album?
    var audioUrl: URL?
    var attachedFiles: [AttachedFile]
    
    init(title: String = "", index: Int = 0, writers: String = "", bpm: Int = 120, key: MusicKey = .c, genre: MusicGenre = .acoustic, lyrics: String = "", notes: String = "", album: Album? = nil, attachedFiles: [AttachedFile] = []) {
        self.title = title
        self.index = index
        self.writers = writers
        self.bpm = bpm
        self.key = key
        self.genre = genre
        self.lyrics = lyrics
        self.notes = notes
        self.album = album
        self.attachedFiles = attachedFiles
    }
}
