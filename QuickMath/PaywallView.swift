import SwiftUI

struct PaywallView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    private let benefits: [(icon: String, text: String)] = [
        ("infinity", "Unlimited decks and cards beyond the free starter limit"),
        ("chart.bar.fill", "Retention insights and review-history charts"),
        ("bell.badge.fill", "Daily due-cards reminder with a review streak")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                ScrollView {
                    VStack(spacing: 28) {
                        // Icon
                        ZStack {
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .fill(Color.qmCard)
                                .frame(width: 88, height: 88)
                            Image(systemName: "rectangle.on.rectangle")
                                .font(.system(size: 40))
                                .foregroundStyle(Color.qmAccent)
                        }
                        .padding(.top, 20)

                        VStack(spacing: 8) {
                            Text("Recallr Pro")
                                .font(.title.weight(.bold))
                            Text("\(store.displayPrice) / month.\nAuto-renews until you cancel.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }

                        // Benefits
                        VStack(spacing: 14) {
                            ForEach(benefits, id: \.text) { b in
                                HStack(alignment: .top, spacing: 14) {
                                    Image(systemName: b.icon)
                                        .foregroundStyle(Color.qmAccent)
                                        .frame(width: 24)
                                    Text(b.text)
                                        .font(.subheadline)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                }
                            }
                        }
                        .qmCard()

                        // Purchase button
                        Button {
                            Haptics.tap()
                            Task {
                                await store.purchase()
                            }
                        } label: {
                            Group {
                                if store.purchaseInFlight {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Unlock Pro — \(store.displayPrice)/mo")
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .prominentButton()
                        .disabled(store.purchaseInFlight)

                        // Restore
                        Button("Restore Purchase") {
                            Haptics.tap()
                            Task { await store.restore() }
                        }
                        .font(.subheadline)
                        .foregroundStyle(Color.qmAccent)

                        // Disclosure
                        VStack(spacing: 10) {
                            Text("""
Recallr Pro is a \(store.displayPrice)/month auto-renewable subscription. \
Payment is charged to your Apple ID account at confirmation of purchase. \
Your subscription automatically renews each month unless it is canceled at least 24 hours before the end of the current period. \
You can manage and cancel your subscriptions by going to your App Store account settings after purchase.
""")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                                .multilineTextAlignment(.center)

                            HStack(spacing: 20) {
                                Link("Terms of Use",
                                     destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                                Link("Privacy Policy",
                                     destination: URL(string: "https://shimondeitel.github.io/recallr-site/privacy.html")!)
                            }
                            .font(.caption2)
                            .foregroundStyle(Color.qmAccent)
                        }
                        .padding(.horizontal, 8)

                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
            .onChange(of: store.isPro) { _, newValue in
                if newValue { dismiss() }
            }
        }
    }
}
