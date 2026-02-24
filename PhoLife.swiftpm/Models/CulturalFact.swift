import Foundation

struct CulturalFact: Identifiable {
    let id: Int
    let minigameTitle: String
    let fact: String

    static let allFacts: [CulturalFact] = [
        CulturalFact(
            id: 1,
            minigameTitle: "Char the Aromatics",
            fact: "Charring aromatics adds a subtle smoky depth — a secret step that separates authentic pho from imitations."
        ),
        CulturalFact(
            id: 2,
            minigameTitle: "Toast the Spices",
            fact: "These five spices are the signature of pho's fragrance. Star anise and cinnamon dominate — you'll recognize them in every bowl."
        ),
        CulturalFact(
            id: 3,
            minigameTitle: "Clean the Bones",
            fact: "This blanching step is why pho broth is crystal clear. Skipping it means cloudy, murky soup — the mark of a careless cook."
        ),
        CulturalFact(
            id: 4,
            minigameTitle: "Simmer the Broth",
            fact: "Great pho broth is never rushed. A gentle 3-hour simmer extracts deep flavor while keeping the broth clear. A rolling boil makes it cloudy and bitter."
        ),
        CulturalFact(
            id: 5,
            minigameTitle: "Slice the Beef",
            fact: "Paper-thin raw beef is placed on top so the boiling broth cooks it to perfect medium-rare when ladled over. Too thick, and it stays chewy."
        ),
        CulturalFact(
            id: 6,
            minigameTitle: "Season the Broth",
            fact: "Fish sauce, not soy sauce, is the backbone of pho seasoning. The Vietnamese flavor philosophy balances savory, salty, sweet, sour, and spicy — with savory always leading."
        ),
        CulturalFact(
            id: 7,
            minigameTitle: "Assemble the Bowl",
            fact: "Order matters. Raw beef goes on top so the boiling broth hits it directly, cooking it to medium-rare in seconds. Bury it under noodles and it stays raw."
        ),
        CulturalFact(
            id: 8,
            minigameTitle: "Top It Off",
            fact: "Pho toppings are always served on the side — the eater customizes every bowl to their own taste. That's the communal philosophy of Vietnamese dining."
        ),
    ]
}
