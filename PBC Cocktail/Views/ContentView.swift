//
//  ContentView.swift
//  PBC Cocktail
//
//  Created by Megan Amanda Ehrlich on 2/10/25.
//

import SwiftUI
struct ContentView: View {
    @StateObject private var viewModel = CocktailViewModel()
    @State private var showingFavorites = false
    
    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                ZStack {
                    // Background image with lighter overlay
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
                        // Keep header size the same
                        VStack(spacing: 4) {
                            Text("RANDOM COCKTAIL")
                                .font(.system(size: 28, weight: .light))
                                .tracking(8)
                                .foregroundColor(.white)
                            
                            Text("FIRST EDITION")
                                .font(.system(size: 14, weight: .light))
                                .tracking(4)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .padding(.top, 60)
                        
                        Spacer()
                        
                        // Cocktail display area with smaller fonts
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            VStack(spacing: 20) {
                                // Reduced cocktail name size
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
                                
                                // Smaller ingredient text
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
                        
                        // Smaller spirit buttons
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
            }
        }
    }
}
//                .toolbar {
//                    ToolbarItem(placement: .navigationBarTrailing) {
//                        Button(action: {
//                            showingFavorites = true
//                        }) {
//                            Image(systemName: "heart.fill")
//                                .foregroundColor(.white)
//                        }
//                    }
//                }
//                .navigationDestination(isPresented: $showingFavorites) {
//                    FavoritesView()
//                }
