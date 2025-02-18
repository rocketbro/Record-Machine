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
    var title: String = ""
    var index: Int = 0
    var writers: String = ""
    var bpm: Int = 120
    var key: MusicKey = MusicKey.c
    var genre: MusicGenre = MusicGenre.acoustic
    var lyrics: String = ""
    var notes: String = ""
    var audioUrl: URL? // Persisted URL for playback
    var attachedFiles: [AttachedFile] = []
    var album: Album?
    
    init(
        title: String = "",
        index: Int = 0,
        writers: String = "",
        bpm: Int = 120,
        key: MusicKey = .c,
        genre: MusicGenre = .acoustic,
        lyrics: String = "",
        notes: String = "",
        album: Album? = nil,
        attachedFiles: [AttachedFile] = []
    ) {
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

// MARK: - Supabase DTO
struct TrackDTO: Codable {
    let id: UUID
    var title: String
    var albumId: UUID
    var trackNumber: Int
    var s3FilePath: String?
    var durationSeconds: Int?
    var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case albumId = "album_id"
        case trackNumber = "track_number"
        case s3FilePath = "s3_file_path"
        case durationSeconds = "duration_seconds"
        case createdAt = "created_at"
    }
    
    // Convert DTO to SwiftData model
    func toModel(album: Album? = nil) -> Track {
        let track = Track(
            title: title,
            index: trackNumber,
            album: album
        )
        return track
    }
    
    // Create DTO from SwiftData model
    static func fromModel(_ model: Track, albumId: UUID) -> TrackDTO {
        return TrackDTO(
            id: UUID(),  // Generate new UUID for new tracks
            title: model.title,
            albumId: albumId,
            trackNumber: model.index,
            s3FilePath: nil,  // Will be set when uploading
            durationSeconds: nil,  // Will be set when uploading
            createdAt: Date()
        )
    }
}
