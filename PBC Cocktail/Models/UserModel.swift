//
//  UserModel.swift
//  PBC Cocktail
//
//  Created by Megan Amanda Ehrlich on 2/13/25.
//

import SwiftUI
import Foundation
import AuthenticationServices

struct User: Identifiable, Codable {
    let id: String  // Firebase UID
    var email: String?  // Optional since Apple might hide the email
    var appleIdentifier: String?  // Apple's unique identifier
    var savedCocktails: [SavedCocktail]
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case appleIdentifier
        case savedCocktails
    }
}

struct SavedCocktail: Identifiable, Codable {
    let id: String
    let cocktailId: String
    let savedAt: Date
    var isFavorite: Bool
    let cocktail: Cocktail
    
    init(id: String = UUID().uuidString,
         cocktail: Cocktail,
         isFavorite: Bool = false) {
        self.id = id
        self.cocktailId = cocktail.strDrink
        self.savedAt = Date()
        self.isFavorite = isFavorite
        self.cocktail = cocktail
    }
}

// AuthenticationState to manage login status
enum AuthenticationState {
    case unauthenticated
    case authenticating
    case authenticated
}

// Authentication provider types
enum AuthProvider {
    case apple
}

// UserError for handling authentication and profile errors
enum UserError: Error {
    case signInError
    case signOutError
    case appleSignInError
    case saveCocktailError
    case deleteCocktailError
    
    var description: String {
        switch self {
        case .signInError:
            return "Failed to sign in. Please try again."
        case .signOutError:
            return "Failed to sign out. Please try again."
        case .appleSignInError:
            return "Failed to sign in with Apple. Please try again."
        case .saveCocktailError:
            return "Failed to save cocktail. Please try again."
        case .deleteCocktailError:
            return "Failed to delete cocktail. Please try again."
        }
    }
}
