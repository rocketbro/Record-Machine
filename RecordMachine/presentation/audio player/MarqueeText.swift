//
//  MarqueeText.swift
//  RecordMachine
//
//  Created by Asher Pope on 10/21/24.
//

import SwiftUI

struct MarqueeText: View {
    let text: String
    var width: CGFloat
    var height: CGFloat
    var speed: Double
    @State private var offset: CGFloat = 0
    @State private var textWidth: CGFloat = 0
    @State private var shouldAnimate = false
    @State private var isAnimating = false
    @Environment(AudioManager.self) var audioManager
    @State private var showText: Bool = true
    @State private var animationWorkItem: DispatchWorkItem?
    
    init(_ text: String, width: CGFloat = 200, height: CGFloat = 16, speed: Double = 40) {
        self.text = text
        self.width = width
        self.height = height
        self.speed = speed
    }
    
    // Animation config
    private let pauseDuration: Double = 1.5
    private var scrollDuration: Double {
        return Double(textWidth) / speed
    }
    
    var body: some View {
        GeometryReader { geo in
            Text(text)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: true)
                .offset(x: offset)
                .opacity(showText ? 1 : 0)
                .background {
                    GeometryReader { textGeo in
                        Color.clear.onAppear {
                            textWidth = textGeo.size.width
                            shouldAnimate = textWidth > width
                            
                            if shouldAnimate {
                                startAnimation()
                            }
                        }
                    }
                }
                .onChange(of: audioManager.currentTrack) {
                    resetAnimation()
                }
        }
        .frame(width: width > 0 ? width : 0, height: height > 0 ? height : 0)
        .clipped()
    }
    
    private func resetAnimation() {
        // Cancel any pending animations
        animationWorkItem?.cancel()
        animationWorkItem = nil
        
        // Reset visual state
        withAnimation(.linear(duration: 0.2)) {
            showText = false
            offset = 0
        }
        
        // Restart after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.linear(duration: 0.2)) {
                showText = true
            }
            if shouldAnimate {
                startAnimation()
            }
        }
    }
    
    private func startAnimation() {
        // Cancel any existing animation
        animationWorkItem?.cancel()
        
        // Reset to start position
        offset = 0
        isAnimating = true
        
        let workItem = DispatchWorkItem {
            animateSequence()
        }
        animationWorkItem = workItem
        
        DispatchQueue.main.asyncAfter(deadline: .now() + pauseDuration, execute: workItem)
    }
    
    private func animateSequence() {
        guard let currentWorkItem = animationWorkItem, !currentWorkItem.isCancelled else { return }
        
        // Animate to end
        withAnimation(.linear(duration: scrollDuration)) {
            offset = -textWidth + width
        }
        
        // Schedule next animation
        DispatchQueue.main.asyncAfter(deadline: .now() + scrollDuration + pauseDuration) {
            guard !currentWorkItem.isCancelled else { return }
            
            // Animate back to start
            withAnimation(.linear(duration: scrollDuration)) {
                offset = 0
            }
            
            // Schedule next cycle
            DispatchQueue.main.asyncAfter(deadline: .now() + scrollDuration + pauseDuration) {
                guard !currentWorkItem.isCancelled else { return }
                animateSequence()
            }
        }
    }
    
//    private func frameWidth(in geometry: GeometryProxy) -> CGFloat {
//        guard width > 0 else { return 0 }
//        let trackWidth = max(0, geometry.size.width - handleDiameter)
//        let progress = CGFloat(max(0, min(displayTime, duration)) / duration)
//        return max(0, min(trackWidth * progress, geometry.size.width))
//    }
}
