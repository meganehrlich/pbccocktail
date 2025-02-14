//
//  PBC_CocktailApp.swift
//  PBC Cocktail
//
//  Created by Megan Amanda Ehrlich on 2/1/22.
//

import SwiftUI
import FirebaseCore

@main
struct PBC_CocktailApp: App {
    // Register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // Create a shared instance of AuthenticationManager
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var firebaseManager = FirebaseManager()
    
    var body: some Scene {
        WindowGroup {
            // Conditional view based on authentication state
            switch authManager.authState {
            case .authenticated:
                ContentView()
                    .environmentObject(authManager)
                    .environmentObject(firebaseManager)
            case .authenticating:
                ProgressView("Authenticating...")
            case .unauthenticated:
                SignInView()
                    .environmentObject(authManager)
            }
        }
    }
}
