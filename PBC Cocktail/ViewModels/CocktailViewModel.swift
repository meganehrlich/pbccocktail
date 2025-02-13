//
//  CocktailViewModel.swift
//  PBC Cocktail
//
//  Created by Megan Amanda Ehrlich on 2/10/25.
//

import SwiftUI
import SwiftUI

class CocktailViewModel: ObservableObject {
    @Published var currentDrink = ""
    @Published var currentIngredients = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var noMoreCocktails = false
    
    // Track all shown cocktails
    private var shownCocktails: Set<String> = []
    
    // Separate tracking for API cocktails
    private var apiCocktails: [String: [Cocktail]] = [:]
    private var currentApiIndex: [String: Int] = [:]
    
    private let spirits = ["Gin", "Vodka", "Rum", "Tequila", "Whisky"]
    
    // Spirit variations mapping
    private let spiritVariations: [String: [String]] = [
        "Gin": ["gin"],
        "Vodka": ["vodka"],
        "Rum": ["rum", "light rum", "dark rum", "white rum", "spiced rum"],
        "Tequila": ["tequila", "mezcal"],
        "Whisky": ["whisky", "whiskey", "bourbon", "rye", "scotch", "irish whiskey"]
    ]
    
    func fetchCocktail(forSpirit spirit: String) {
        // Don't start a new request if we're already loading
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        // If we already have cocktails loaded for this spirit, get the next one
        if let cocktail = getNextApiCocktail(forSpirit: spirit) {
            fetchDrinkDetails(id: cocktail.strDrink, spirit: spirit)
            return
        }
        
        // If no cocktails loaded yet, fetch them from API
        fetchApiCocktails(forSpirit: spirit)
    }
    
    private func getNextApiCocktail(forSpirit spirit: String) -> Cocktail? {
        guard let cocktails = apiCocktails[spirit],
              let currentIdx = currentApiIndex[spirit],
              currentIdx < cocktails.count else {
            return nil
        }
        
        let cocktail = cocktails[currentIdx]
        currentApiIndex[spirit] = currentIdx + 1
        
        return cocktail
    }
    private func fetchApiCocktails(forSpirit spirit: String) {
        if spirit == "Whisky" {
            // Create a group to handle multiple API calls
            let group = DispatchGroup()
            var allDrinks: [Cocktail] = []
            
            // Search for each whiskey variation
            for variation in ["Whiskey", "Bourbon", "Scotch", "Rye"] {
                group.enter()
                
                let urlString = "https://www.thecocktaildb.com/api/json/v1/1/filter.php?i=\(variation)"
                guard let url = URL(string: urlString) else { continue }
                
                URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
                    defer { group.leave() }
                    if let data = data,
                       let response = try? JSONDecoder().decode(CocktailResponse.self, from: data),
                       let drinks = response.drinks {
                        allDrinks.append(contentsOf: drinks)
                    }
                }.resume()
            }
            
            group.notify(queue: .main) { [weak self] in
                guard let self = self else { return }
                
                // Remove duplicates and filter already shown cocktails
                let uniqueDrinks = Array(Set(allDrinks))
                    .filter { !self.shownCocktails.contains($0.strDrink) }
                    .shuffled()
                
                if uniqueDrinks.isEmpty {
                    self.noMoreCocktails = true
                    self.errorMessage = "No more cocktails available for \(spirit)"
                    self.isLoading = false
                    return
                }
                
                self.apiCocktails[spirit] = uniqueDrinks
                self.currentApiIndex[spirit] = 0
                
                if let cocktail = self.getNextApiCocktail(forSpirit: spirit) {
                    self.fetchDrinkDetails(id: cocktail.strDrink, spirit: spirit)
                }
            }
        } else {
            // Original implementation for other spirits
            let urlString = "https://www.thecocktaildb.com/api/json/v1/1/filter.php?i=\(spirit)"
            
            guard let url = URL(string: urlString) else {
                errorMessage = "Invalid URL"
                isLoading = false
                return
            }
            
            URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    if let error = error {
                        self.errorMessage = error.localizedDescription
                        self.isLoading = false
                        return
                    }
                    
                    guard let data = data else {
                        self.errorMessage = "No data received"
                        self.isLoading = false
                        return
                    }
                    
                    do {
                        let response = try JSONDecoder().decode(CocktailResponse.self, from: data)
                        if let drinks = response.drinks {
                            // Filter out already shown cocktails and shuffle the results
                            let filteredDrinks = drinks
                                .filter { !self.shownCocktails.contains($0.strDrink) }
                                .shuffled()
                            
                            if filteredDrinks.isEmpty {
                                self.noMoreCocktails = true
                                self.errorMessage = "No more cocktails available for \(spirit)"
                                self.isLoading = false
                                return
                            }
                            
                            self.apiCocktails[spirit] = filteredDrinks
                            self.currentApiIndex[spirit] = 0
                            
                            // Fetch the first cocktail
                            if let cocktail = self.getNextApiCocktail(forSpirit: spirit) {
                                self.fetchDrinkDetails(id: cocktail.strDrink, spirit: spirit)
                            }
                        } else {
                            self.errorMessage = "No cocktails found"
                            self.isLoading = false
                        }
                    } catch {
                        self.errorMessage = "Failed to decode response"
                        self.isLoading = false
                    }
                }
            }.resume()
        }
    }
//
//    private func fetchApiCocktails(forSpirit spirit: String) {
//        let apiSpirit = spirit == "Whisky" ? "Whiskey" : spirit
//        let urlString = "https://www.thecocktaildb.com/api/json/v1/1/filter.php?i=\(apiSpirit)"
//        
//        guard let url = URL(string: urlString) else {
//            errorMessage = "Invalid URL"
//            isLoading = false
//            return
//        }
//        
//        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
//            guard let self = self else { return }
//            
//            DispatchQueue.main.async {
//                if let error = error {
//                    self.errorMessage = error.localizedDescription
//                    self.isLoading = false
//                    return
//                }
//                
//                guard let data = data else {
//                    self.errorMessage = "No data received"
//                    self.isLoading = false
//                    return
//                }
//                
//                do {
//                    let response = try JSONDecoder().decode(CocktailResponse.self, from: data)
//                    if let drinks = response.drinks {
//                        // Filter out already shown cocktails and shuffle the results
//                        let filteredDrinks = drinks
//                            .filter { !self.shownCocktails.contains($0.strDrink) }
//                            .shuffled()
//                        
//                        if filteredDrinks.isEmpty {
//                            self.noMoreCocktails = true
//                            self.errorMessage = "No more cocktails available for \(spirit)"
//                            self.isLoading = false
//                            return
//                        }
//                        
//                        self.apiCocktails[spirit] = filteredDrinks
//                        self.currentApiIndex[spirit] = 0
//                        
//                        // Fetch the first cocktail
//                        if let cocktail = self.getNextApiCocktail(forSpirit: spirit) {
//                            self.fetchDrinkDetails(id: cocktail.strDrink, spirit: spirit)
//                        }
//                    } else {
//                        self.errorMessage = "No cocktails found"
//                        self.isLoading = false
//                    }
//                } catch {
//                    self.errorMessage = "Failed to decode response"
//                    self.isLoading = false
//                }
//            }
//        }.resume()
//    }
    
    private func fetchDrinkDetails(id: String, spirit: String) {
        let urlString = "https://www.thecocktaildb.com/api/json/v1/1/search.php?s=\(id)"
        guard let encodedString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encodedString) else {
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let data = data {
                    do {
                        let response = try JSONDecoder().decode(CocktailResponse.self, from: data)
                        if let drink = response.drinks?.first {
                            if self.verifySpiritInCocktail(drink, spirit: spirit) {
                                self.shownCocktails.insert(drink.strDrink)
                                self.updateUIWithCocktail(drink)
                            } else {
                                // If spirit verification fails, try the next cocktail
                                self.fetchCocktail(forSpirit: spirit)
                            }
                        }
                    } catch {
                        self.errorMessage = "Failed to decode drink details"
                    }
                }
                self.isLoading = false
            }
        }.resume()
    }
    
    func reset() {
        currentDrink = ""
        currentIngredients = ""
        errorMessage = nil
        shownCocktails.removeAll()
        apiCocktails.removeAll()
        currentApiIndex.removeAll()
        noMoreCocktails = false
    }
    
    private func verifySpiritInCocktail(_ cocktail: Cocktail, spirit: String) -> Bool {
        guard let variations = spiritVariations[spirit] else { return false }
        
        let ingredients = [
            cocktail.strIngredient1?.lowercased(),
            cocktail.strIngredient2?.lowercased(),
            cocktail.strIngredient3?.lowercased(),
            cocktail.strIngredient4?.lowercased(),
            cocktail.strIngredient5?.lowercased()
        ].compactMap { $0 }
        
        return ingredients.contains { ingredient in
            variations.contains { variation in
                ingredient.contains(variation)
            }
        }
    }
    
    private func updateUIWithCocktail(_ cocktail: Cocktail) {
        currentDrink = cocktail.strDrink
        
        // Build ingredients string
        var ingredients: [String] = []
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
        
        currentIngredients = ingredients.joined(separator: ", ")
    }
}
