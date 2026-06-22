import SwiftUI
import Charts

// MARK: - Insights (Pro)

struct InsightsView: View {
    @EnvironmentObject var appModel: AppModel
    @Environment(\.dismiss) private var dismiss

    private var last7: [ReviewSession] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -6, to: Calendar.current.startOfDay(for: .now)) ?? .now
        return appModel.sessions.filter { $0.date >= cutoff }
    }

    private var chartData: [(day: String, count: Int)] {
        let cal = Calendar.current
        return (0..<7).reversed().map { offset -> (String, Int) in
            let date = cal.date(byAdding: .day, value: -offset, to: .now) ?? .now
            let label = date.formatted(.dateTime.weekday(.abbreviated))
            let count = last7.filter { cal.isDate($0.date, inSameDayAs: date) }
                .reduce(0) { $0 + $1.cardsReviewed }
            return (label, count)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        // Streak & retention
                        HStack(spacing: 12) {
                            MetricTile(
                                value: "\(appModel.streakDays)",
                                label: "Day Streak"
                            )
                            MetricTile(
                                value: appModel.retentionRate > 0
                                    ? "\(Int(appModel.retentionRate * 100))%"
                                    : "—",
                                label: "Retention"
                            )
                            MetricTile(
                                value: "\(appModel.sessions.count)",
                                label: "Sessions"
                            )
                        }

                        // 7-day chart
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Cards reviewed — last 7 days")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 4)

                            if chartData.allSatisfy({ $0.count == 0 }) {
                                Text("Complete a review session to see your chart.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.vertical, 32)
                                    .qmCard()
                            } else {
                                Chart {
                                    ForEach(chartData, id: \.day) { item in
                                        BarMark(
                                            x: .value("Day", item.day),
                                            y: .value("Cards", item.count)
                                        )
                                        .foregroundStyle(Color.qmAccent)
                                        .cornerRadius(6)
                                    }
                                }
                                .frame(height: 160)
                                .padding(16)
                                .background(Color.qmCard, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                            }
                        }

                        // Recent sessions list
                        if !appModel.sessions.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Recent sessions")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 4)
                                ForEach(appModel.sessions.prefix(15), id: \.date) { s in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(s.date.formatted(.dateTime.month().day().hour().minute()))
                                                .font(.subheadline)
                                                .foregroundStyle(.primary)
                                            Text("\(s.cardsReviewed) reviewed")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Text(s.cardsReviewed > 0
                                             ? "\(Int(Double(s.cardsCorrect)/Double(s.cardsReviewed)*100))%"
                                             : "—")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(Color.qmAccent)
                                    }
                                    .qmCard()
                                }
                            }
                        } else {
                            VStack(spacing: 12) {
                                Image(systemName: "chart.bar.xaxis")
                                    .font(.system(size: 40))
                                    .foregroundStyle(Color.qmAccent.opacity(0.7))
                                Text("No sessions yet")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text("Complete a review to see your history here.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.vertical, 40)
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
