//
//  ConfettiView.swift
//  Shoebox
//
//  Created by Jiro Feingold
//  Copyright (c) 2026 Jiro Feingold. All rights reserved.
//
//  Animated confetti overlay triggered when a review session is
//  completed. Renders colorful circles, rectangles, and stars
//  with randomized physics for a celebratory effect.
//

import SwiftUI

struct ConfettiPiece: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    let color: Color
    let size: CGFloat
    let rotation: Double
    let shape: Int // 0 = circle, 1 = rectangle, 2 = star
    let delay: Double
    let speed: Double
    let wobble: CGFloat
}

struct ConfettiView: View {
    @State private var pieces: [ConfettiPiece] = []
    @State private var animate = false
    let trigger: Bool

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(pieces) { piece in
                    confettiShape(piece)
                        .offset(
                            x: piece.x + (animate ? piece.wobble : 0),
                            y: animate ? geo.size.height + 50 : piece.y
                        )
                        .rotationEffect(.degrees(animate ? piece.rotation + 360 : piece.rotation))
                        .scaleEffect(animate ? 0.5 : 1.0)
                        .opacity(animate ? 0 : 1)
                        .animation(
                            .easeOut(duration: piece.speed)
                            .delay(piece.delay),
                            value: animate
                        )
                }
            }
        }
        .allowsHitTesting(false)
        .onChange(of: trigger) { _, newValue in
            if newValue {
                launchConfetti()
            }
        }
    }

    @ViewBuilder
    private func confettiShape(_ piece: ConfettiPiece) -> some View {
        switch piece.shape {
        case 0:
            Circle()
                .fill(piece.color)
                .frame(width: piece.size, height: piece.size)
        case 1:
            RoundedRectangle(cornerRadius: 2)
                .fill(piece.color)
                .frame(width: piece.size, height: piece.size * 1.6)
        default:
            Image(systemName: "star.fill")
                .font(.system(size: piece.size * 0.8))
                .foregroundStyle(piece.color)
        }
    }

    private func launchConfetti() {
        animate = false
        let colors: [Color] = [.red, .blue, .green, .yellow, .purple, .orange, .pink, .mint, .cyan, .indigo]
        var newPieces: [ConfettiPiece] = []

        for i in 0..<60 {
            newPieces.append(ConfettiPiece(
                x: CGFloat.random(in: -20...UIScreen.main.bounds.width + 20),
                y: CGFloat.random(in: -200...(-20)),
                color: colors[i % colors.count],
                size: CGFloat.random(in: 6...14),
                rotation: Double.random(in: 0...360),
                shape: Int.random(in: 0...2),
                delay: Double.random(in: 0...0.4),
                speed: Double.random(in: 2.0...3.5),
                wobble: CGFloat.random(in: -60...60)
            ))
        }

        pieces = newPieces

        // Kick off animation on next frame
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            animate = true
        }

        // Clean up after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            pieces = []
            animate = false
        }
    }
}
