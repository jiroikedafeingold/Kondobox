//
//  ContentView.swift
//  Shoebox
//
//  Created by Jiro Feingold
//  Copyright (c) 2026 Jiro Feingold. All rights reserved.
//
//  Root tab view with Home, Review, and Settings tabs. Also contains
//  the HomeView with the hero section, start review button, and
//  gesture instruction guide.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var photoManager: PhotoManager
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var router: NavigationRouter
    @AppStorage("photosPerSession") private var photosPerSession = 20
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView(selectedTab: $selectedTab)
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)

            NavigationStack {
                ReviewView()
            }
            .tabItem {
                Label("Review", systemImage: "rectangle.stack.fill")
            }
            .tag(1)

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
            .tag(2)

            NavigationStack {
                HelpView()
            }
            .tabItem {
                Label("Help", systemImage: "questionmark.circle.fill")
            }
            .tag(3)
        }
        .tint(.purple)
        .onAppear {
            Task {
                await notificationManager.checkAuthorizationStatus()
            }
        }
        .onChange(of: router.shouldStartReview) { _, shouldStart in
            if shouldStart {
                router.shouldStartReview = false
                photoManager.loadRandomPhotos(count: photosPerSession)
                selectedTab = 1
            }
        }
    }
}

// MARK: - Home View

struct HomeView: View {
    @EnvironmentObject var photoManager: PhotoManager
    @AppStorage("photosPerSession") private var photosPerSession = 20
    @AppStorage("albumName") private var albumName = "Kondobox"
    @Binding var selectedTab: Int

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Hero section
                VStack(spacing: 16) {
                    Image(systemName: "photo.stack")
                        .font(.system(size: 64))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .padding(.top, 40)

                    Text("Kondobox")
                        .font(.system(size: 36, weight: .bold, design: .rounded))

                    Text("Declutter your photo library,\none swipe at a time")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                // Start review card
                Button {
                    photoManager.loadRandomPhotos(count: photosPerSession)
                    selectedTab = 1
                } label: {
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Start Review")
                                .font(.title3.bold())
                                .foregroundStyle(.white)
                            Text(photosPerSession == 0 ? "Swipe through all your photos" : "Swipe through \(photosPerSession) random photos")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        Spacer()
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.white)
                    }
                    .padding(24)
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                .padding(.horizontal, 20)

                // How it works section
                VStack(alignment: .leading, spacing: 20) {
                    Text("How it works")
                        .font(.title2.bold())
                        .padding(.horizontal, 20)

                    VStack(spacing: 16) {
                        instructionRow(
                            icon: "hand.draw.fill",
                            iconColor: .blue,
                            title: "Swipe Right",
                            description: "Save to your \(albumName) album"
                        )
                        instructionRow(
                            icon: "hand.point.left.fill",
                            iconColor: .green,
                            title: "Swipe Left",
                            description: "Keep and move on"
                        )
                        instructionRow(
                            icon: "hand.point.up.fill",
                            iconColor: .red,
                            title: "Swipe Up",
                            description: "Delete from your library"
                        )
                        instructionRow(
                            icon: "hand.point.down.fill",
                            iconColor: .yellow,
                            title: "Swipe Down",
                            description: "Add to your Favorites"
                        )
                    }
                    .padding(.horizontal, 20)
                }

                Spacer(minLength: 40)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func instructionRow(icon: String, iconColor: Color, title: LocalizedStringKey, description: LocalizedStringKey) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: 48, height: 48)
                .background(iconColor.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Help View

struct HelpView: View {
    @AppStorage("albumName") private var albumName = "Kondobox"

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Kondobox helps you declutter your photo library by showing you random photos to sort through. Swipe or tap the buttons to decide what happens with each photo. Save a photo by swiping right which can allow you to make a list of photos to print, send to a family member or just have in an album.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("About Kondobox")
            }

            Section {
                helpRow(
                    icon: "hand.draw.fill",
                    iconColor: .blue,
                    title: "Swipe Right — Save",
                    description: "Saves the photo to your \"\(albumName)\" album. The photo stays in your library and is also added to the album."
                )
                helpRow(
                    icon: "hand.point.left.fill",
                    iconColor: .green,
                    title: "Swipe Left — Keep",
                    description: "Keeps the photo in your library as-is and moves to the next one. It won't be shown again in future reviews."
                )
                helpRow(
                    icon: "hand.point.up.fill",
                    iconColor: .red,
                    title: "Swipe Up — Delete",
                    description: "Deletes the photo from your library. Your device will ask you to confirm before deleting."
                )
                helpRow(
                    icon: "hand.point.down.fill",
                    iconColor: .yellow,
                    title: "Swipe Down — Favorite",
                    description: "Marks the photo as a Favorite in your library. Favorited photos won't appear in future reviews."
                )
            } header: {
                Text("Gestures")
            } footer: {
                Text("You can also tap the action buttons below the photo instead of swiping.")
            }

            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Label {
                        Text("Deleted photos are moved to the **Recently Deleted** folder in the Photos app, where they stay for 30 days before being permanently removed.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                    }

                    Button {
                        if let url = URL(string: "photos-redirect://") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("Open Photos App", systemImage: "photo.fill")
                    }
                    .tint(.purple)
                }
            } header: {
                Text("Accidentally Deleted a Photo?")
            } footer: {
                Text("Open the Photos app, go to Albums, and scroll to the bottom to find the Recently Deleted folder.")
            }

            Section {
                VStack(alignment: .leading, spacing: 12) {
                    tipRow(
                        icon: "arrow.clockwise",
                        text: "Once you've reviewed all your photos, you can reset your review history in Settings to start fresh."
                    )
                    tipRow(
                        icon: "bell.badge.fill",
                        text: "Set up reminders in Settings to get notified when it's time to review your photos."
                    )
                    tipRow(
                        icon: "star.fill",
                        text: "Photos already in your Favorites are automatically skipped during reviews."
                    )
                }
            } header: {
                Text("Tips")
            }
        }
        .navigationTitle("Help")
    }

    private func helpRow(icon: String, iconColor: Color, title: LocalizedStringKey, description: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(iconColor)
                    .frame(width: 32, height: 32)
                    .background(iconColor.opacity(0.12))
                    .clipShape(Circle())
                Text(title)
                    .font(.subheadline.bold())
            }
            Text(description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func tipRow(icon: String, text: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(.purple)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}
