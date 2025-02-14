//
//  FirebaseManager.swift
//  PBC Cocktail
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
    
    // MARK: - Save Cocktail
    func saveCocktail(_ cocktail: Cocktail) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw UserError.saveCocktailError
        }
        
        let savedCocktail = SavedCocktail(cocktail: cocktail)
        
        try await db.collection("users")
            .document(userId)
            .collection("savedCocktails")
            .document(savedCocktail.id)
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
}

extension FirebaseManager {
    // MARK: - Advanced Queries
    
    // Get favorite cocktails only
    func loadFavoriteCocktails() async throws -> [SavedCocktail] {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw UserError.signInError
        }
        
        let snapshot = try await db.collection("users")
            .document(userId)
            .collection("savedCocktails")
            .whereField("isFavorite", isEqualTo: true)
            .getDocuments()
            
        return try snapshot.documents.compactMap { document in
            try document.data(as: SavedCocktail.self)
        }
    }
    
    // Search cocktails by spirit
    func searchSavedCocktails(bySpirit spirit: String) async throws -> [SavedCocktail] {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw UserError.signInError
        }
        
        let snapshot = try await db.collection("users")
            .document(userId)
            .collection("savedCocktails")
            .getDocuments()
            
        return try snapshot.documents.compactMap { document -> SavedCocktail? in
            let cocktail = try document.data(as: SavedCocktail.self)
            let ingredients = [
                cocktail.cocktail.strIngredient1,
                cocktail.cocktail.strIngredient2,
                cocktail.cocktail.strIngredient3,
                cocktail.cocktail.strIngredient4,
                cocktail.cocktail.strIngredient5
            ].compactMap { $0.map { $0.lowercased() } }
            
            return ingredients.contains { $0.contains(spirit.lowercased()) } ? cocktail : nil
        }
    }
    
    // Batch update for cocktails
    func batchUpdateFavorites(cocktailIds: [String], isFavorite: Bool) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw UserError.signInError
        }
        
        let batch = db.batch()
        
        for cocktailId in cocktailIds {
            let docRef = db.collection("users")
                .document(userId)
                .collection("savedCocktails")
                .document(cocktailId)
            
            batch.updateData(["isFavorite": isFavorite], forDocument: docRef)
        }
        
        try await batch.commit()
        
        // Update local state
        await MainActor.run {
            for cocktailId in cocktailIds {
                if let index = savedCocktails.firstIndex(where: { $0.id == cocktailId }) {
                    savedCocktails[index].isFavorite = isFavorite
                }
            }
        }
    }
    
    // MARK: - Data Sync
    
    // Listen for real-time updates
    func startListeningForChanges() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users")
            .document(userId)
            .collection("savedCocktails")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let snapshot = snapshot else { return }
                
                do {
                    let updatedCocktails = try snapshot.documents.compactMap { document -> SavedCocktail? in
                        try document.data(as: SavedCocktail.self)
                    }
                    
                    Task { @MainActor in
                        self.savedCocktails = updatedCocktails.sorted(by: { $0.savedAt > $1.savedAt })
                    }
                } catch {
                    self.error = error
                }
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

// Add this extension to SavedCocktail for additional functionality
extension SavedCocktail {
    var formattedIngredients: [String] {
        var ingredients: [String] = []
        
        if let m1 = cocktail.strMeasure1, let i1 = cocktail.strIngredient1 {
            ingredients.append("\(m1.trimmingCharacters(in: .whitespaces)) \(i1)")
        }
        if let m2 = cocktail.strMeasure2, let i2 = cocktail.strIngredient2 {
            ingredients.append("\(m2.trimmingCharacters(in: .whitespaces)) \(i2)")
        }
        if let m3 = cocktail.strMeasure3, let i3 = cocktail.strIngredient3 {
            ingredients.append("\(m3.trimmingCharacters(in: .whitespaces)) \(i3)")
        }
        if let m4 = cocktail.strMeasure4, let i4 = cocktail.strIngredient4 {
            ingredients.append("\(m4.trimmingCharacters(in: .whitespaces)) \(i4)")
        }
        if let m5 = cocktail.strMeasure5, let i5 = cocktail.strIngredient5 {
            ingredients.append("\(m5.trimmingCharacters(in: .whitespaces)) \(i5)")
        }
        
        return ingredients
    }
    
    var mainSpirit: String? {
        let spirits = ["gin", "vodka", "rum", "tequila", "whisky", "whiskey", "bourbon", "scotch"]
        return formattedIngredients.first { ingredient in
            spirits.contains { spirit in
                ingredient.lowercased().contains(spirit)
            }
        }
    }
}
