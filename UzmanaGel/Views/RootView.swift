//
//  RootView.swift
//  UzmanaGel
//
//  Created by Abdullah B on 2.02.2026.
//

import SwiftUI

struct RootView: View {

    @EnvironmentObject var session: SessionViewModel
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        Group {
            if !hasSeenOnboarding {
                OnboardingView()
            } else if session.isAuthenticated {
                Homepage()
            } else {
                NavigationStack {
                    LoginPage()
                }
            }
        }
    }
}
