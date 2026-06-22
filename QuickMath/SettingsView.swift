import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    @AppStorage("quickmath.theme") private var themeRaw = AppTheme.system.rawValue
    @State private var showPaywall = false
    @State private var showDeleteConfirm = false

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                List {
                    // Pro section
                    Section("Subscription") {
                        if store.isPro {
                            HStack {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundStyle(Color.qmAccent)
                                Text("Recallr Pro — Active")
                                    .font(.subheadline.weight(.semibold))
                            }
                            Link("Manage Subscription",
                                 destination: URL(string: "https://apps.apple.com/account/subscriptions")!)
                                .font(.subheadline)
                                .foregroundStyle(Color.qmAccent)
                        } else {
                            Button("Upgrade to Pro — \(store.displayPrice)/month") {
                                Haptics.tap()
                                showPaywall = true
                            }
                            .foregroundStyle(Color.qmAccent)
                            Button("Restore Purchase") {
                                Haptics.tap()
                                Task { await store.restore() }
                            }
                            .foregroundStyle(Color.qmAccent)
                        }
                    }

                    // Appearance
                    Section("Appearance") {
                        Picker("Theme", selection: $themeRaw) {
                            ForEach(AppTheme.allCases) { theme in
                                Text(theme.label).tag(theme.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)
                        .listRowBackground(Color.clear)
                    }

                    // Legal
                    Section("Legal") {
                        Link("Privacy Policy",
                             destination: URL(string: "https://shimondeitel.github.io/recallr-site/privacy.html")!)
                            .font(.subheadline)
                            .foregroundStyle(Color.qmAccent)
                        Link("Terms of Use",
                             destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                            .font(.subheadline)
                            .foregroundStyle(Color.qmAccent)
                    }

                    // Danger zone
                    Section {
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Label("Delete All Data", systemImage: "trash")
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .confirmationDialog(
                "Delete all cards, decks, and review history?",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete Everything", role: .destructive) {
                    appModel.deleteAllData()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}
