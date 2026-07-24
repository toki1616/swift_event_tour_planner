import SwiftUI

struct EventEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let viewModel: EventListViewModel
    let event: LiveEvent?

    @State private var title: String
    @State private var venue: String
    @State private var startDate: Date
    @State private var expenseName = ""
    @State private var expenseAmount: Int?

    init(
        viewModel: EventListViewModel,
        event: LiveEvent? = nil
    ) {
        self.viewModel = viewModel
        self.event = event
        _title = State(initialValue: event?.title ?? "")
        _venue = State(initialValue: event?.venue ?? "")
        _startDate = State(initialValue: event?.startDate ?? Date())
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("イベント情報") {
                    TextField("イベント名", text: $title)
                    TextField("会場", text: $venue)
                    DatePicker(
                        "開演日時",
                        selection: $startDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }

                if let event {
                    expenseSection(for: event)
                }
            }
            .navigationTitle(event == nil ? "イベントを登録" : "イベントを編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        if save() {
                            dismiss()
                        }
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func save() -> Bool {
        if let event {
            return viewModel.updateEvent(
                event,
                title: title,
                venue: venue,
                startDate: startDate
            )
        } else {
            return viewModel.addEvent(
                title: title,
                venue: venue,
                startDate: startDate
            )
        }
    }

    private func expenseSection(for event: LiveEvent) -> some View {
        Section {
            ForEach(sortedExpenses(for: event)) { expense in
                HStack {
                    Text(expense.name)

                    Spacer()

                    Text(expense.amount, format: .currency(code: currencyCode))
                        .monospacedDigit()
                }
            }
            .onDelete { offsets in
                let expenses = sortedExpenses(for: event)
                for index in offsets {
                    viewModel.deleteExpense(expenses[index])
                }
            }

            TextField("費用名", text: $expenseName)

            HStack {
                TextField(
                    "金額",
                    value: $expenseAmount,
                    format: .number
                )
                .keyboardType(.numberPad)

                Button {
                    addExpense(to: event)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
                .disabled(
                    expenseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        || (expenseAmount ?? 0) <= 0
                )
            }
        } header: {
            Text("費用")
        } footer: {
            HStack {
                Text("合計")
                Spacer()
                Text(event.totalExpense, format: .currency(code: currencyCode))
                    .fontWeight(.semibold)
                    .monospacedDigit()
            }
        }
    }

    private func sortedExpenses(for event: LiveEvent) -> [EventExpense] {
        event.expenses.sorted { $0.createdAt < $1.createdAt }
    }

    private func addExpense(to event: LiveEvent) {
        guard let amount = expenseAmount else { return }
        if viewModel.addExpense(name: expenseName, amount: amount, to: event) {
            expenseName = ""
            expenseAmount = nil
        }
    }

    private var currencyCode: String {
        Locale.autoupdatingCurrent.currency?.identifier ?? "JPY"
    }
}
