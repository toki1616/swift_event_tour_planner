import SwiftUI
import Charts

struct EventEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let viewModel: EventListViewModel
    let event: LiveEvent?

    @State private var title: String
    @State private var venue: String
    @State private var startDate: Date
    @State private var budget: Int?
    @State private var expenseName = ""
    @State private var expenseAmount: Int?
    @State private var expenseCategory = ExpenseCategory.ticket
    @State private var editingExpense: EventExpense?

    init(
        viewModel: EventListViewModel,
        event: LiveEvent? = nil
    ) {
        self.viewModel = viewModel
        self.event = event
        _title = State(initialValue: event?.title ?? "")
        _venue = State(initialValue: event?.venue ?? "")
        _startDate = State(initialValue: event?.startDate ?? Date())
        _budget = State(initialValue: event.map(\.budget))
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

                budgetSection

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
            .sheet(item: $editingExpense) { expense in
                ExpenseEditorSheet(
                    expense: expense,
                    onSave: { name, amount, category in
                        viewModel.updateExpense(
                            expense,
                            name: name,
                            amount: amount,
                            category: category
                        )
                    },
                    onDelete: {
                        viewModel.deleteExpense(expense)
                    }
                )
            }
        }
    }

    private func save() -> Bool {
        if let event {
            return viewModel.updateEvent(
                event,
                title: title,
                venue: venue,
                startDate: startDate,
                budget: budget ?? 0
            )
        } else {
            return viewModel.addEvent(
                title: title,
                venue: venue,
                startDate: startDate,
                budget: budget ?? 0
            )
        }
    }

    private func expenseSection(for event: LiveEvent) -> some View {
        Section {
            if !event.expenses.isEmpty {
                expenseChart(for: event)
                    .frame(height: 220)
                    .listRowInsets(EdgeInsets())
                    .padding()
            }

            ForEach(sortedExpenses(for: event)) { expense in
                Button {
                    editingExpense = expense
                } label: {
                    HStack {
                        Label(
                            expense.name.isEmpty ? expense.category.title : expense.name,
                            systemImage: expense.category.systemImage
                        )

                        Spacer()

                        Text(expense.amount, format: .currency(code: currencyCode))
                            .monospacedDigit()
                            .foregroundStyle(.primary)

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)
            }
            .onDelete { offsets in
                let expenses = sortedExpenses(for: event)
                for index in offsets {
                    viewModel.deleteExpense(expenses[index])
                }
            }

            Picker("カテゴリ", selection: $expenseCategory) {
                ForEach(ExpenseCategory.allCases) { category in
                    Label(category.title, systemImage: category.systemImage)
                        .tag(category)
                }
            }

            TextField("費用名（任意）", text: $expenseName)

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
                .disabled((expenseAmount ?? 0) <= 0)
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
        if viewModel.addExpense(
            name: expenseName,
            amount: amount,
            category: expenseCategory,
            to: event
        ) {
            expenseName = ""
            expenseAmount = nil
        }
    }

    private var budgetSection: some View {
        Section("予算") {
            TextField("予算額", value: $budget, format: .number)
                .keyboardType(.numberPad)

            if let event, (budget ?? 0) > 0 {
                LabeledContent("支出済み") {
                    Text(event.totalExpense, format: .currency(code: currencyCode))
                        .monospacedDigit()
                }

                LabeledContent("残額") {
                    Text(
                        (budget ?? 0) - event.totalExpense,
                        format: .currency(code: currencyCode)
                    )
                    .monospacedDigit()
                    .foregroundStyle(event.totalExpense > (budget ?? 0) ? .red : .primary)
                }

                ProgressView(value: usageRate(for: event))
                    .tint(event.totalExpense > (budget ?? 0) ? .red : .accentColor)

                Text(usageRate(for: event), format: .percent.precision(.fractionLength(0)))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func expenseChart(for event: LiveEvent) -> some View {
        Chart(expenseSummaries(for: event)) { summary in
            SectorMark(
                angle: .value("金額", summary.amount),
                innerRadius: .ratio(0.58),
                angularInset: 2
            )
            .foregroundStyle(by: .value("カテゴリ", summary.category.title))
        }
        .chartLegend(position: .bottom, alignment: .center, spacing: 8)
        .accessibilityLabel("費用の内訳")
    }

    private func expenseSummaries(for event: LiveEvent) -> [ExpenseSummary] {
        Dictionary(grouping: event.expenses, by: \.category)
            .map { category, expenses in
                ExpenseSummary(
                    category: category,
                    amount: expenses.reduce(0) { $0 + $1.amount }
                )
            }
            .sorted { $0.category.rawValue < $1.category.rawValue }
    }

    private func usageRate(for event: LiveEvent) -> Double {
        guard (budget ?? 0) > 0 else { return 0 }
        return Double(event.totalExpense) / Double(budget ?? 0)
    }

    private var currencyCode: String {
        Locale.autoupdatingCurrent.currency?.identifier ?? "JPY"
    }

    private struct ExpenseSummary: Identifiable {
        let category: ExpenseCategory
        let amount: Int

        var id: ExpenseCategory { category }
    }
}

private struct ExpenseEditorSheet: View {
    @Environment(\.dismiss) private var dismiss

    let expense: EventExpense
    let onSave: (String, Int, ExpenseCategory) -> Bool
    let onDelete: () -> Void

    @State private var name: String
    @State private var amount: Int?
    @State private var category: ExpenseCategory
    @State private var isShowingDeleteConfirmation = false

    init(
        expense: EventExpense,
        onSave: @escaping (String, Int, ExpenseCategory) -> Bool,
        onDelete: @escaping () -> Void
    ) {
        self.expense = expense
        self.onSave = onSave
        self.onDelete = onDelete
        _name = State(initialValue: expense.name)
        _amount = State(initialValue: expense.amount)
        _category = State(initialValue: expense.category)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("費用") {
                    Picker("カテゴリ", selection: $category) {
                        ForEach(ExpenseCategory.allCases) { category in
                            Label(category.title, systemImage: category.systemImage)
                                .tag(category)
                        }
                    }

                    TextField("費用名（任意）", text: $name)
                    TextField("金額", value: $amount, format: .number)
                        .keyboardType(.numberPad)
                }

                Section {
                    Button("削除", role: .destructive) {
                        isShowingDeleteConfirmation = true
                    }
                }
            }
            .navigationTitle("費用を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        guard let amount else { return }
                        if onSave(name, amount, category) {
                            dismiss()
                        }
                    }
                    .disabled((amount ?? 0) <= 0)
                }
            }
            .confirmationDialog(
                "この費用を削除しますか？",
                isPresented: $isShowingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("削除", role: .destructive) {
                    onDelete()
                    dismiss()
                }
                Button("キャンセル", role: .cancel) {}
            }
        }
    }
}
