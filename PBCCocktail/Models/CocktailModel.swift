//
//  CocktailModel.swift
//  PBCCocktail
//
//  Created by Megan Amanda Ehrlich on 2/10/25.
//

import SwiftUI

struct Cocktail: Codable, Hashable {
    let strDrink: String
    let strInstructions: String?
    let strDrinkThumb: String?
    let strIngredient1: String?
    let strIngredient2: String?
    let strIngredient3: String?
    let strIngredient4: String?
    let strIngredient5: String?
    let strMeasure1: String?
    let strMeasure2: String?
    let strMeasure3: String?
    let strMeasure4: String?
    let strMeasure5: String?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(strDrink)
    }
    
    static func == (lhs: Cocktail, rhs: Cocktail) -> Bool {
        return lhs.strDrink == rhs.strDrink
    }
}

struct CocktailResponse: Codable {
    let drinks: [Cocktail]?
}
