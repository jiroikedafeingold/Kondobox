//
//  NotificationManager.swift
//  Shoebox
//
//  Created by Jiro Feingold
//  Copyright (c) 2026 Jiro Feingold. All rights reserved.
//
//  Manages local notification scheduling and permissions. Handles
//  configurable review reminders, notification tap deep linking,
//  and foreground suppression when no new photos are available.
//

import Foundation
import UserNotifications
import Photos

@MainActor
class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    @Published var isAuthorized = false
    var router: NavigationRouter?

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func requestAuthorization() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            isAuthorized = granted
            if granted {
                let frequency = UserDefaults.standard.integer(forKey: "reviewFrequencyDays")
                scheduleNotification(everyDays: frequency > 0 ? frequency : 7)
            }
        } catch {
            print("Notification authorization failed: \(error)")
        }
    }

    /// Schedule review reminder notifications.
    func scheduleNotification(everyDays days: Int) {
        let center = UNUserNotificationCenter.current()
        // Remove all previous review notifications
        center.removePendingNotificationRequests(withIdentifiers:
            (0..<7).map { "review-day-\($0)" } + ["weekly-review"]
        )

        guard days >= 1 else { return }

        let content = UNMutableNotificationContent()
        content.title = String(localized: "Time to tidy up!")
        content.body = String(localized: "You have photos waiting for review. Swipe through some photos to keep your library clean.")
        content.sound = .default

        if days == 1 {
            // Daily at 10 AM
            var dateComponents = DateComponents()
            dateComponents.hour = 10
            dateComponents.minute = 0
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(identifier: "review-day-0", content: content, trigger: trigger)
            center.add(request)
        } else {
            // Schedule for specific weekdays to approximate every N days
            let weekdays = pickWeekdays(everyDays: days)
            for (i, weekday) in weekdays.enumerated() {
                var dateComponents = DateComponents()
                dateComponents.weekday = weekday  // 1 = Sunday, 7 = Saturday
                dateComponents.hour = 10
                dateComponents.minute = 0
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                let request = UNNotificationRequest(identifier: "review-day-\(i)", content: content, trigger: trigger)
                center.add(request)
            }
        }
    }

    /// Returns weekday numbers (1-7) spaced as evenly as possible for a given frequency.
    private func pickWeekdays(everyDays days: Int) -> [Int] {
        switch days {
        case 1: return [1, 2, 3, 4, 5, 6, 7]  // every day
        case 2: return [1, 3, 5, 7]             // ~every 2 days
        case 3: return [1, 4, 6]                // ~every 2-3 days
        case 4: return [1, 5]                   // ~every 3-4 days
        case 5: return [1, 5]                   // ~every 3-4 days
        case 6: return [1]                      // once a week
        case 7: return [1]                      // once a week (Sunday)
        default: return [1]
        }
    }

    func checkAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    // MARK: - UNUserNotificationCenterDelegate

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let id = response.notification.request.identifier
        if id.hasPrefix("review-") {
            Task { @MainActor in
                router?.shouldStartReview = true
            }
        }
        completionHandler()
    }

    // Show notification in foreground only if there are new photos to review
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let id = notification.request.identifier
        if id.hasPrefix("review-") && !PhotoManager.hasNewPhotosSinceLastReview() {
            // Suppress — no new photos since last review
            completionHandler([])
            return
        }
        completionHandler([.banner, .sound])
    }
}
