////
////  SavedCocktailsView.swift
////  PBC Cocktail
////
////  Created by Megan Amanda Ehrlich on 2/13/25.
////
//
//import SwiftUI
//
//struct SavedCocktailsView: View {
//    @StateObject private var firebaseManager = FirebaseManager()
//    @Environment(\.dismiss) private var dismiss
//    
//    var body: some View {
//        NavigationView {
//            Group {
//                if firebaseManager.savedCocktails.isEmpty {
//                    VStack(spacing: 20) {
//                        Text("No Saved Cocktails")
//                            .font(.title)
//                            .foregroundColor(.gray)
//                        Text("Your saved cocktails will appear here")
//                            .foregroundColor(.gray)
//                    }
//                } else {
//                    List {
//                        ForEach(firebaseManager.savedCocktails) { savedCocktail in
//                            SavedCocktailRow(cocktail: savedCocktail) {
//                                Task {
//                                    try? await firebaseManager.toggleFavorite(for: savedCocktail.id)
//                                }
//                            }
//                        }
//                        .onDelete { indexSet in
//                            deleteCocktails(at: indexSet)
//                        }
//                    }
//                }
//            }
//            .navigationTitle("Saved Cocktails")
//            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button("Done") {
//                        dismiss()
//                    }
//                }
//            }
//        }
//        .task {
//            await firebaseManager.loadSavedCocktails()
//        }
//    }
//    
//    private func deleteCocktails(at offsets: IndexSet) {
//        Task {
//            for index in offsets {
//                let cocktailId = firebaseManager.savedCocktails[index].id
//                try? await firebaseManager.deleteCocktail(cocktailId)
//            }
//        }
//    }
//}
//
//struct SavedCocktailRow: View {
//    let cocktail: SavedCocktail
//    let onFavoriteToggle: () -> Void
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            HStack {
//                Text(cocktail.cocktail.strDrink)
//                    .font(.headline)
//                Spacer()
//                Button(action: onFavoriteToggle) {
//                    Image(systemName: cocktail.isFavorite ? "heart.fill" : "heart")
//                        .foregroundColor(cocktail.isFavorite ? .red : .gray)
//                }
//            }
//            
//            if let ingredients = formatIngredients(cocktail.cocktail) {
//                Text(ingredients)
//                    .font(.subheadline)
//                    .foregroundColor(.gray)
//            }
//        }
//        .padding(.vertical, 4)
//    }
//    
//    private func formatIngredients(_ cocktail: Cocktail) -> String? {
//        var ingredients: [String] = []
//        
//        // Add ingredients with their measurements
//        if let i1 = cocktail.strIngredient1 { ingredients.append(formatIngredient(i1, measure: cocktail.strMeasure1)) }
//        if let i2 = cocktail.strIngredient2 { ingredients.append(formatIngredient(i2, measure: cocktail.strMeasure2)) }
//        if let i3 = cocktail.strIngredient3 { ingredients.append(formatIngredient(i3, measure: cocktail.strMeasure3)) }
//        if let i4 = cocktail.strIngredient4 { ingredients.append(formatIngredient(i4, measure: cocktail.strMeasure4)) }
//        if let i5 = cocktail.strIngredient5 { ingredients.append(formatIngredient(i5, measure: cocktail.strMeasure5)) }
//        
//        return ingredients.isEmpty ? nil : ingredients.joined(separator: ", ")
//    }
//    
//    private func formatIngredient(_ ingredient: String, measure: String?) -> String {
//        if let measure = measure?.trimmingCharacters(in: .whitespaces), !measure.isEmpty {
//            return "\(measure) \(ingredient)"
//        }
//        return ingredient
//    }
//}
