//
//  ShoeboxApp.swift
//  Shoebox
//
//  Created by Jiro Feingold
//  Copyright (c) 2026 Jiro Feingold. All rights reserved.
//
//  App entry point. Manages the root view hierarchy, gating between
//  onboarding and the main tab interface. Creates and injects the
//  shared PhotoManager, NotificationManager, and NavigationRouter.
//

import SwiftUI
import UserNotifications

@main
struct ShoeboxApp: App {
    @StateObject private var photoManager = PhotoManager()
    @StateObject private var notificationManager = NotificationManager()
    @StateObject private var router = NavigationRouter()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                ContentView()
                    .environmentObject(photoManager)
                    .environmentObject(notificationManager)
                    .environmentObject(router)
                    .onAppear {
                        notificationManager.router = router
                    }
            } else {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                    .environmentObject(photoManager)
                    .environmentObject(notificationManager)
            }
        }
    }
}
