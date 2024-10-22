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
    @Binding private var offset: CGFloat
    @State private var textWidth: CGFloat = 0
    @State private var shouldAnimate = false
    @State private var isAnimating = false
    
    init(_ text: String, offset: Binding<CGFloat>, width: CGFloat = 200, height: CGFloat = 16, speed: Double = 40) {
        self.text = text
        self._offset = offset
        self.width = width
        self.height = height
        self.speed = speed
    }
    
    // Animation config
    private let pauseDuration: Double = 1.5
    private var scrollDuration: Double {
        // Adjust the factor to control speed
        return Double(textWidth) / speed
    }
    var body: some View {
        GeometryReader { geo in
            Text(text)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: true)
                .offset(x: offset)
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
        }
        .frame(width: width, height: height)
        .clipped()
    }
    
    private func startAnimation() {
        // Reset to start position
        offset = 0
        isAnimating = true
        
        // Initial pause
        DispatchQueue.main.asyncAfter(deadline: .now() + pauseDuration) {
            // Animate to end
            withAnimation(.linear(duration: scrollDuration)) {
                offset = -textWidth + width
            }
            
            // Pause at end
            DispatchQueue.main.asyncAfter(deadline: .now() + scrollDuration + pauseDuration) {
                // Animate back to start
                withAnimation(.linear(duration: scrollDuration)) {
                    offset = 0
                }
                
                // Restart the cycle after returning to start
                DispatchQueue.main.asyncAfter(deadline: .now() + scrollDuration + pauseDuration) {
                    startAnimation()
                }
            }
        }
    }
}
