//
//  FirebaseManager.swift
//  PBCCocktail
//
//  Created by Megan Amanda Ehrlich on 2/13/25.
//

import SwiftUI


import FirebaseFirestore
import FirebaseAuth

class FirebaseManager: ObservableObject {
    private let db = Firestore.firestore()
    @Published var savedCocktails: [SavedCocktail] = []
    @Published var error: Error?
    private var listener: ListenerRegistration?
    
    init() {
        startListeningForChanges()
    }
    
    deinit {
        listener?.remove()
    }
    
    // MARK: - Real-time Updates
    func startListeningForChanges() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Remove existing listener if any
        listener?.remove()
        
        listener = db.collection("users").document(userId).collection("savedCocktails")
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error listening for cocktail updates: \(error)")
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    print("No documents found")
                    return
                }
                
                self.savedCocktails = documents.compactMap { document -> SavedCocktail? in
                    try? document.data(as: SavedCocktail.self)
                }
                
                print("Updated savedCocktails count: \(self.savedCocktails.count)")
            }
    }
    
    // MARK: - Save Cocktail
    func saveCocktail(_ cocktail: Cocktail) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw UserError.saveCocktailError
        }
        
        // Double-check for duplicates right before saving
        let normalizedNewDrink = cocktail.strDrink.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let isDuplicate = savedCocktails.contains { savedCocktail in
            let normalizedSavedDrink = savedCocktail.cocktail.strDrink.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            return normalizedNewDrink == normalizedSavedDrink
        }
        
        if isDuplicate {
            print("Duplicate caught in FirebaseManager - not saving")
            return
        }
        
        let savedCocktail = SavedCocktail(cocktail: cocktail)
        
        try await db.collection("users").document(userId)
            .collection("savedCocktails").document(savedCocktail.id)
            .setData(from: savedCocktail)
    }
    
    // MARK: - Load Saved Cocktails
    func loadSavedCocktails() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        do {
            let snapshot = try await db.collection("users")
                .document(userId)
                .collection("savedCocktails")
                .getDocuments()
            
            let cocktails = try snapshot.documents.compactMap { document -> SavedCocktail? in
                try document.data(as: SavedCocktail.self)
            }
            
            await MainActor.run {
                self.savedCocktails = cocktails.sorted(by: { $0.savedAt > $1.savedAt })
            }
        } catch {
            await MainActor.run {
                self.error = error
            }
        }
    }
    
    // MARK: - Toggle Favorite
    func toggleFavorite(for cocktailId: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        if let index = savedCocktails.firstIndex(where: { $0.id == cocktailId }) {
            var updatedCocktail = savedCocktails[index]
            updatedCocktail.isFavorite.toggle()
            
            try await db.collection("users")
                .document(userId)
                .collection("savedCocktails")
                .document(cocktailId)
                .setData(from: updatedCocktail)
            
            await MainActor.run {
                savedCocktails[index] = updatedCocktail
            }
        }
    }
    
    // MARK: - Delete Cocktail
    func deleteCocktail(_ cocktailId: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        try await db.collection("users")
            .document(userId)
            .collection("savedCocktails")
            .document(cocktailId)
            .delete()
        
        await MainActor.run {
            savedCocktails.removeAll { $0.id == cocktailId }
        }
    }
    
    // MARK: - Error Handling
    func handleFirebaseError(_ error: Error) {
        if let nsError = error as NSError? {
            switch nsError.code {
            case AuthErrorCode.userNotFound.rawValue:
                self.error = UserError.signInError
            case AuthErrorCode.networkError.rawValue:
                // Handle network errors
                break
            default:
                self.error = error
            }
        }
    }
}

