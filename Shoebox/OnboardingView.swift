//
//  OnboardingView.swift
//  Shoebox
//
//  Created by Jiro Feingold
//  Copyright (c) 2026 Jiro Feingold. All rights reserved.
//
//  First-launch onboarding flow. Walks the user through granting
//  photo library and notification permissions, then summarizes
//  the swipe gestures before getting started.
//

import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @EnvironmentObject var photoManager: PhotoManager
    @EnvironmentObject var notificationManager: NotificationManager
    @State private var currentPage = 0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(.systemBackground), Color(.secondarySystemBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack {
                TabView(selection: $currentPage) {
                    welcomePage.tag(0)
                    photosPermissionPage.tag(1)
                    notificationsPermissionPage.tag(2)
                    readyPage.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
            }
        }
    }

    // MARK: - Pages

    private var welcomePage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "photo.stack")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("Welcome to Shoebox")
                .font(.system(size: 32, weight: .bold, design: .rounded))

            Text("Declutter your photo library with simple swipe gestures. Review 10 photos each week and keep your memories organized.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            nextButton(page: 0)
        }
        .padding()
    }

    private var photosPermissionPage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 72))
                .foregroundStyle(.blue)

            Text("Access Your Photos")
                .font(.title.bold())

            Text("Shoebox needs access to your photo library to show you images for review and to manage albums.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if photoManager.isAuthorized {
                Label("Photos Access Granted", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .foregroundStyle(.green)
                    .padding()
            }

            Spacer()

            if !photoManager.isAuthorized {
                Button {
                    Task {
                        await photoManager.requestAuthorization()
                    }
                } label: {
                    Text("Allow Photo Access")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 32)
            }

            nextButton(page: 1)
        }
        .padding()
    }

    private var notificationsPermissionPage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "bell.badge.fill")
                .font(.system(size: 72))
                .foregroundStyle(.orange)

            Text("Weekly Reminders")
                .font(.title.bold())

            Text("Get a gentle reminder each week to review your photos. You can change this later in Settings.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if notificationManager.isAuthorized {
                Label("Notifications Enabled", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .foregroundStyle(.green)
                    .padding()
            }

            Spacer()

            if !notificationManager.isAuthorized {
                Button {
                    Task {
                        await notificationManager.requestAuthorization()
                    }
                } label: {
                    Text("Enable Notifications")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.orange)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 32)
            }

            nextButton(page: 2)
        }
        .padding()
    }

    private var readyPage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "sparkles")
                .font(.system(size: 72))
                .foregroundStyle(.purple)

            Text("You're All Set!")
                .font(.title.bold())

            VStack(alignment: .leading, spacing: 16) {
                featureRow(icon: "hand.draw.fill", color: .blue, text: "Swipe right to save to album")
                featureRow(icon: "hand.point.left.fill", color: .green, text: "Swipe left to keep")
                featureRow(icon: "hand.point.up.fill", color: .red, text: "Swipe up to delete")
                featureRow(icon: "hand.point.down.fill", color: .yellow, text: "Swipe down to favorite")
            }
            .padding(.horizontal, 32)

            Spacer()

            Button {
                withAnimation {
                    hasCompletedOnboarding = true
                }
            } label: {
                Text("Get Started")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 20)
        }
        .padding()
    }

    // MARK: - Helpers

    private func nextButton(page: Int) -> some View {
        Button {
            withAnimation {
                currentPage = page + 1
            }
        } label: {
            Text("Next")
                .font(.headline)
                .foregroundStyle(.purple)
                .padding()
        }
        .padding(.bottom, 20)
    }

    private func featureRow(icon: String, color: Color, text: LocalizedStringKey) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.12))
                .clipShape(Circle())
            Text(text)
                .font(.body.weight(.medium))
        }
    }
}
