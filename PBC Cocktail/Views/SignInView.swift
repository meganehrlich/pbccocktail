//
//  SignInView.swift
//  PBC Cocktail
//
//  Created by Megan Amanda Ehrlich on 2/13/25.
//

import SwiftUI
import _AuthenticationServices_SwiftUI
import AuthenticationServices

struct SignInView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var firebaseManager: FirebaseManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Sign In")
                .font(.system(size: 24, weight: .medium))
            
            Text("Sign in to save your favorite cocktails")
                .font(.system(size: 16, weight: .light))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            SignInWithAppleButton(
                .signIn,
                onRequest: { _ in },
                onCompletion: { _ in
                    authManager.handleSignInWithApple()
                }
            )
            .frame(height: 44)
            .padding(.horizontal)
            
            if let error = authManager.error {
                Text(error.description)
                    .foregroundColor(.red)
                    .font(.system(size: 14))
                    .padding()
            }
            
            Button("Cancel") {
                dismiss()
            }
            .foregroundColor(.gray)
            .padding(.top)
        }
        .padding()
    }
}
