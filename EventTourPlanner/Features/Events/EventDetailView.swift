import SwiftUI

struct EventDetailView: View {
    let viewModel: EventListViewModel
    let event: LiveEvent

    @State private var isShowingEditor = false

    var body: some View {
        Form {
            Section("イベント情報") {
                LabeledContent("イベント名", value: event.title)
                if !event.venue.isEmpty {
                    LabeledContent("会場", value: event.venue)
                }
                LabeledContent("種類", value: event.eventType.title)
            }

            Section("時間") {
                if let meetupDate = event.meetupDate {
                    dateRow("集合時間", date: meetupDate)
                }
                if let doorsOpenDate = event.doorsOpenDate {
                    dateRow("開場時間", date: doorsOpenDate)
                }
                dateRow("開演時間", date: event.startDate)
                if let scheduledEndDate = event.scheduledEndDate {
                    dateRow("終演予定時間", date: scheduledEndDate)
                }
            }

            if websiteURL != nil || electronicTicketURL != nil {
                Section("リンク") {
                    if let websiteURL {
                        Link(destination: websiteURL) {
                            Label("サイトを開く", systemImage: "safari")
                        }
                    }
                    if let electronicTicketURL {
                        Link(destination: electronicTicketURL) {
                            Label("電子チケットを開く", systemImage: "ticket")
                        }
                    }
                }
            }

            if event.budget > 0 || !event.expenses.isEmpty {
                Section("予算") {
                    if event.budget > 0 {
                        LabeledContent("予算額") {
                            currencyText(event.budget)
                        }
                        LabeledContent("支出済み") {
                            currencyText(event.totalExpense)
                        }
                        LabeledContent("残額") {
                            currencyText(event.remainingBudget)
                                .foregroundStyle(event.remainingBudget < 0 ? .red : .primary)
                        }
                        ProgressView(value: min(event.budgetUsageRate, 1))
                            .tint(event.remainingBudget < 0 ? .red : .accentColor)
                    }
                }
            }

            if !event.expenses.isEmpty {
                Section {
                    ForEach(sortedExpenses) { expense in
                        HStack {
                            Label(
                                expense.name.isEmpty ? expense.category.title : expense.name,
                                systemImage: expense.category.systemImage
                            )
                            Spacer()
                            currencyText(expense.amount)
                        }
                    }
                } header: {
                    Text("費用")
                } footer: {
                    HStack {
                        Text("合計")
                        Spacer()
                        currencyText(event.totalExpense)
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .navigationTitle("イベント詳細")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("編集") {
                isShowingEditor = true
            }
        }
        .sheet(isPresented: $isShowingEditor) {
            EventEditorView(viewModel: viewModel, event: event)
        }
    }

    private func dateRow(_ title: LocalizedStringKey, date: Date) -> some View {
        LabeledContent {
            Text(
                date,
                format: .dateTime
                    .year()
                    .month()
                    .day()
                    .hour()
                    .minute()
            )
        } label: {
            Text(title)
        }
    }

    private func currencyText(_ amount: Int) -> some View {
        Text(amount, format: .currency(code: currencyCode))
            .monospacedDigit()
    }

    private var sortedExpenses: [EventExpense] {
        event.expenses.sorted { $0.createdAt < $1.createdAt }
    }

    private var websiteURL: URL? {
        normalizedURL(from: event.websiteURL)
    }

    private var electronicTicketURL: URL? {
        normalizedURL(from: event.electronicTicketURL)
    }

    private func normalizedURL(from input: String) -> URL? {
        let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInput.isEmpty else { return nil }
        let urlString = trimmedInput.contains("://")
            ? trimmedInput
            : "https://\(trimmedInput)"
        guard
            let components = URLComponents(string: urlString),
            ["http", "https"].contains(components.scheme?.lowercased() ?? ""),
            components.host != nil
        else {
            return nil
        }
        return components.url
    }

    private var currencyCode: String {
        Locale.autoupdatingCurrent.currency?.identifier ?? "JPY"
    }
}
