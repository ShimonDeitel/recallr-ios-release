import Foundation
import SwiftData

// MARK: - SwiftData models

@Model
final class FlashCard {
    var id: UUID
    var front: String
    var back: String
    var deckName: String
    var ease: Double          // SM-2 ease factor (default 2.5)
    var intervalDays: Int     // days until next review
    var dueDate: Date
    var lastReviewed: Date?
    var lapses: Int           // times rated "missed"

    init(front: String, back: String, deckName: String) {
        self.id = UUID()
        self.front = front
        self.back = back
        self.deckName = deckName
        self.ease = 2.5
        self.intervalDays = 1
        self.dueDate = Date()
        self.lastReviewed = nil
        self.lapses = 0
    }
}

@Model
final class ReviewSession {
    var date: Date
    var cardsReviewed: Int
    var cardsCorrect: Int

    init(date: Date = .now, cardsReviewed: Int, cardsCorrect: Int) {
        self.date = date
        self.cardsReviewed = cardsReviewed
        self.cardsCorrect = cardsCorrect
    }
}

// MARK: - AppModel

@MainActor
final class AppModel: ObservableObject {
    let container: ModelContainer
    weak var store: Store?

    @Published private(set) var cards: [FlashCard] = []
    @Published private(set) var sessions: [ReviewSession] = []

    // Free tier limit
    static let freeCardLimit = 20

    init(container: ModelContainer) {
        self.container = container
        reload()
    }

    static func makeContainer() -> ModelContainer {
        let schema = Schema([FlashCard.self, ReviewSession.self])
        let config = ModelConfiguration("recallr", schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            let fallback = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return (try? ModelContainer(for: schema, configurations: [fallback]))!
        }
    }

    func reload() {
        let ctx = container.mainContext
        cards = (try? ctx.fetch(FetchDescriptor<FlashCard>(
            sortBy: [SortDescriptor(\.dueDate)]))) ?? []
        sessions = (try? ctx.fetch(FetchDescriptor<ReviewSession>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]))) ?? []
    }

    func refresh() { reload() }

    // MARK: - Card CRUD

    var isPro: Bool { store?.isPro ?? false }

    var canAddCard: Bool { isPro || cards.count < AppModel.freeCardLimit }

    func addCard(front: String, back: String, deck: String) {
        guard canAddCard else { return }
        let card = FlashCard(front: front, back: back, deckName: deck)
        container.mainContext.insert(card)
        try? container.mainContext.save()
        reload()
    }

    func deleteCard(_ card: FlashCard) {
        container.mainContext.delete(card)
        try? container.mainContext.save()
        reload()
    }

    // MARK: - Due cards

    var dueCards: [FlashCard] {
        let now = Date()
        return cards.filter { $0.dueDate <= now }
    }

    var deckNames: [String] {
        Array(Set(cards.map { $0.deckName })).sorted()
    }

    // MARK: - SM-2 review

    /// Grade: true = "got it", false = "missed it"
    func review(card: FlashCard, correct: Bool) {
        if correct {
            if card.intervalDays == 1 {
                card.intervalDays = 6
            } else {
                card.intervalDays = Int(Double(card.intervalDays) * card.ease)
            }
            card.ease = max(1.3, card.ease + 0.1)
        } else {
            card.lapses += 1
            card.intervalDays = 1
            card.ease = max(1.3, card.ease - 0.2)
        }
        card.lastReviewed = Date()
        card.dueDate = Calendar.current.date(byAdding: .day, value: card.intervalDays, to: .now) ?? .now
        try? container.mainContext.save()
    }

    func saveSession(reviewed: Int, correct: Int) {
        let s = ReviewSession(cardsReviewed: reviewed, cardsCorrect: correct)
        container.mainContext.insert(s)
        try? container.mainContext.save()
        reload()
    }

    // MARK: - Insights helpers

    var streakDays: Int {
        guard !sessions.isEmpty else { return 0 }
        var streak = 0
        var date = Calendar.current.startOfDay(for: .now)
        let sessionDates = Set(sessions.map { Calendar.current.startOfDay(for: $0.date) })
        while sessionDates.contains(date) {
            streak += 1
            date = Calendar.current.date(byAdding: .day, value: -1, to: date) ?? date
        }
        return streak
    }

    var retentionRate: Double {
        let total = sessions.reduce(0) { $0 + $1.cardsReviewed }
        let correct = sessions.reduce(0) { $0 + $1.cardsCorrect }
        guard total > 0 else { return 0 }
        return Double(correct) / Double(total)
    }

    // MARK: - Delete all

    func deleteAllData() {
        let ctx = container.mainContext
        cards.forEach { ctx.delete($0) }
        sessions.forEach { ctx.delete($0) }
        try? ctx.save()
        reload()
    }
}
