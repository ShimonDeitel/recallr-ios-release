import SwiftUI
import SwiftData

struct HomeView: View {
    var forceScreen: String? = nil

    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var store: Store

    @State private var showSettings = false
    @State private var showPaywall = false
    @State private var showInsights = false
    @State private var showAddCard = false
    @State private var showReview = false

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        // Due today banner
                        dueBanner

                        // Metric row
                        HStack(spacing: 12) {
                            MetricTile(value: "\(appModel.cards.count)", label: "Total Cards")
                            MetricTile(value: "\(appModel.dueCards.count)", label: "Due Today")
                            MetricTile(value: "\(appModel.deckNames.count)", label: "Decks")
                        }

                        // Pro tile
                        Button {
                            Haptics.tap()
                            if store.isPro { showInsights = true }
                            else { showPaywall = true }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(store.isPro ? "Retention Insights" : "Recallr Pro")
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text(store.isPro
                                         ? "Streak, accuracy & history"
                                         : "Unlimited cards, insights & streaks")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: store.isPro ? "chart.bar.fill" : "lock.fill")
                                    .foregroundStyle(Color.qmAccent)
                            }
                            .qmCard()
                        }
                        .buttonStyle(.plain)

                        // Deck list
                        if !appModel.deckNames.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Your Decks")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 4)
                                ForEach(appModel.deckNames, id: \.self) { deck in
                                    deckRow(deck: deck)
                                }
                            }
                        } else {
                            emptyState
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Recallr")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Haptics.tap()
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(Color.qmAccent)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.tap()
                        showAddCard = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(Color.qmAccent)
                    }
                }
            }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .sheet(isPresented: $showInsights) { InsightsView() }
            .sheet(isPresented: $showAddCard, onDismiss: { appModel.reload() }) { AddCardView() }
            .sheet(isPresented: $showReview, onDismiss: { appModel.reload() }) {
                ReviewView(cards: appModel.dueCards)
            }
            .onAppear {
                if forceScreen == "review" { showReview = true }
                else if forceScreen == "add" { showAddCard = true }
                else if forceScreen == "insights" { showInsights = true }
            }
        }
    }

    // MARK: - Sub-views

    private var dueBanner: some View {
        Group {
            if appModel.dueCards.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.qmCorrect)
                    Text("All caught up! Check back tomorrow.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .qmCard()
            } else {
                Button {
                    Haptics.success()
                    showReview = true
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(appModel.dueCards.count) card\(appModel.dueCards.count == 1 ? "" : "s") due")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text("Tap to start today's review")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Color.qmAccent)
                    }
                    .qmCard()
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func deckRow(deck: String) -> some View {
        let count = appModel.cards.filter { $0.deckName == deck }.count
        let due = appModel.dueCards.filter { $0.deckName == deck }.count
        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(deck)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                Text("\(count) card\(count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if due > 0 {
                Text("\(due) due")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.qmAccent, in: Capsule())
            }
        }
        .qmCard()
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "rectangle.on.rectangle")
                .font(.system(size: 48))
                .foregroundStyle(Color.qmAccent.opacity(0.8))
            Text("No cards yet")
                .font(.title3.weight(.semibold))
            Text("Tap + to create your first flashcard.\nThe app will resurface it on the perfect day.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Add First Card") {
                Haptics.tap()
                showAddCard = true
            }
            .prominentButton()
        }
        .padding(.vertical, 40)
    }
}
