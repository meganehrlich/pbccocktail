//
//  AuthenticationManager.swift
//  PBC Cocktail
//
//  Created by Megan Amanda Ehrlich on 2/13/25.
//
// AuthenticationManager.swift

import SwiftUI
import AuthenticationServices
import FirebaseAuth
import FirebaseFirestore
import CryptoKit

class AuthenticationManager: NSObject, ObservableObject {
    @Published var authState: AuthenticationState = .unauthenticated
    @Published var currentUser: User?
    @Published var error: UserError?
    
    private let db = Firestore.firestore()
    private var currentNonce: String?
    
    // MARK: - Sign in with Apple
    func handleSignInWithApple() {
        let nonce = randomNonceString()
        currentNonce = nonce
        
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.email]
        request.nonce = sha256(nonce)
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    // MARK: - Nonce Generation
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }
        
        return String(nonce)
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
    
    // MARK: - Sign Out
    func signOut() {
        do {
            try Auth.auth().signOut()
            self.authState = .unauthenticated
            self.currentUser = nil
        } catch {
            self.error = .signOutError
        }
    }
    
    // MARK: - User Data Management
    private func createOrUpdateUserRecord(withAppleID appleID: String, email: String?) {
        guard let firebaseUser = Auth.auth().currentUser else { return }
        
        let userData: [String: Any] = [
            "id": firebaseUser.uid,
            "email": email ?? "",
            "appleIdentifier": appleID,
            "savedCocktails": []
        ]
        
        db.collection("users").document(firebaseUser.uid).setData(userData, merge: true) { [weak self] error in
            if let error = error {
                print("Error updating user record: \(error)")
                self?.error = .signInError
            }
        }
    }
}

// MARK: - ASAuthorizationControllerDelegate
extension AuthenticationManager: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8),
              let nonce = currentNonce else {
            self.error = .appleSignInError
            return
        }
        
        // Create Firebase credential with nonce
        let credential = OAuthProvider.credential(
            withProviderID: "apple.com",
            idToken: idTokenString,
            rawNonce: nonce // Now properly passing the nonce
        )
        
        // Sign in to Firebase
        self.authState = .authenticating
        
        Auth.auth().signIn(with: credential) { [weak self] (result, error) in
            if let error = error {
                self?.error = .signInError
                self?.authState = .unauthenticated
                print("Firebase auth error: \(error)")
                return
            }
            
            guard let user = result?.user else {
                self?.error = .signInError
                self?.authState = .unauthenticated
                return
            }
            
            // Create or update user record
            self?.createOrUpdateUserRecord(
                withAppleID: appleIDCredential.user,
                email: appleIDCredential.email
            )
            
            self?.authState = .authenticated
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Sign in with Apple error: \(error)")
        self.error = .appleSignInError
        self.authState = .unauthenticated
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding
extension AuthenticationManager: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        return scene?.windows.first ?? UIWindow()
    }
}
