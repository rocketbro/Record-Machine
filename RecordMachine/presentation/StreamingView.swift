import SwiftUI

struct StreamingView: View {
    @Environment(AudioManager.self) private var audioManager
    
    // For now, we'll just show our demo track
    private let availableTracks = [StreamTrack.demoTrack]
    
    var body: some View {
        List {
            ForEach(availableTracks) { track in
                Button(action: {
                    audioManager.loadStreamingQueue([track])
                    audioManager.showingPlayer = true
                }) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(track.title)
                                .font(.headline)
                            Text(track.artist)
                                .font(.subheadline)
                        }
                        Spacer()
                        Image(systemName: "play.circle.fill")
                            .font(.title2)
                            .foregroundStyle(primaryOrange)
                    }
                    .contentShape(Rectangle())
                }
            }
        }
        .navigationTitle("Streaming Library")
    }
} 