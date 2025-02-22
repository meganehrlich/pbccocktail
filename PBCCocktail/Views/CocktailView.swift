//
//  CocktailView.swift
//  PBCCocktail
//
//  Created by Megan Amanda Ehrlich on 2/10/25.
//

import SwiftUI

struct CocktailView: View {
    @StateObject private var viewModel = CocktailViewModel()
    
    var body: some View {
        ZStack {
            // Background image with overlay
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
            
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    // Header - now positioned based on safe area
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
                    .padding(.top, geometry.safeAreaInsets.top - 8)
                    
                    // Cocktail display area
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .padding(.top, 40)
                    } else {
                        VStack(spacing: 20) {
                            Text(viewModel.currentDrink)
                                .font(.system(size: 24, weight: .light))
                                .tracking(2)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding(.top, 40)
                            
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
                        ForEach(["GIN", "VODKA", "RUM", "TEQUILA", "WHISKY"], id: \.self) { spirit in
                            Button(action: {
                                viewModel.fetchCocktail(forSpirit: spirit.lowercased())
                            }) {
                                Text(spirit)
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

#Preview {
    NavigationView {
        CocktailView()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "bookmark.fill")
                            .foregroundColor(.white)
                    }
                }
            }
    }
}
