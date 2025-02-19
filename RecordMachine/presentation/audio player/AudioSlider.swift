//
//  AudioSlider.swift
//  RecordMachine
//
//  Created by Asher Pope on 10/22/24.
//

import SwiftUI

struct AudioSlider: View {
    @Environment(AudioManager.self) var audioManager
    let onEditingChanged: (Bool) -> Void
    let onSeek: (Double) -> Void
    
    @State private var seekPosition: Double? = nil
    @State private var isDragging = false
    
    // Constants for layout
    private let handleDiameter: CGFloat = 12
    private let trackHeight: CGFloat = 4
    private let minimumTouchTarget: CGFloat = 20
    
    var duration: Double {
        return audioManager.duration
    }
    
    var remainingDuration: Double {
        guard duration > 0 else { return 0 }
        guard let seekPosition = seekPosition else {
            return duration - audioManager.currentTime
        }
        return duration - seekPosition
    }
    
    var currentTime: Double {
        return audioManager.currentTime
    }
    
    var body: some View {
        VStack(spacing: 4) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: trackHeight)
                    
                    // Progress bar
                    Rectangle()
                        .fill(Color.primary.opacity(isDragging ? 0.5 : 1.0))
                        .frame(width: progressWidth(in: geometry), height: trackHeight)
                }
                .cornerRadius(trackHeight / 2)
                // Custom slider handle
                .overlay(
                    Circle()
                        .fill(.clear)
                        .contentShape(Circle())
                        .frame(width: handleDiameter, height: handleDiameter)
                        .shadow(radius: isDragging ? 4 : 0)
                        .position(
                            x: handlePosition(in: geometry),
                            y: trackHeight / 2
                        )
                        .scaleEffect(isDragging ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3), value: isDragging)
                )
                // Gesture handling with debouncing
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            withAnimation(.linear(duration: 0)) {
                                updateSeekPosition(value: value, geometry: geometry)
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
            .frame(height: minimumTouchTarget)
            .contentShape(Rectangle())
            
            // Time labels
            HStack {
                Text(formatTime(displayTime))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(formatTime(remainingDuration))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // Helper functions for layout calculations
    private func progressWidth(in geometry: GeometryProxy) -> CGFloat {
        guard duration > 0 else { return 0 }
        let trackWidth = max(0, geometry.size.width - handleDiameter)
        let progress = CGFloat(max(0, min(displayTime, duration)) / duration)
        return max(0, min(trackWidth * progress, geometry.size.width))
    }
    
    private func handlePosition(in geometry: GeometryProxy) -> CGFloat {
        guard duration > 0 else { return handleDiameter / 2 }
        let trackWidth = max(0, geometry.size.width - handleDiameter)
        let time = max(0, min(displayTime, duration))
        let progress = CGFloat(time / duration)
        let position = (trackWidth * progress) + (handleDiameter / 2)
        return max(handleDiameter / 2, min(position, geometry.size.width - handleDiameter / 2))
    }
    
    private func updateSeekPosition(value: DragGesture.Value, geometry: GeometryProxy) {
        let trackWidth = max(0, geometry.size.width - handleDiameter)
        let xPosition = value.location.x
        
        // Constrain the drag position to the track bounds
        let boundedX = min(max(handleDiameter/2, xPosition), geometry.size.width - handleDiameter/2)
        
        // Calculate time based on bounded position
        let percentage = (boundedX - handleDiameter/2) / trackWidth
        let newTime = Double(percentage) * duration
        
        seekPosition = max(0, min(newTime, duration))
        
        if !isDragging {
            isDragging = true
            onEditingChanged(true)
        }
    }
    
    private let timeFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
    
    private func formatTime(_ time: Double) -> String {
        guard time.isFinite && !time.isNaN && time >= 0 else {
            return "00:00:00"
        }
        
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60
        
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    var displayTime: Double {
        return seekPosition ?? currentTime
    }
}
