//
//  PhotoCardView.swift
//  Shoebox
//
//  Created by Jiro Feingold
//  Copyright (c) 2026 Jiro Feingold. All rights reserved.
//
//  Swipeable photo card with four-direction gesture recognition.
//  Displays the photo with metadata overlay (date, time, location)
//  and animated action indicators for save, keep, delete, and favorite.
//

import SwiftUI
import Photos
import CoreLocation

struct PhotoCardView: View {
    let item: PhotoItem
    let onSwipe: (SwipeDirection) -> Void

    @State private var image: UIImage?
    @State private var offset: CGSize = .zero
    @State private var opacity: Double = 1
    @State private var locationName: String?
    @EnvironmentObject var photoManager: PhotoManager

    private let swipeThreshold: CGFloat = 100

    enum SwipeDirection {
        case left   // keep (skip)
        case right  // save to album
        case up     // delete
        case down   // favorite
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Card background
                Color.black

                // Photo
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(
                            width: geometry.size.width,
                            height: geometry.size.height
                        )
                } else {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .overlay {
                            ProgressView()
                                .scaleEffect(1.2)
                        }
                }

                // Photo metadata at bottom
                VStack {
                    Spacer()
                    photoMetadataView
                }

                // Overlay indicators
                overlayIndicator
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
            .offset(offset)
            .rotationEffect(.degrees(Double(offset.width / 30)))
            .opacity(opacity)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        offset = gesture.translation
                    }
                    .onEnded { gesture in
                        handleSwipeEnd(gesture: gesture)
                    }
            )
            .animation(.interactiveSpring(response: 0.4, dampingFraction: 0.7), value: offset)
        }
        .onAppear {
            loadImage()
            reverseGeocode()
        }
    }

    @ViewBuilder
    private var overlayIndicator: some View {
        ZStack {
            // Right swipe - Save
            if offset.width > 30 {
                VStack {
                    Image(systemName: "square.and.arrow.down.fill")
                        .font(.system(size: 48, weight: .bold))
                    Text("SAVE")
                        .font(.system(size: 24, weight: .heavy))
                }
                .foregroundStyle(.blue)
                .padding(20)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .opacity(min(Double(offset.width) / 100, 1))
            }

            // Left swipe - Keep
            if offset.width < -30 {
                VStack {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 48, weight: .bold))
                    Text("KEEP")
                        .font(.system(size: 24, weight: .heavy))
                }
                .foregroundStyle(.green)
                .padding(20)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .opacity(min(Double(-offset.width) / 100, 1))
            }

            // Up swipe - Delete
            if offset.height < -30 && abs(offset.height) > abs(offset.width) {
                VStack {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 48, weight: .bold))
                    Text("DELETE")
                        .font(.system(size: 24, weight: .heavy))
                }
                .foregroundStyle(.red)
                .padding(20)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .opacity(min(Double(-offset.height) / 100, 1))
            }

            // Down swipe - Favorite
            if offset.height > 30 && abs(offset.height) > abs(offset.width) {
                VStack {
                    Image(systemName: "star.fill")
                        .font(.system(size: 48, weight: .bold))
                    Text("FAVORITE")
                        .font(.system(size: 24, weight: .heavy))
                }
                .foregroundStyle(.yellow)
                .padding(20)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .opacity(min(Double(offset.height) / 100, 1))
            }
        }
    }

    private func handleSwipeEnd(gesture: DragGesture.Value) {
        let horizontalAmount = gesture.translation.width
        let verticalAmount = gesture.translation.height
        let isVertical = abs(verticalAmount) > abs(horizontalAmount)

        // Vertical swipes take priority when the gesture is more vertical
        if isVertical && verticalAmount < -swipeThreshold {
            // Up - delete
            withAnimation(.easeOut(duration: 0.3)) {
                offset = CGSize(width: 0, height: -800)
                opacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                onSwipe(.up)
            }
        } else if isVertical && verticalAmount > swipeThreshold {
            // Down - favorite
            withAnimation(.easeOut(duration: 0.3)) {
                offset = CGSize(width: 0, height: 800)
                opacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                onSwipe(.down)
            }
        } else if horizontalAmount > swipeThreshold {
            withAnimation(.easeOut(duration: 0.3)) {
                offset = CGSize(width: 600, height: 0)
                opacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                onSwipe(.right)
            }
        } else if horizontalAmount < -swipeThreshold {
            withAnimation(.easeOut(duration: 0.3)) {
                offset = CGSize(width: -600, height: 0)
                opacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                onSwipe(.left)
            }
        } else {
            // Snap back
            withAnimation(.interactiveSpring(response: 0.4, dampingFraction: 0.7)) {
                offset = .zero
            }
        }
    }

    private var photoMetadataView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                if let date = item.asset.creationDate {
                    Text(date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.white)
                }
                if let locationName {
                    Text(locationName)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            LinearGradient(
                colors: [.clear, .black.opacity(0.5)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private func reverseGeocode() {
        guard let location = item.asset.location else { return }
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, _ in
            if let p = placemarks?.first {
                let parts = [p.locality, p.administrativeArea, p.country].compactMap { $0 }
                if !parts.isEmpty {
                    DispatchQueue.main.async {
                        self.locationName = parts.joined(separator: ", ")
                    }
                }
            }
        }
    }

    private func loadImage() {
        let size = CGSize(width: 800, height: 1200)
        photoManager.loadImage(for: item.asset, targetSize: size) { loadedImage in
            self.image = loadedImage
        }
    }
}
