import Foundation

struct StreamTrack: Identifiable, Codable {
    let id: String
    let title: String
    let artist: String
    let objectPath: String
    
    // For demo purposes, we'll hardcode our test track
    static let demoTrack = StreamTrack(
        id: "demo-1",
        title: "Live 2024",
        artist: "Skrillex",
        objectPath: "demos/skrillex-live-2024.mp3"
    )
} 