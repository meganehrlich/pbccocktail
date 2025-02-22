//
//  UserModel.swift
//  PBCCocktail
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

extension SavedCocktail {
    var formattedIngredients: [String] {
        var ingredients: [String] = []
        
        // Attempt to create ingredients with measures
        if let m1 = cocktail.strMeasure1, let i1 = cocktail.strIngredient1 {
            ingredients.append("\(m1.trimmingCharacters(in: .whitespaces)) \(i1)")
        } else if let i1 = cocktail.strIngredient1 {
            ingredients.append(i1)
        }
        
        if let m2 = cocktail.strMeasure2, let i2 = cocktail.strIngredient2 {
            ingredients.append("\(m2.trimmingCharacters(in: .whitespaces)) \(i2)")
        } else if let i2 = cocktail.strIngredient2 {
            ingredients.append(i2)
        }
        
        if let m3 = cocktail.strMeasure3, let i3 = cocktail.strIngredient3 {
            ingredients.append("\(m3.trimmingCharacters(in: .whitespaces)) \(i3)")
        } else if let i3 = cocktail.strIngredient3 {
            ingredients.append(i3)
        }
        
        if let m4 = cocktail.strMeasure4, let i4 = cocktail.strIngredient4 {
            ingredients.append("\(m4.trimmingCharacters(in: .whitespaces)) \(i4)")
        } else if let i4 = cocktail.strIngredient4 {
            ingredients.append(i4)
        }
        
        if let m5 = cocktail.strMeasure5, let i5 = cocktail.strIngredient5 {
            ingredients.append("\(m5.trimmingCharacters(in: .whitespaces)) \(i5)")
        } else if let i5 = cocktail.strIngredient5 {
            ingredients.append(i5)
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
