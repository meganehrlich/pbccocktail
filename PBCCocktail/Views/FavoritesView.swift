//
//  FavoritesView.swift
//  PBCCocktail
//
//  Created by Megan Amanda Ehrlich on 2/10/25.
//

import SwiftUI
import _AuthenticationServices_SwiftUI

struct FavoriteCardView: View {
    @StateObject private var firebaseManager = FirebaseManager()
    @State private var isExpanded = false
    
    private let backgroundColor = Color(white: 0.15) // Dark gray background
    private let textColor = Color.white.opacity(0.85) // Light text
    private let subtextColor = Color.white.opacity(0.6) // Lighter subdued text
    private let accentColor = Color.white // White accent color

    
    let savedCocktail: SavedCocktail
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Minimalist Card Design
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(savedCocktail.cocktail.strDrink)
                        .font(.custom("HelveticaNeue-Thin", size: 22))
                        .tracking(1.5)
                        .textCase(.uppercase)
                        .foregroundColor(textColor)
                    
                    if let spirit = savedCocktail.mainSpirit {
                        Text(spirit.uppercased())
                            .font(.custom("HelveticaNeue-Light", size: 12))
                            .tracking(2)
                            .foregroundColor(subtextColor)
                    }
                }
                
                Spacer()
                
                // Minimalist Favorite Icon
                Button(action: {
                    Task {
                        do {
                            try await firebaseManager.deleteCocktail(savedCocktail.id)
                        } catch {
                            print("Error deleting cocktail: \(error)")
                        }
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(accentColor)
                        .font(.system(size: 24, weight: .light))
                }
            }
            .padding()
            
            // Expandable Recipe Section with Elegant Typography
            if isExpanded {
                VStack(alignment: .leading, spacing: 15) {
                    Divider()
                        .background(accentColor)
                    
                    // Ingredients Section
                    Text("Recipe")
                        .font(.custom("HelveticaNeue-Light", size: 16))
                        .textCase(.uppercase)
                        .foregroundColor(textColor)
                        .padding(.horizontal)
                    
                    ForEach(savedCocktail.formattedIngredients, id: \.self) { ingredient in
                        Text("— \(ingredient)")
                            .font(.custom("HelveticaNeue-Light", size: 14))
                            .foregroundColor(subtextColor)
                            .padding(.horizontal)
                    }
                    
                    // Instructions Section
                    if let instructions = savedCocktail.cocktail.strInstructions {
                        Text("Preparation")
                            .font(.custom("HelveticaNeue-Light", size: 16))
                            .textCase(.uppercase)
                            .foregroundColor(textColor)
                            .padding([.horizontal, .top])
                        
                        Text(instructions)
                            .font(.custom("HelveticaNeue-Light", size: 14))
                            .foregroundColor(subtextColor)
                            .padding(.horizontal)
                    }
                }
                .transition(.opacity)
                .padding(.bottom)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColor)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        )
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.3)) {
                isExpanded.toggle()
            }
        }
        .padding(.vertical, 8)
    }
}

struct FavoritesView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var firebaseManager = FirebaseManager()
    @State private var searchText = ""
    @Environment(\.dismiss) var dismiss
    
    // Elegant, minimalist color palette
    private let backgroundColor = Color(white: 0.1) // Very dark background
    private let textColor = Color.white // White main text
    private let subtextColor = Color.white.opacity(0.6) // Subdued white text

    var filteredCocktails: [SavedCocktail] {
        // Same implementation as before
        if searchText.isEmpty {
            return firebaseManager.savedCocktails
        } else {
            return firebaseManager.savedCocktails.filter { savedCocktail in
                let cocktail = savedCocktail.cocktail
                let ingredients = [
                    cocktail.strIngredient1,
                    cocktail.strIngredient2,
                    cocktail.strIngredient3,
                    cocktail.strIngredient4,
                    cocktail.strIngredient5
                ].compactMap { $0 }
                
                return ingredients.contains { $0.lowercased().contains(searchText.lowercased()) } ||
                    cocktail.strDrink.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    var body: some View {
        Group {
            if authManager.authState == .authenticated {
                // Existing authenticated view content
                ZStack {
                    backgroundColor.ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        // Header
                        VStack(spacing: 8) {
                            Text("Cocktail Collection")
                                .font(.custom("HelveticaNeue-Thin", size: 38))
                                .tracking(3)
                                .textCase(.uppercase)
                                .foregroundColor(textColor)
                        }
                        .padding(.top, 20)
                        
                        // Search Bar
                        SearchBar(text: $searchText)
                            .padding(.horizontal)
                        
                        // Favorites List
                        if filteredCocktails.isEmpty {
                            VStack(spacing: 10) {
                                Text(searchText.isEmpty ? "No Cocktails" : "No Matches")
                                    .font(.custom("HelveticaNeue-Light", size: 18))
                                    .foregroundColor(subtextColor)
                                    .padding(.top, 30)
                                Text(searchText.isEmpty ?
                                     "Begin Your Collection" :
                                        "Refine Your Search")
                                    .font(.custom("HelveticaNeue-Light", size: 14))
                                    .foregroundColor(subtextColor.opacity(0.7))
                            }
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 15) {
                                    ForEach(filteredCocktails) { savedCocktail in
                                        FavoriteCardView(savedCocktail: savedCocktail)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
            } else {
                // New unauthenticated view content
                ZStack {
                    backgroundColor.ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        Spacer()
                        
                        Text("Cocktail Collection")
                            .font(.custom("HelveticaNeue-Thin", size: 38))
                            .tracking(3)
                            .textCase(.uppercase)
                            .foregroundColor(textColor)
                        
                        Text("Sign in to view and manage your saved cocktails")
                            .font(.custom("HelveticaNeue-Light", size: 16))
                            .foregroundColor(subtextColor)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        SignInWithAppleButton(
                            .signIn,
                            onRequest: { request in
                                authManager.handleSignInWithApple()
                            },
                            onCompletion: { _ in }
                        )
                        .frame(height: 44)
                        .padding(.horizontal, 40)
                        
                        Button("Cancel") {
                            dismiss()
                        }
                        .foregroundColor(subtextColor)
                        .padding(.top)
                        
                        Spacer()
                    }
                    .padding()
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            if authManager.authState == .authenticated {
                firebaseManager.startListeningForChanges()
            }
        }
    }
}

// Custom Search Bar
struct SearchBar: View {
    @Binding var text: String
    private let textGray = Color(white: 0.7) // Light gray for text
    private let placeholderGray = Color(white: 0.5) // Slightly darker placeholder
    private let cardGray = Color(white: 0.2) // Lighter dark gray for search background
    

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(textGray)
            
            TextField("Search by ingredient...", text: $text)
                .foregroundColor(textGray)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .tint(placeholderGray) // Cursor color
                .placeholder(when: text.isEmpty) {
                    Text("Search by ingredient...")
                        .foregroundColor(placeholderGray)
                }
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(textGray)
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(cardGray)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// Helper extension for placeholder styling
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

#Preview {
    NavigationView {
        FavoritesView()
    }
    .preferredColorScheme(.dark)
}
