//
//  CocktailView.swift
//  PBC Cocktail
//
//  Created by Megan Amanda Ehrlich on 2/10/25.
//

import SwiftUI

struct CocktailView: View {
    @StateObject private var viewModel = CocktailViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // Fixed header area
            VStack(spacing: 16) {
                Text(viewModel.currentDrink)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .frame(height: 60) // Fixed height for title
                    .frame(maxWidth: .infinity)
                
                if !viewModel.currentDrink.isEmpty {
                    Text("Ingredients:")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                }
            }
            .padding(.top)
            .background(Color(UIColor.systemBackground))
            // Add a shadow to create visual separation
            .shadow(color: Color.black.opacity(0.1), radius: 2, y: 2)
            // Ensure header stays on top
            .zIndex(1)
            
            // Scrollable content area
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Ingredients list
                    if !viewModel.currentIngredients.isEmpty {
                        Text(viewModel.currentIngredients)
                            .font(.title3)
                            .multilineTextAlignment(.leading)
                            .padding(.horizontal, 40) // Match the drink name padding
                    }
                    
                    // Error message if present
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            
            // Button group at bottom
            VStack(spacing: 12) {
                HStack(spacing: 20) {
                    ForEach(["Gin", "Vodka"], id: \.self) { spirit in
                        spiritButton(spirit)
                    }
                }
                
                HStack(spacing: 20) {
                    ForEach(["Rum", "Tequila", "Whisky"], id: \.self) { spirit in
                        spiritButton(spirit)
                    }
                }
                
                Button(action: {
                    viewModel.reset()
                }) {
                    Text("Reset")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .disabled(viewModel.isLoading)
            }
            .padding(.vertical)
            .background(Color(UIColor.systemBackground))
            .shadow(color: Color.black.opacity(0.1), radius: 2, y: -2)
        }
        .overlay(
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.1))
                }
            }
        )
    }
    
    private func spiritButton(_ spirit: String) -> some View {
        Button(action: {
            viewModel.fetchCocktail(forSpirit: spirit)
        }) {
            Text(spirit)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
        }
        .disabled(viewModel.isLoading)
    }
}

#Preview {
    CocktailView()
}
