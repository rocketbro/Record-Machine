//
//  AudioSlider.swift
//  RecordMachine
//
//  Created by Asher Pope on 10/22/24.
//

import SwiftUI

struct AudioSlider: View {
    let duration: Double
    @Binding var currentTime: Double
    let onEditingChanged: (Bool) -> Void
    let onSeek: (Double) -> Void
    
    @State private var seekPosition: Double? = nil
    @State private var isDragging = false
    
    // Formatter for displaying time in mm:ss format
    private let timeFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
    
    private func formatTime(_ time: Double) -> String {
        return timeFormatter.string(from: time) ?? "0:00"
    }
    
    var displayTime: Double {
        seekPosition ?? currentTime
    }
    
    var body: some View {
        VStack(spacing: 4) {
            // Preview bubble when dragging
//            if isDragging {
//                Text(formatTime(displayTime))
//                    .font(.caption)
//                    .padding(.horizontal, 8)
//                    .padding(.vertical, 4)
//                    .background(
//                        RoundedRectangle(cornerRadius: 4)
//                            .fill(Color.accentColor)
//                    )
//                    .foregroundColor(.white)
//                    .transition(.opacity)
//                    .animation(.easeOut(duration: 0.1), value: isDragging)
//            }
            
            // Custom slider
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 4)
                    
                    // Playback progress
                    Rectangle()
                        .fill(Color.primary)
                        .frame(width: max(0, min(CGFloat(currentTime / duration) * geometry.size.width, geometry.size.width)), height: 4)
                    
                    // Preview position indicator
                    if let seekPosition = seekPosition {
                        Rectangle()
                            .fill(Color.primary.opacity(0.5))
                            .frame(width: max(0, min(CGFloat(seekPosition / duration) * geometry.size.width, geometry.size.width)), height: 4)
                    }
                }
                .cornerRadius(2)
                // Custom slider handle
                .overlay(
                    Circle()
                        .fill(Color.primary)
                        .frame(width: 12, height: 12)
                        .shadow(radius: isDragging ? 4 : 0)
                        .position(
                            x: max(6, min(CGFloat(displayTime / duration) * geometry.size.width, geometry.size.width - 6)),
                            y: 2
                        )
                        .scaleEffect(isDragging ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3), value: isDragging)
                )
                // Gesture handling
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let newTime = min(max(0, Double(value.location.x / geometry.size.width) * duration), duration)
                            seekPosition = newTime
                            
                            if !isDragging {
                                isDragging = true
                                onEditingChanged(true)
                            }
                        }
                        .onEnded { _ in
                            if let finalPosition = seekPosition {
                                onSeek(finalPosition)
                            }
                            isDragging = false
                            onEditingChanged(false)
                            seekPosition = nil
                        }
                )
            }
            .frame(height: 20) // Provide touch target
            .contentShape(Rectangle())
            
            // Time labels
            HStack {
                Text(formatTime(isDragging ? displayTime : currentTime))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(formatTime(duration))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
