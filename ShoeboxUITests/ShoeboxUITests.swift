//
//  ShoeboxUITests.swift
//  ShoeboxUITests
//
//  Created by Jiro Feingold
//  Copyright (c) 2026 Jiro Feingold. All rights reserved.
//
//  UI tests covering the onboarding flow and main tab navigation.
//  Pass -hasCompletedOnboarding YES/NO via launchArguments to control
//  which root view the app renders.
//

import XCTest

// MARK: - Onboarding

final class OnboardingUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-hasCompletedOnboarding", "NO"]
        app.launch()
    }

    func testWelcomeScreenTitle() {
        XCTAssertTrue(app.staticTexts["Welcome to Kondobox"].waitForExistence(timeout: 3))
    }

    func testNextButtonExistsOnWelcomePage() {
        XCTAssertTrue(app.buttons["Next"].waitForExistence(timeout: 3))
    }

    func testNextButtonAdvancesToPhotosPermissionPage() {
        app.buttons["Next"].tap()
        XCTAssertTrue(app.staticTexts["Access Your Photos"].waitForExistence(timeout: 3))
    }

    func testPhotosPageShowsContinueButton() {
        app.buttons["Next"].tap()
        XCTAssertTrue(app.buttons["Continue"].waitForExistence(timeout: 3))
    }

    func testContinueOnPhotosPageAdvancesToNotificationsPage() {
        app.buttons["Next"].tap()
        app.buttons["Continue"].tap()
        XCTAssertTrue(app.staticTexts["Weekly Reminders"].waitForExistence(timeout: 3))
    }

    func testContinueOnNotificationsPageAdvancesToReadyPage() {
        app.buttons["Next"].tap()
        app.buttons["Continue"].tap()
        app.buttons["Continue"].tap()
        XCTAssertTrue(app.buttons["Get Started"].waitForExistence(timeout: 3))
    }

    func testGetStartedButtonCompletesOnboarding() {
        app.buttons["Next"].tap()
        app.buttons["Continue"].tap()
        app.buttons["Continue"].tap()
        app.buttons["Get Started"].tap()
        // After onboarding the main tab bar should appear
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 5))
    }
}

// MARK: - Main App Navigation

final class MainAppUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-hasCompletedOnboarding", "YES"]
        app.launch()
    }

    func testTabBarExists() {
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 3))
    }

    func testFourTabsArePresent() {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.buttons["Home"].waitForExistence(timeout: 3))
        XCTAssertTrue(tabBar.buttons["Review"].exists)
        XCTAssertTrue(tabBar.buttons["Settings"].exists)
        XCTAssertTrue(tabBar.buttons["Help"].exists)
    }

    func testHomeTabIsSelectedByDefault() {
        XCTAssertTrue(app.staticTexts["Start Review"].waitForExistence(timeout: 3))
    }

    func testHomeTabShowsAppName() {
        XCTAssertTrue(app.staticTexts["Kondobox"].waitForExistence(timeout: 3))
    }

    func testNavigateToReviewTab() {
        app.tabBars.firstMatch.buttons["Review"].tap()
        // Without photos the empty/completion state is shown
        XCTAssertTrue(
            app.staticTexts["All Done!"].waitForExistence(timeout: 3) ||
            app.staticTexts["All Caught Up!"].waitForExistence(timeout: 3) ||
            app.staticTexts["Loading photos..."].waitForExistence(timeout: 3)
        )
    }

    func testNavigateToSettingsTab() {
        app.tabBars.firstMatch.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 3))
    }

    func testNavigateToHelpTab() {
        app.tabBars.firstMatch.buttons["Help"].tap()
        XCTAssertTrue(app.navigationBars["Help"].waitForExistence(timeout: 3))
    }

    func testNavigateBackToHomeTab() {
        app.tabBars.firstMatch.buttons["Settings"].tap()
        app.tabBars.firstMatch.buttons["Home"].tap()
        XCTAssertTrue(app.staticTexts["Start Review"].waitForExistence(timeout: 3))
    }
}
