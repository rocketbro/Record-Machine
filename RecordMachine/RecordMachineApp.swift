//
//  RecordMachineApp.swift
//  RecordMachine
//
//  Created by Asher Pope on 1/3/24.
//

import SwiftUI
import SwiftData
import AVFoundation

@main
struct RecordMachineApp: App {
    @State private var audioManager = AudioManager()
    @State private var authManager = AuthManager()
    @AppStorage("isFirstLaunch") private var isFirstLaunch = true
    
    init() {
        configureAudioSession()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(audioManager)
                .environment(authManager)
                .monospaced()
                .preferredColorScheme(.dark)
        }.modelContainer(for: Album.self)
    }
    
    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.allowAirPlay, .allowBluetooth, .allowBluetoothA2DP, .mixWithOthers, .defaultToSpeaker])
            try session.setActive(true)
        } catch {
            print("Error setting audio session:", error.localizedDescription)
        }
    }
}
