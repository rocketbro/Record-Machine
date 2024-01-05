//
//  RecordMachineApp.swift
//  RecordMachine
//
//  Created by Asher Pope on 1/3/24.
//

import SwiftUI
import SwiftData

@main
struct RecordMachineApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .monospaced()
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: Album.self)
    }
}
