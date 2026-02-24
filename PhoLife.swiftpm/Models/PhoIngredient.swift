import Foundation

struct PhoIngredient: Identifiable {
    let id: Int
    let name: String
    let contribution: String
    let icon: PhoIngredientIcon

    static let allIngredients: [PhoIngredient] = [
        PhoIngredient(id: 1, name: "Charred Onion & Ginger", contribution: "Smoky depth and aromatic backbone", icon: .onion),
        PhoIngredient(id: 2, name: "Whole Spices", contribution: "Signature fragrance of star anise & cinnamon", icon: .starAnise),
        PhoIngredient(id: 3, name: "Beef Bones", contribution: "Rich collagen body and clear golden broth", icon: .bone),
        PhoIngredient(id: 4, name: "Slow-Simmered Broth", contribution: "Hours of gentle heat for deep umami", icon: .pot),
        PhoIngredient(id: 5, name: "Paper-Thin Beef", contribution: "Cooks to medium-rare from the hot broth", icon: .beefSlice),
        PhoIngredient(id: 6, name: "Fish Sauce & Rock Sugar", contribution: "Savory-sweet seasoning balance", icon: .fishSauce),
        PhoIngredient(id: 7, name: "Fresh Rice Noodles", contribution: "Silky foundation that carries the broth", icon: .noodles),
        PhoIngredient(id: 8, name: "Fresh Herbs & Garnish", contribution: "Bright contrast — basil, lime, bean sprouts", icon: .herbs),
    ]
}
