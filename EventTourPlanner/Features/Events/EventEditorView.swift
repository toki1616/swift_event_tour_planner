import SwiftUI
import Charts

struct EventEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let viewModel: EventListViewModel
    let event: LiveEvent?

    @State private var title: String
    @State private var venue: String
    @State private var eventType: EventType
    @State private var meetupDate: Date
    @State private var doorsOpenDate: Date
    @State private var startDate: Date
    @State private var scheduledEndDate: Date
    @State private var budget: Int?
    @State private var isShowingExpenseEditor = false
    @State private var editingExpense: EventExpense?
    @State private var isMeetupDateCustomized: Bool
    @State private var isDoorsOpenDateCustomized: Bool
    @State private var isScheduledEndDateCustomized: Bool
    @FocusState private var focusedField: Field?

    private enum Field {
        case title
        case venue
        case budget
    }

    init(
        viewModel: EventListViewModel,
        event: LiveEvent? = nil
    ) {
        self.viewModel = viewModel
        self.event = event
        let startDate = event?.startDate ?? Date()
        let eventType = event?.eventType ?? .live
        let defaultMeetupDate = eventType.defaultMeetupDate(for: startDate)
        let defaultDoorsOpenDate = eventType.defaultDoorsOpenDate(for: startDate)
        let defaultScheduledEndDate = eventType.defaultScheduledEndDate(for: startDate)
        _title = State(initialValue: event?.title ?? "")
        _venue = State(initialValue: event?.venue ?? "")
        _eventType = State(initialValue: eventType)
        _meetupDate = State(
            initialValue: event?.meetupDate ?? defaultMeetupDate
        )
        _doorsOpenDate = State(
            initialValue: event?.doorsOpenDate ?? defaultDoorsOpenDate
        )
        _startDate = State(initialValue: startDate)
        _scheduledEndDate = State(
            initialValue: event?.scheduledEndDate ?? defaultScheduledEndDate
        )
        _isMeetupDateCustomized = State(
            initialValue: event?.meetupDate.map { $0 != defaultMeetupDate } ?? false
        )
        _isDoorsOpenDateCustomized = State(
            initialValue: event?.doorsOpenDate.map { $0 != defaultDoorsOpenDate } ?? false
        )
        _isScheduledEndDateCustomized = State(
            initialValue: event?.scheduledEndDate.map { $0 != defaultScheduledEndDate } ?? false
        )
        _budget = State(initialValue: event.map(\.budget))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("イベント情報") {
                    TextField("イベント名", text: $title)
                        .focused($focusedField, equals: .title)
                        .submitLabel(.done)
                    TextField("会場", text: $venue)
                        .focused($focusedField, equals: .venue)
                        .submitLabel(.done)
                    Picker("種類", selection: $eventType) {
                        ForEach(EventType.allCases) { eventType in
                            Text(eventType.title)
                                .tag(eventType)
                        }
                    }
                }

                Section("時間") {
                    eventDatePicker("集合時間", selection: meetupDateBinding)
                    eventDatePicker("開場時間", selection: doorsOpenDateBinding)
                    eventDatePicker("開演時間", selection: startDateBinding)
                    eventDatePicker("終演予定時間", selection: scheduledEndDateBinding)

                    Button("標準時間に戻す") {
                        applyDefaultSchedule()
                    }
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
            .keyboardDoneButton(focusedField: $focusedField)
            .sheet(isPresented: $isShowingExpenseEditor) {
                if let event {
                    ExpenseEditorView { name, amount, category in
                        viewModel.addExpense(
                            name: name,
                            amount: amount,
                            category: category,
                            to: event
                        )
                    }
                }
            }
            .sheet(item: $editingExpense) { expense in
                ExpenseEditorView(
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
                eventType: eventType,
                meetupDate: meetupDate,
                doorsOpenDate: doorsOpenDate,
                startDate: startDate,
                scheduledEndDate: scheduledEndDate,
                budget: budget ?? 0
            )
        } else {
            return viewModel.addEvent(
                title: title,
                venue: venue,
                eventType: eventType,
                meetupDate: meetupDate,
                doorsOpenDate: doorsOpenDate,
                startDate: startDate,
                scheduledEndDate: scheduledEndDate,
                budget: budget ?? 0
            )
        }
    }

    private var meetupDateBinding: Binding<Date> {
        Binding(
            get: { meetupDate },
            set: {
                meetupDate = $0
                isMeetupDateCustomized = true
            }
        )
    }

    private var doorsOpenDateBinding: Binding<Date> {
        Binding(
            get: { doorsOpenDate },
            set: {
                doorsOpenDate = $0
                isDoorsOpenDateCustomized = true
            }
        )
    }

    private var startDateBinding: Binding<Date> {
        Binding(
            get: { startDate },
            set: { newStartDate in
                startDate = newStartDate
                applyAutomaticSchedule()
            }
        )
    }

    private var scheduledEndDateBinding: Binding<Date> {
        Binding(
            get: { scheduledEndDate },
            set: {
                scheduledEndDate = $0
                isScheduledEndDateCustomized = true
            }
        )
    }

    private func applyAutomaticSchedule() {
        if !isMeetupDateCustomized {
            meetupDate = eventType.defaultMeetupDate(for: startDate)
        }
        if !isDoorsOpenDateCustomized {
            doorsOpenDate = eventType.defaultDoorsOpenDate(for: startDate)
        }
        if !isScheduledEndDateCustomized {
            scheduledEndDate = eventType.defaultScheduledEndDate(for: startDate)
        }
    }

    private func applyDefaultSchedule() {
        isMeetupDateCustomized = false
        isDoorsOpenDateCustomized = false
        isScheduledEndDateCustomized = false
        applyAutomaticSchedule()
    }

    private func eventDatePicker(
        _ title: LocalizedStringKey,
        selection: Binding<Date>
    ) -> some View {
        DatePicker(
            title,
            selection: selection,
            displayedComponents: [.date, .hourAndMinute]
        )
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

            Button {
                isShowingExpenseEditor = true
            } label: {
                Label("費用を追加", systemImage: "plus.circle.fill")
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

    private var budgetSection: some View {
        Section("予算") {
            TextField("予算額", value: $budget, format: .number)
                .keyboardType(.numberPad)
                .focused($focusedField, equals: .budget)

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
