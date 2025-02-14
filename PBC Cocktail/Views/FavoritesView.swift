//
//  FavoritesView.swift
//  PBC Cocktail
//
//  Created by Megan Amanda Ehrlich on 2/10/25.
//

import SwiftUI

struct FavoritesView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var firebaseManager = FirebaseManager()
    @State private var searchText = ""
    
    // Custom colors for monochrome theme
    private let darkBackground = Color(red: 0.06, green: 0.06, blue: 0.06)
    private let cardGray = Color(white: 0.15)
    private let accentGray = Color(white: 0.9)
    private let textGray = Color(white: 0.7)
    
    var filteredCocktails: [SavedCocktail] {
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
        ZStack {
            darkBackground.ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header
                Text("Favorites")
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
                // Subtitle
                Text("Your Recipe Book")
                    .font(.system(size: 16, weight: .light))
                    .foregroundColor(textGray)
                
                // Search Bar
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                    .foregroundColor(accentGray)
                
                // Favorites List
                if filteredCocktails.isEmpty {
                    VStack(spacing: 10) {
                        Text(searchText.isEmpty ? "No saved cocktails" : "No matches found")
                            .foregroundColor(textGray)
                            .padding(.top, 30)
                        Text(searchText.isEmpty ?
                            "Save some cocktails to get started" :
                            "Try searching for a different ingredient")
                            .font(.caption)
                            .foregroundColor(textGray.opacity(0.7))
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
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    // Add sorting/filtering action here
                }) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .foregroundColor(accentGray)
                }
            }
        }
        .onAppear {
            firebaseManager.startListeningForChanges()
        }
    }
}

struct FavoriteCardView: View {
    @StateObject private var firebaseManager = FirebaseManager()
    private let cardGray = Color(white: 0.15)
    private let accentGray = Color(white: 0.9)
    private let textGray = Color(white: 0.7)
    
    let savedCocktail: SavedCocktail
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(savedCocktail.cocktail.strDrink)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    Task {
                        try? await firebaseManager.toggleFavorite(for: savedCocktail.id)
                    }
                }) {
                    Image(systemName: savedCocktail.isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(accentGray)
                }
            }
            
            Text(savedCocktail.formattedIngredients.joined(separator: ", "))
                .font(.system(size: 16, weight: .light))
                .foregroundColor(textGray)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(cardGray)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                Task {
                    try? await firebaseManager.deleteCocktail(savedCocktail.id)
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// Custom Search Bar
struct SearchBar: View {
    @Binding var text: String
    private let textGray = Color(white: 0.7)
    private let placeholderGray = Color(white: 0.8) // Lighter gray for placeholder
    private let cardGray = Color(white: 0.15)
    
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
