//
//  ContentView.swift
//  PBC Cocktail
//
//  Created by Megan Amanda Ehrlich on 2/10/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = CocktailViewModel()
    @StateObject private var firebaseManager = FirebaseManager()
    @StateObject private var authManager = AuthenticationManager()
    @State private var showingSavedCocktails = false
    @State private var showingSignInSheet = false
    
    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                ZStack {
                    // Your existing ZStack content remains the same
                    Image("pelican")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .overlay(
                            LinearGradient(
                                gradient: Gradient(colors: [.black.opacity(0.4), .black.opacity(0.2)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .ignoresSafeArea()
                    
                    VStack {
                        // Header
                        VStack(spacing: 8) {
                            Text(" RANDOM COCKTAIL")
                                .font(.system(size: 28, weight: .light))
                                .tracking(8)
                                .foregroundColor(.white)
                            
                            Text("FIRST EDITION")
                                .font(.system(size: 14, weight: .light))
                                .tracking(4)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .padding(.top, 30)
                        
                        Spacer()
                        
                        // Cocktail display area
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            VStack(spacing: 20) {
                                Text(viewModel.currentDrink)
                                    .font(.system(size: 24, weight: .light))
                                    .tracking(2)
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                
                                if !viewModel.currentDrink.isEmpty {
                                    Rectangle()
                                        .frame(width: 40, height: 1)
                                        .foregroundColor(.white.opacity(0.5))
                                }
                                
                                VStack(alignment: .center, spacing: 8) {
                                    ForEach(viewModel.currentIngredients.components(separatedBy: ", "), id: \.self) { ingredient in
                                        Text(ingredient)
                                            .font(.system(size: 16, weight: .light))
                                            .tracking(1)
                                            .foregroundColor(.white.opacity(0.9))
                                    }
                                }
                                .padding(.horizontal, 40)
                            }
                        }
                        
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.system(size: 14, weight: .light))
                                .foregroundColor(.red.opacity(0.9))
                                .padding()
                        }
                        
                        Spacer()
                        
                        // Spirit buttons
                        VStack(spacing: 16) {
                            ForEach(["Gin", "Vodka", "Rum", "Tequila", "Whisky"], id: \.self) { spirit in
                                Button(action: {
                                    viewModel.fetchCocktail(forSpirit: spirit)
                                }) {
                                    Text(spirit.uppercased())
                                        .font(.system(size: 14, weight: .light))
                                        .tracking(4)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(Color.black.opacity(0.2))
                                        .cornerRadius(2)
                                }
                            }
                            
                            Button(action: {
                                viewModel.reset()
                            }) {
                                Text("RESTART")
                                    .font(.system(size: 14, weight: .light))
                                    .tracking(4)
                                    .foregroundColor(.white.opacity(0.8))
                                    .padding(.vertical, 10)
                            }
                        }
                        .padding(.horizontal, 40)
                        .padding(.bottom, 40)
                    }
                }
                
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack {
                            Button(action: {
                                if authManager.authState == .authenticated {
                                    showingSavedCocktails = true
                                } else {
                                    showingSignInSheet = true
                                }
                            }) {
                                Image(systemName: "bookmark.fill")
                                    .foregroundColor(.white)
                            }
                            
                            if !viewModel.currentDrink.isEmpty {
                                Button(action: {
                                    if authManager.authState == .authenticated {
                                        saveCocktail()
                                    } else {
                                        showingSignInSheet = true
                                    }
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.white)
                                }
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showingSavedCocktails) {
                FavoritesView()
            }
            .sheet(isPresented: $showingSignInSheet) {
                SignInView()
                    .environmentObject(authManager)
                    .onChange(of: authManager.authState) { newState in
                        if newState == .authenticated {
                            showingSignInSheet = false
                            // If user was trying to save a cocktail, save it now
                            if !viewModel.currentDrink.isEmpty {
                                saveCocktail()
                            }
                            // Show the favorites view after successful sign-in
                            showingSavedCocktails = true
                        }
                    }
            }
        }
    }
    
    private func saveCocktail() {
        guard !viewModel.currentDrink.isEmpty else { return }
        
        // Create a more thorough duplicate check
        let normalizedCurrentDrink = viewModel.currentDrink.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        let isDuplicate = firebaseManager.savedCocktails.contains { savedCocktail in
            let normalizedSavedDrink = savedCocktail.cocktail.strDrink.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            return normalizedCurrentDrink == normalizedSavedDrink
        }
        
        // Add print statements for debugging
        print("Attempting to save cocktail: \(normalizedCurrentDrink)")
        print("Current saved cocktails: \(firebaseManager.savedCocktails.map { $0.cocktail.strDrink })")
        print("Is duplicate: \(isDuplicate)")
        
        if isDuplicate {
            print("Duplicate cocktail found - not saving")
            showingSavedCocktails = true
            return
        }
        
        let cocktail = Cocktail(
            strDrink: viewModel.currentDrink,
            strInstructions: nil,
            strDrinkThumb: nil,
            strIngredient1: viewModel.currentIngredients.components(separatedBy: ", ").first,
            strIngredient2: viewModel.currentIngredients.components(separatedBy: ", ").dropFirst().first,
            strIngredient3: viewModel.currentIngredients.components(separatedBy: ", ").dropFirst(2).first,
            strIngredient4: viewModel.currentIngredients.components(separatedBy: ", ").dropFirst(3).first,
            strIngredient5: viewModel.currentIngredients.components(separatedBy: ", ").dropFirst(4).first,
            strMeasure1: nil,
            strMeasure2: nil,
            strMeasure3: nil,
            strMeasure4: nil,
            strMeasure5: nil
        )
        
        Task {
            do {
                try await firebaseManager.saveCocktail(cocktail)
                showingSavedCocktails = true
            } catch {
                print("Error saving cocktail: \(error)")
            }
        }
    }
}
