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
    
    @Relationship(deleteRule: .cascade, inverse: \Track.album) 
    var trackListing = [Track]()
    
    init(
        title: String = "",
        artist: String = "",
        genre: MusicGenre = .acoustic,
        releaseDate: Date = .now,
        linerNotes: String = ""
    ) {
        self.title = title
        self.artist = artist
        self.genre = genre
        self.releaseDate = releaseDate
        self.linerNotes = linerNotes
    }
}

// MARK: - Supabase DTO
struct AlbumDTO: Codable {
    let id: UUID
    var title: String
    var artist: String
    var s3FolderPath: String?
    var isStreamingEnabled: Bool
    var createdAt: Date
    var updatedAt: Date
    var visibility: String
    var ownerId: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case artist
        case s3FolderPath = "s3_folder_path"
        case isStreamingEnabled = "is_streaming_enabled"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case visibility
        case ownerId = "owner_id"
    }
    
    // Convert DTO to SwiftData model
    func toModel() -> Album {
        let album = Album(
            title: title,
            artist: artist
        )
        return album
    }
    
    // Create DTO from SwiftData model
    static func fromModel(_ model: Album, ownerId: String?) -> AlbumDTO {
        return AlbumDTO(
            id: UUID(),  // Generate new UUID for new albums
            title: model.title,
            artist: model.artist,
            s3FolderPath: nil,  // Will be set when uploading
            isStreamingEnabled: false,
            createdAt: Date(),
            updatedAt: Date(),
            visibility: "private",
            ownerId: ownerId
        )
    }
}
