//
//  OnBoarding.swift
//  RecordMachine
//
//  Created by Asher Pope on 10/24/24.
//

import SwiftUI

struct OnBoarding: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            Text("Welcome to Record Machine")
                .font(.largeTitle)
                .bold()
                .multilineTextAlignment(.center)
            Text("Organize everything you need\nfor your next release.")
                .multilineTextAlignment(.center)
                .padding(.bottom, 30)
            OnboardingItem(text: "From the records page, tap the plus sign to create a new record. You can add tracks from the record details page.", systemImage: "plus")
            OnboardingItem(text: "Once you've created a track, you can attach an audio file.", systemImage: "waveform.badge.plus")
            OnboardingItem(text: "When the miniplayer is visible, tap on it to open the full screen music player. Swipe down to get back.", systemImage: "ipod")
            Spacer()
            Spacer()
            Button(action: { isPresented.toggle() }, label: {
                Text("Let's Go")
                    .frame(maxWidth: .infinity)
                    .bold()
            })
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            Spacer()
        }
        .padding(.horizontal, 30)
        .monospaced(false)
    }
}

struct OnboardingItem: View {
    let text: String
    let systemImage: String
    
    var body: some View {
        HStack(alignment: .center) {
            Image(systemName: systemImage)
                .font(.title)
                .padding(.trailing)
                .foregroundStyle(.accent)
            Text(text)
                .multilineTextAlignment(.leading)
                .font(.headline)
            Spacer()
        }
    }
}

#Preview {
    OnBoarding(isPresented: .constant(true))
}
