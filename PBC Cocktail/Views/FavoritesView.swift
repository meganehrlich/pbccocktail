//
//  FavoritesView.swift
//  PBC Cocktail
//
//  Created by Megan Amanda Ehrlich on 2/10/25.
//

import SwiftUI

struct FavoritesView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var searchText = ""
    
    // Custom colors for monochrome theme
    private let darkBackground = Color(red: 0.06, green: 0.06, blue: 0.06)
    private let cardGray = Color(white: 0.15)
    private let accentGray = Color(white: 0.9)
    private let textGray = Color(white: 0.7)
    
    // Sample data - replace with your actual data from Firebase
    private let sampleCocktails = [
        Cocktail(
            strDrink: "Martini",
            strInstructions: "Stir with ice, strain into chilled glass, garnish with olive",
            strDrinkThumb: nil,
            strIngredient1: "Gin",
            strIngredient2: "Dry Vermouth",
            strIngredient3: "Olive",
            strIngredient4: nil,
            strIngredient5: nil,
            strMeasure1: "1 2/3 oz",
            strMeasure2: "1/3 oz",
            strMeasure3: "1",
            strMeasure4: nil,
            strMeasure5: nil
        ),
        Cocktail(
            strDrink: "Negroni Torboto",
            strInstructions: nil,
            strDrinkThumb: nil,
            strIngredient1: "Scotch",
            strIngredient2: "Cynar",
            strIngredient3: "Aperol",
            strIngredient4: nil,
            strIngredient5: nil,
            strMeasure1: "1/3 oz",
            strMeasure2: "1/3 oz",
            strMeasure3: "1/3 oz",
            strMeasure4: nil,
            strMeasure5: nil
        )
    ]
    
    var filteredCocktails: [Cocktail] {
        if searchText.isEmpty {
            return sampleCocktails
        } else {
            return sampleCocktails.filter { cocktail in
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
                        Text("No matches found")
                            .foregroundColor(textGray)
                            .padding(.top, 30)
                        Text("Try searching for a different ingredient or add new ones to your favorites")
                            .font(.caption)
                            .foregroundColor(textGray.opacity(0.7))
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 15) {
                            ForEach(filteredCocktails, id: \.strDrink) { cocktail in
                                FavoriteCardView(cocktail: cocktail)
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
    }
}

struct FavoriteCardView: View {
    private let cardGray = Color(white: 0.15)
    private let accentGray = Color(white: 0.9)
    private let textGray = Color(white: 0.7)
    
    let cocktail: Cocktail
    
    var formattedIngredients: String {
        var ingredients: [String] = []
        
        // Combine measurements and ingredients
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
        
        return ingredients.joined(separator: ", ")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(cocktail.strDrink)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    // Remove from favorites action
                }) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(accentGray)
                }
            }
            
            Text(formattedIngredients)
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
