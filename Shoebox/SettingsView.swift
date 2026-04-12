//
//  SettingsView.swift
//  Shoebox
//
//  Created by Jiro Feingold
//  Copyright (c) 2026 Jiro Feingold. All rights reserved.
//
//  App settings screen. Configures photos per session, album name,
//  notification frequency, photo library access, and provides a
//  gesture reference guide and review history reset.
//

import SwiftUI
import Photos

struct SettingsView: View {
    @EnvironmentObject var photoManager: PhotoManager
    @EnvironmentObject var notificationManager: NotificationManager
    @AppStorage("photosPerSession") private var photosPerSession = 20
    @AppStorage("albumName") private var albumName = "Kondobox"
    @AppStorage("reviewFrequencyDays") private var reviewFrequencyDays = 7
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @State private var showResetConfirmation = false

    private var photoAccessLabel: String {
        switch photoManager.authorizationStatus {
        case .authorized: return String(localized: "All Photos")
        case .limited: return String(localized: "Selected Photos")
        case .denied, .restricted: return String(localized: "Denied")
        default: return String(localized: "Not Set")
        }
    }

    private var frequencyLabel: String {
        switch reviewFrequencyDays {
        case 1: return String(localized: "Every day")
        case 7: return String(localized: "Once a week")
        default: return String(localized: "Every \(reviewFrequencyDays) days")
        }
    }

    var body: some View {
        List {
            Section {
                HStack {
                    Label("Photos per session", systemImage: "photo.stack")
                    Spacer()
                    Picker("", selection: $photosPerSession) {
                        Text("5").tag(5)
                        Text("10").tag(10)
                        Text("20").tag(20)
                        Text("50").tag(50)
                        Text("Unlimited").tag(0)
                    }
                    .pickerStyle(.menu)
                    .tint(.purple)
                }

                HStack {
                    Label("Album name", systemImage: "rectangle.stack")
                    Spacer()
                    TextField("Album name", text: $albumName)
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: 180)
                }
            } header: {
                Text("Review")
            }

            Section {
                HStack {
                    Label("Reminder", systemImage: "bell.badge.fill")
                    Spacer()
                    if notificationManager.isAuthorized {
                        Picker("", selection: $reviewFrequencyDays) {
                            Text("Every day").tag(1)
                            Text("Every 2 days").tag(2)
                            Text("Every 3 days").tag(3)
                            Text("Every 4 days").tag(4)
                            Text("Every 5 days").tag(5)
                            Text("Every 6 days").tag(6)
                            Text("Once a week").tag(7)
                        }
                        .pickerStyle(.menu)
                        .tint(.purple)
                        .onChange(of: reviewFrequencyDays) { _, newValue in
                            notificationManager.scheduleNotification(everyDays: newValue)
                        }
                    } else {
                        Button("Enable") {
                            Task {
                                await notificationManager.requestAuthorization()
                            }
                        }
                        .tint(.purple)
                    }
                }
            } header: {
                Text("Notifications")
            } footer: {
                if notificationManager.isAuthorized {
                    Text("You'll receive a reminder at 10 AM based on your chosen frequency.")
                } else {
                    Text("Enable notifications to get reminded to review your photos.")
                }
            }

            Section {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack {
                        Label("Photo Access", systemImage: "photo.on.rectangle.angled")
                        Spacer()
                        Text(photoAccessLabel)
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                }
                .tint(.primary)
            } header: {
                Text("Privacy")
            } footer: {
                if photoManager.authorizationStatus == .limited {
                    Text("You've given Kondobox access to selected photos only. Tap to change which photos are accessible.")
                } else {
                    Text("Manage photo library access in system Settings.")
                }
            }

            Section {
                HStack {
                    Label {
                        Text("Swipe Right")
                    } icon: {
                        Image(systemName: "arrow.right")
                            .foregroundStyle(.blue)
                    }
                    Spacer()
                    Text("Save to album")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Label {
                        Text("Swipe Left")
                    } icon: {
                        Image(systemName: "arrow.left")
                            .foregroundStyle(.green)
                    }
                    Spacer()
                    Text("Keep photo")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Label {
                        Text("Swipe Up")
                    } icon: {
                        Image(systemName: "arrow.up")
                            .foregroundStyle(.red)
                    }
                    Spacer()
                    Text("Delete photo")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Label {
                        Text("Swipe Down")
                    } icon: {
                        Image(systemName: "arrow.down")
                            .foregroundStyle(.yellow)
                    }
                    Spacer()
                    Text("Add to Favorites")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Gestures")
            }

            Section {
                Button("Reset Review History") {
                    showResetConfirmation = true
                }
                .foregroundStyle(.purple)
                .confirmationDialog(
                    "Reset Review History?",
                    isPresented: $showResetConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Reset", role: .destructive) {
                        photoManager.resetReviewHistory()
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This will let you see all previously reviewed photos again. This action cannot be undone.")
                }

                Button("Reset Onboarding") {
                    hasCompletedOnboarding = false
                }
                .foregroundStyle(.red)
            } header: {
                Text("Data")
            } footer: {
                Text("\(photoManager.reviewedCount) photos reviewed so far.\nResetting lets you see previously reviewed photos again.")
                    .padding(.bottom, 8)

                Text("Kondobox v1.2")
                    .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Settings")
    }
}
