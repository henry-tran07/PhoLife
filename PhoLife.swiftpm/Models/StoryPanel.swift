import Foundation

enum NarratorExpression: String, CaseIterable {
    case happy
    case neutral
    case speak

    var imageName: String {
        switch self {
        case .happy: return "narratorHappy"
        case .neutral: return "narratorNeutral"
        case .speak: return "narratorSpeak"
        }
    }
}

struct DialogueSegment: Identifiable {
    let id: Int
    let text: String
    let expression: NarratorExpression
}

struct StoryPanel: Identifiable {
    let id: Int
    let title: String
    let bodyText: String
    let imageName: String
    let ambientAudioFile: String?
    let expression: NarratorExpression
    let dialogueSegments: [DialogueSegment]

    static let allPanels: [StoryPanel] = [
        StoryPanel(
            id: 1,
            title: "Every great bowl has a story.",
            bodyText: "",
            imageName: "story-panel-1",
            ambientAudioFile: nil,
            expression: .happy,
            dialogueSegments: [
                DialogueSegment(id: 1, text: "I'm Khoa Nguyen, from Đà Nẵng.", expression: .happy),
                DialogueSegment(id: 2, text: "Let me tell you how phở came to be.", expression: .speak),
            ]
        ),
        StoryPanel(
            id: 2,
            title: "Before it had a name",
            bodyText: "In the villages along the Red River, Vietnamese cooks had been simmering bones and herbs for centuries. But the dish that would become pho didn't exist yet.",
            imageName: "story-panel-2",
            ambientAudioFile: nil,
            expression: .neutral,
            dialogueSegments: [
                DialogueSegment(id: 1, text: "In the villages along the Red River, Vietnamese cooks had been simmering bones and herbs for centuries.", expression: .neutral),
                DialogueSegment(id: 2, text: "But the dish that would become pho didn't exist yet.", expression: .neutral),
            ]
        ),
        StoryPanel(
            id: 3,
            title: "Where worlds collided",
            bodyText: "When the French arrived, they brought their appetite for beef. The bones they discarded became treasure in Vietnamese hands.",
            imageName: "story-panel-3",
            ambientAudioFile: nil,
            expression: .neutral,
            dialogueSegments: [
                DialogueSegment(id: 1, text: "When the French arrived, they brought their appetite for beef.", expression: .neutral),
                DialogueSegment(id: 2, text: "The bones they discarded became treasure in Vietnamese hands.", expression: .happy),
            ]
        ),
        StoryPanel(
            id: 4,
            title: "Alchemy in a pot",
            bodyText: "Charred aromatics. Toasted spices. Beef bones simmered for hours. What emerged was unlike anything before — a broth that was light as water but deep as the earth.",
            imageName: "story-panel-4",
            ambientAudioFile: nil,
            expression: .speak,
            dialogueSegments: [
                DialogueSegment(id: 1, text: "Charred aromatics. Toasted spices. Beef bones simmered for hours.", expression: .speak),
                DialogueSegment(id: 2, text: "What emerged was unlike anything before — a broth that was light as water but deep as the earth.", expression: .happy),
            ]
        ),
        StoryPanel(
            id: 5,
            title: "The streets came alive",
            bodyText: "Pho became the rhythm of Hanoi mornings. Vendors carried entire kitchens on their shoulders, and the city woke to the sound of broth ladled into bowls.",
            imageName: "story-panel-5",
            ambientAudioFile: nil,
            expression: .happy,
            dialogueSegments: [
                DialogueSegment(id: 1, text: "Pho became the rhythm of Hanoi mornings.", expression: .happy),
                DialogueSegment(id: 2, text: "Vendors carried entire kitchens on their shoulders, and the city woke to the sound of broth ladled into bowls.", expression: .speak),
            ]
        ),
        StoryPanel(
            id: 6,
            title: "A country divided",
            bodyText: "In 1954, Vietnam was split in two. Pho split with it. The North kept it pure — just broth, noodles, and beef. The South made it abundant — herbs, sauces, and sweetness piled high.",
            imageName: "story-panel-6",
            ambientAudioFile: nil,
            expression: .neutral,
            dialogueSegments: [
                DialogueSegment(id: 1, text: "In 1954, Vietnam was split in two. Pho split with it.", expression: .neutral),
                DialogueSegment(id: 2, text: "The North kept it pure — just broth, noodles, and beef.", expression: .neutral),
                DialogueSegment(id: 3, text: "The South made it abundant — herbs, sauces, and sweetness piled high.", expression: .happy),
            ]
        ),
        StoryPanel(
            id: 7,
            title: "Carried across oceans",
            bodyText: "After 1975, over a million Vietnamese fled by sea. They couldn't carry much. But they carried their recipes — and the memory of home in a bowl.",
            imageName: "story-panel-7",
            ambientAudioFile: nil,
            expression: .neutral,
            dialogueSegments: [
                DialogueSegment(id: 1, text: "After 1975, over a million Vietnamese fled by sea. They couldn't carry much.", expression: .neutral),
                DialogueSegment(id: 2, text: "But they carried their recipes — and the memory of home in a bowl.", expression: .happy),
            ]
        ),
        StoryPanel(
            id: 8,
            title: "New roots",
            bodyText: "In Houston, Sydney, Paris, and San Jose, pho restaurants became anchors. The first taste of home in a new country. The place where communities rebuilt.",
            imageName: "story-panel-8",
            ambientAudioFile: nil,
            expression: .neutral,
            dialogueSegments: [
                DialogueSegment(id: 1, text: "In Houston, Sydney, Paris, and San Jose, pho restaurants became anchors.", expression: .neutral),
                DialogueSegment(id: 2, text: "The first taste of home in a new country. The place where communities rebuilt.", expression: .happy),
            ]
        ),
        StoryPanel(
            id: 9,
            title: "More than soup",
            bodyText: "Pho is not soup. It is patience simmered into broth. History ladled into a bowl. A culture you can taste.",
            imageName: "story-panel-9",
            ambientAudioFile: nil,
            expression: .speak,
            dialogueSegments: [
                DialogueSegment(id: 1, text: "Pho is not soup.", expression: .speak),
                DialogueSegment(id: 2, text: "It is patience simmered into broth. History ladled into a bowl. A culture you can taste.", expression: .happy),
            ]
        ),
        StoryPanel(
            id: 10,
            title: "Your turn",
            bodyText: "Now you know the story. Time to make the bowl.",
            imageName: "story-panel-10",
            ambientAudioFile: nil,
            expression: .happy,
            dialogueSegments: [
                DialogueSegment(id: 1, text: "Now you know the story. Time to make the bowl.", expression: .happy),
            ]
        ),
    ]
}
