import SwiftUI
import SwiftData

// MARK: - Add Card Sheet

struct AddCardView: View {
    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    @State private var front = ""
    @State private var back = ""
    @State private var deckName = ""
    @State private var showPaywall = false
    @State private var existingDeck: String = ""

    private var decks: [String] { appModel.deckNames }

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        if !appModel.canAddCard {
                            paywallBanner
                        }

                        // Front
                        fieldSection(title: "Front (question)") {
                            TextField("What do you want to remember?", text: $front, axis: .vertical)
                                .lineLimit(3...6)
                                .padding(12)
                                .background(Color.qmField, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }

                        // Back
                        fieldSection(title: "Back (answer)") {
                            TextField("The answer or definition", text: $back, axis: .vertical)
                                .lineLimit(3...6)
                                .padding(12)
                                .background(Color.qmField, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }

                        // Deck picker
                        fieldSection(title: "Deck") {
                            if !decks.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(decks, id: \.self) { d in
                                            Button(d) {
                                                Haptics.tap()
                                                deckName = d
                                            }
                                            .font(.subheadline.weight(deckName == d ? .semibold : .regular))
                                            .foregroundStyle(deckName == d ? .white : Color.qmAccent)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(
                                                deckName == d
                                                ? Color.qmAccent
                                                : Color.qmCard,
                                                in: Capsule()
                                            )
                                        }
                                    }
                                }
                                Text("or create new:")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            TextField("Deck name (e.g. Spanish, History)", text: $deckName)
                                .padding(12)
                                .background(Color.qmField, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }

                        Button("Save Card") {
                            save()
                        }
                        .prominentButton()
                        .disabled(!canSave)
                        .opacity(canSave ? 1 : 0.4)
                        .padding(.top, 8)

                        // Card count indicator
                        if !store.isPro {
                            Text("\(appModel.cards.count)/\(AppModel.freeCardLimit) free cards used")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("New Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private var canSave: Bool {
        !front.trimmingCharacters(in: .whitespaces).isEmpty &&
        !back.trimmingCharacters(in: .whitespaces).isEmpty &&
        !deckName.trimmingCharacters(in: .whitespaces).isEmpty &&
        appModel.canAddCard
    }

    private func save() {
        guard canSave else { return }
        Haptics.success()
        appModel.addCard(
            front: front.trimmingCharacters(in: .whitespaces),
            back: back.trimmingCharacters(in: .whitespaces),
            deck: deckName.trimmingCharacters(in: .whitespaces)
        )
        dismiss()
    }

    private var paywallBanner: some View {
        Button {
            Haptics.tap()
            showPaywall = true
        } label: {
            HStack {
                Image(systemName: "lock.fill")
                    .foregroundStyle(Color.qmAccent)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Card limit reached")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text("Upgrade to Pro for unlimited cards")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .qmCard()
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func fieldSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            content()
        }
    }
}

// MARK: - Review Session View

struct ReviewView: View {
    @EnvironmentObject var appModel: AppModel
    @Environment(\.dismiss) private var dismiss

    let cards: [FlashCard]

    @State private var index = 0
    @State private var revealed = false
    @State private var correct = 0
    @State private var reviewed = 0
    @State private var done = false

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                if done || cards.isEmpty {
                    doneView
                } else {
                    reviewCard
                }
            }
            .navigationTitle("Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        finish()
                    }
                }
            }
        }
    }

    private var reviewCard: some View {
        VStack(spacing: 24) {
            // Progress
            ProgressView(value: Double(index), total: Double(cards.count))
                .tint(Color.qmAccent)
                .padding(.horizontal, 16)

            Text("\(index + 1) of \(cards.count)")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            // Card face
            VStack(spacing: 16) {
                Text(revealed ? "Back" : "Front")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 4)

                Text(revealed ? cards[index].back : cards[index].front)
                    .font(.title3.weight(.medium))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .qmCard()
                    .padding(.horizontal, 16)

                if !revealed {
                    Text("Deck: \(cards[index].deckName)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Buttons
            if !revealed {
                Button("Show Answer") {
                    Haptics.tap()
                    withAnimation(.easeInOut(duration: 0.2)) { revealed = true }
                }
                .prominentButton()
            } else {
                HStack(spacing: 20) {
                    Button {
                        Haptics.warning()
                        grade(correct: false)
                    } label: {
                        Label("Missed", systemImage: "xmark")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.qmWrong.opacity(0.15), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .foregroundStyle(Color.qmWrong)
                            .font(.headline.weight(.semibold))
                    }
                    .buttonStyle(.plain)

                    Button {
                        Haptics.success()
                        grade(correct: true)
                    } label: {
                        Label("Got it", systemImage: "checkmark")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.qmCorrect.opacity(0.15), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .foregroundStyle(Color.qmCorrect)
                            .font(.headline.weight(.semibold))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
            }

            Spacer(minLength: 40)
        }
    }

    private func grade(correct isCorrect: Bool) {
        appModel.review(card: cards[index], correct: isCorrect)
        if isCorrect { correct += 1 }
        reviewed += 1
        if index + 1 >= cards.count {
            finish()
        } else {
            index += 1
            revealed = false
        }
    }

    private func finish() {
        if reviewed > 0 {
            appModel.saveSession(reviewed: reviewed, correct: correct)
        }
        done = true
    }

    private var doneView: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color.qmCorrect)

            Text("Session Complete!")
                .font(.title2.weight(.bold))

            HStack(spacing: 20) {
                MetricTile(value: "\(reviewed)", label: "Reviewed")
                MetricTile(value: "\(correct)", label: "Correct")
                MetricTile(
                    value: reviewed > 0 ? "\(Int(Double(correct)/Double(reviewed)*100))%" : "—",
                    label: "Accuracy"
                )
            }
            .padding(.horizontal, 16)

            Spacer()

            Button("Done") { dismiss() }
                .prominentButton()

            Spacer(minLength: 40)
        }
    }
}
