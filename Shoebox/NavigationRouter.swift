//
//  NavigationRouter.swift
//  Shoebox
//
//  Created by Jiro Feingold
//  Copyright (c) 2026 Jiro Feingold. All rights reserved.
//
//  Lightweight navigation state for deep linking. Used to trigger
//  the review flow when a notification is tapped.
//

import SwiftUI

@MainActor
class NavigationRouter: ObservableObject {
    @Published var shouldStartReview = false
}
