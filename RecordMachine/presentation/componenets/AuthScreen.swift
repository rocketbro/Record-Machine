//
//  AuthScreen.swift
//  RecordMachine
//
//  Created by Asher Pope on 2/18/25.
//
import SwiftUI

struct AuthScreen: View {
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Record Machine")
                .font(.largeTitle)
                .bold()
            
            Text("Sign in to start creating albums")
                .foregroundStyle(.secondary)
            
            SignInWithAppleView()
                .frame(width: 280, height: 45)
                .padding(.top)
        }
        .padding()
    }
}
