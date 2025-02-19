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

    static let weezer = StreamTrack(
        id: "demo-2",
        title: "Blast Off!",
        artist: "Weezer",
        objectPath: "demos/weezer-blast-off!.mp3"
    )
    
    static let spinners = StreamTrack(id: "demo-3", title: "Long, Long Time", artist: "Asher & the Spinners", objectPath: "demos/asher-and-the-spinners-long-long-time.mp3")
}
