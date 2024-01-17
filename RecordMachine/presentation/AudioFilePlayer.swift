//
//  AudioEngine.swift
//  RecordMachine
//
//  Created by Asher Pope on 1/6/24.
//

import SwiftUI
import AVFoundation

struct AudioFilePlayer: View {
    @Bindable var track: Track
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var presentFileImporter = false
    @State private var fileLength: Double = 0
    @Binding var fileName: String
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var formattedTime: String {
        let hours = Int(fileLength) / 3600
        let minutes = (Int(fileLength) % 3600) / 60
        let seconds = Int(fileLength) % 60
        
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    var body: some View {
        VStack(alignment: .center) {
            VStack {
                Text("\(formattedTime)")
                    .font(.title3)
                    .onReceive(timer) { _ in
                        if isPlaying {
                            if fileLength > 0 {
                                fileLength -= 1
                            }
                        }
                    }
                
                Text(fileName)
                    .font(.caption)
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
            .background(.black)
            .cornerRadius(6)
            
            HStack(alignment: .center) {
                
                Spacer()
                
                Button(action: playPause) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.title2)
                        .frame(width: 24, height: 6)
                        .padding()
                        .background(.gray.opacity(0.25))
                        .cornerRadius(4)
                        .tint(.green)
                }
                .onAppear {
                    prepareAudioPlayer()
                }
                .disabled(track.audioUrl == nil)
                
                Button(action: restartAudioPlayer) {
                    Image(systemName: "backward.fill")
                        .font(.title2)
                        .frame(width: 24, height: 6)
                        .padding()
                        .background(.gray.opacity(0.25))
                        .cornerRadius(4)
                        .tint(.white)
                }
                .disabled(track.audioUrl == nil)
                
                Button(action: {
                    stopAudioPlayer()
                    presentFileImporter.toggle()
                }) {
                    Image(systemName: "waveform.badge.plus")
                        .font(.title2)
                        .frame(width: 24, height: 6)
                        .padding()
                        .background(.gray.opacity(0.25))
                        .cornerRadius(4)
                        .tint(.white)
                }
                .fileImporter(isPresented: $presentFileImporter, allowedContentTypes: [UTType.mp3, UTType.mpeg4Audio, UTType.aiff, UTType.wav, UTType.audio]) { result in
                    switch result {
                    case .success(let url):
                        track.audioUrl = url
                        prepareAudioPlayer()
                    case .failure(let error):
                        print(error)
                    }
                }
                
                Button(action: {
                    stopAudioPlayer()
                    track.audioUrl = nil
                    fileLength = 0
                    fileName = "Import an audio file below"
                }) {
                    Image(systemName: "trash.fill")
                        .font(.title2)
                        .frame(width: 24, height: 6)
                        .padding()
                        .background(.gray.opacity(0.25))
                        .cornerRadius(4)
                        .tint(.red)
                }
                .disabled(track.audioUrl == nil)
                
                Spacer()
                
                
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        //.background(.blue.opacity(0.25))
        .background(primaryOrange.opacity(0.25))
        .cornerRadius(8)
        .buttonStyle(.borderless)
        .frame(maxWidth: 500)
    }
    
    
    func prepareAudioPlayer() {
        guard let url = track.audioUrl else {
            print("\(track.title).audioUrl is nil.")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            fileLength = audioPlayer?.duration ?? 0
            fileName = url.lastPathComponent
        } catch {
            print("Error creating audio player: \(error.localizedDescription)")
        }
    }
    
    func playPause() {
        guard let audioPlayer = audioPlayer else {
            print("Audio player is nil.")
            return
        }
        
        if audioPlayer.isPlaying {
            audioPlayer.pause()
            isPlaying = false
        } else {
            audioPlayer.play()
            isPlaying = true
        }
    }
    
    func restartAudioPlayer() {
        guard let audioPlayer = audioPlayer else {
            print("Audio player is nil.")
            return
        }
        //        audioPlayer.pause()
        //        isPlaying = false
        audioPlayer.currentTime = 0
        fileLength = audioPlayer.duration
        //        audioPlayer.play()
        //        isPlaying = true
    }
    
    func stopAudioPlayer() {
        guard let audioPlayer = audioPlayer else {
            print("Audio player is nil.")
            return
        }
        audioPlayer.stop()
        isPlaying = false
    }
}
