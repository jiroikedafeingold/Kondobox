//
//  ReviewView.swift
//  Shoebox
//
//  Created by Jiro Feingold
//  Copyright (c) 2026 Jiro Feingold. All rights reserved.
//
//  Main review screen. Presents a stack of photo cards for swiping,
//  tracks session statistics, shows a progress bar, and displays a
//  celebration view with confetti when a session is completed.
//

import SwiftUI

struct ReviewView: View {
    @EnvironmentObject var photoManager: PhotoManager
    @AppStorage("photosPerSession") private var photosPerSession = 20
    @State private var reviewComplete = false
    @State private var showConfetti = false
    @State private var celebrationScale: CGFloat = 0.3
    @State private var celebrationOpacity: Double = 0
    @State private var stats = ReviewStats()
    @State private var allPhotosReviewed = false
    @State private var history: [(item: PhotoItem, direction: PhotoCardView.SwipeDirection)] = []
    @State private var shareImage: UIImage?
    @State private var showShareSheet = false

    struct ReviewStats {
        var kept = 0
        var saved = 0
        var deleted = 0
        var favorited = 0

        var total: Int { kept + saved + deleted + favorited }
    }

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(.systemBackground), Color(.secondarySystemBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            if photoManager.isLoading {
                loadingView
            } else if allPhotosReviewed {
                allReviewedView
            } else if reviewComplete || photoManager.photos.isEmpty {
                completionView
            } else {
                VStack(spacing: 0) {
                    headerView
                    cardStackView
                    swipeHintsView
                }
            }

            // Confetti overlay
            ConfettiView(trigger: showConfetti)
                .ignoresSafeArea()
        }
        .onChange(of: photoManager.photos.isEmpty) {
            if !photoManager.photos.isEmpty && (reviewComplete || allPhotosReviewed) {
                reviewComplete = false
                allPhotosReviewed = false
                showConfetti = false
                celebrationScale = 0.3
                celebrationOpacity = 0
                stats = ReviewStats()
                history = []
            }
        }
    }

    // MARK: - Subviews

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading photos...")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
    }

    private var headerView: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Review")
                    .font(.largeTitle.bold())
                Spacer()
                Text("\(photoManager.photos.count) left")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 24)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemGray5))
                        .frame(height: 4)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, geo.size.width * progressFraction), height: 4)
                        .animation(.easeInOut, value: stats.total)
                }
            }
            .frame(height: 4)
            .padding(.horizontal, 24)
        }
        .padding(.top, 8)
        .padding(.bottom, 16)
    }

    private var progressFraction: CGFloat {
        let total = stats.total + photoManager.photos.count
        guard total > 0 else { return 0 }
        return CGFloat(stats.total) / CGFloat(total)
    }

    private var cardStackView: some View {
        ZStack {
            ForEach(Array(photoManager.photos.prefix(3).enumerated().reversed()), id: \.element.id) { index, item in
                PhotoCardView(item: item) { direction in
                    handleSwipe(direction: direction, item: item)
                }
                .padding(.horizontal, 24 + CGFloat(index) * 8)
                .scaleEffect(1 - CGFloat(index) * 0.04)
                .offset(y: CGFloat(index) * 8)
                .allowsHitTesting(index == 0)
            }
        }
        .padding(.vertical, 8)
        .frame(maxHeight: .infinity)
    }

    private var swipeHintsView: some View {
        HStack(spacing: 16) {
            backButton
            actionButton(icon: "hand.point.left.fill", text: "Keep", color: .green, direction: .left)
            actionButton(icon: "hand.point.up.fill", text: "Delete", color: .red, direction: .up)
            actionButton(icon: "hand.point.down.fill", text: "Fave", color: .yellow, direction: .down)
            actionButton(icon: "hand.draw.fill", text: "Save", color: .blue, direction: .right)
            shareButton
        }
        .padding(.bottom, 24)
        .padding(.top, 12)
        .sheet(isPresented: $showShareSheet) {
            if let shareImage {
                ShareSheet(items: [shareImage])
            }
        }
    }

    private var backButton: some View {
        Button {
            goBack()
        } label: {
            VStack(spacing: 6) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.purple)
                    .frame(width: 44, height: 44)
                    .background(Color.purple.opacity(0.12))
                    .clipShape(Circle())
                Text("Back")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .disabled(history.isEmpty)
        .opacity(history.isEmpty ? 0.4 : 1.0)
    }

    private var shareButton: some View {
        Button {
            guard let item = photoManager.photos.first else { return }
            let size = CGSize(width: 1600, height: 2400)
            photoManager.loadImage(for: item.asset, targetSize: size) { image in
                if let image {
                    shareImage = image
                    showShareSheet = true
                }
            }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.orange)
                    .frame(width: 44, height: 44)
                    .background(Color.orange.opacity(0.12))
                    .clipShape(Circle())
                Text("Share")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .disabled(photoManager.photos.isEmpty)
    }

    private func actionButton(icon: String, text: LocalizedStringKey, color: Color, direction: PhotoCardView.SwipeDirection) -> some View {
        Button {
            if let item = photoManager.photos.first {
                handleSwipe(direction: direction, item: item)
            }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(width: 44, height: 44)
                    .background(color.opacity(0.12))
                    .clipShape(Circle())
                Text(text)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .disabled(photoManager.photos.isEmpty)
    }

    private var completionView: some View {
        VStack(spacing: 20) {
            Spacer()

            // Animated trophy / party popper
            ZStack {
                // Radiating rings
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.purple.opacity(0.3), .blue.opacity(0.1)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 2
                        )
                        .frame(width: CGFloat(120 + i * 50), height: CGFloat(120 + i * 50))
                        .scaleEffect(celebrationScale)
                        .opacity(celebrationOpacity * (1.0 - Double(i) * 0.25))
                }

                // Main icon
                VStack(spacing: 8) {
                    Text("🎉")
                        .font(.system(size: 80))

                    Text("All Done!")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                }
                .scaleEffect(celebrationScale)
                .opacity(celebrationOpacity)
            }

            Text("You reviewed \(stats.total) photos this session")
                .font(.body)
                .foregroundStyle(.secondary)
                .opacity(celebrationOpacity)

            // Stats row
            HStack(spacing: 16) {
                statBadge(count: stats.kept, label: "Kept", color: .green, icon: "hand.point.left.fill")
                statBadge(count: stats.saved, label: "Saved", color: .blue, icon: "hand.draw.fill")
                statBadge(count: stats.favorited, label: "Faved", color: .yellow, icon: "hand.point.down.fill")
                statBadge(count: stats.deleted, label: "Deleted", color: .red, icon: "hand.point.up.fill")
            }
            .padding(.top, 4)
            .opacity(celebrationOpacity)

            // Motivational message
            Text(motivationalMessage)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.purple)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .opacity(celebrationOpacity)

            Spacer()

            Button {
                stats = ReviewStats()
                history = []
                reviewComplete = false
                celebrationScale = 0.3
                celebrationOpacity = 0
                photoManager.loadRandomPhotos(count: photosPerSession)
                if photoManager.photos.isEmpty {
                    allPhotosReviewed = true
                }
            } label: {
                Text("Review More")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 32)
            .opacity(celebrationOpacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                celebrationScale = 1.0
                celebrationOpacity = 1.0
            }
        }
    }

    private var allReviewedView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 72))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("All Caught Up!")
                .font(.system(size: 34, weight: .bold, design: .rounded))

            Text("You've reviewed every photo in your library.\nReset your review history in Settings to start fresh.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
        }
    }

    private var motivationalMessage: String {
        if stats.deleted > stats.kept + stats.favorited {
            return String(localized: "Decluttering champion! Your library thanks you.")
        } else if stats.favorited > 0 {
            return String(localized: "Great taste! Those favorites are keepers.")
        } else if stats.saved > stats.kept {
            return String(localized: "Lots of great memories saved!")
        } else {
            return String(localized: "Nice work keeping your library tidy!")
        }
    }

    private func statBadge(count: Int, label: LocalizedStringKey, color: Color, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(color)
            Text("\(count)")
                .font(.title3.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(width: 68, height: 80)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Actions

    private func handleSwipe(direction: PhotoCardView.SwipeDirection, item: PhotoItem) {
        switch direction {
        case .right:
            photoManager.photos.removeAll { $0.id == item.id }
            Task {
                let saved = await photoManager.addToAlbum(item)
                if saved {
                    stats.saved += 1
                    history.append((item: item, direction: direction))
                } else {
                    photoManager.photos.insert(item, at: 0)
                }
                checkCompletion()
            }
        case .left:
            photoManager.removeFromQueue(item)
            stats.kept += 1
            history.append((item: item, direction: direction))
            checkCompletion()
        case .up:
            photoManager.photos.removeAll { $0.id == item.id }
            Task {
                let deleted = await photoManager.deletePhoto(item)
                if deleted {
                    stats.deleted += 1
                    history.append((item: item, direction: direction))
                } else {
                    photoManager.photos.insert(item, at: 0)
                }
                checkCompletion()
            }
        case .down:
            photoManager.photos.removeAll { $0.id == item.id }
            Task {
                let favorited = await photoManager.favoritePhoto(item)
                if favorited {
                    stats.favorited += 1
                    history.append((item: item, direction: direction))
                } else {
                    photoManager.photos.insert(item, at: 0)
                }
                checkCompletion()
            }
        }
    }

    private func goBack() {
        guard let last = history.popLast() else { return }

        // Undo the stat
        switch last.direction {
        case .right: stats.saved -= 1
        case .left: stats.kept -= 1
        case .up: stats.deleted -= 1
        case .down: stats.favorited -= 1
        }

        // Unmark as reviewed so the photo is eligible again
        photoManager.unmarkReviewed(last.item.id)

        // Re-insert at the front of the queue
        photoManager.photos.insert(last.item, at: 0)

        // Reset completion state if we were on the done screen
        if reviewComplete {
            reviewComplete = false
            showConfetti = false
            celebrationScale = 0.3
            celebrationOpacity = 0
        }
    }

    private func checkCompletion() {
        if photoManager.photos.isEmpty {
            photoManager.markReviewCompleted()
            withAnimation(.easeInOut(duration: 0.5)) {
                reviewComplete = true
            }
            // Trigger confetti slightly after the view transition
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showConfetti = true
            }
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
