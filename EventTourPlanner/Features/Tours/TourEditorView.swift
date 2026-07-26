import SwiftUI
import SwiftData

struct TourEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let viewModel: TourListViewModel
    let tour: TourPlan?
    let availableEvents: [LiveEvent]

    @State private var title: String
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var budget: Int?
    @State private var notes: String
    @State private var selectedEventIDs: Set<PersistentIdentifier>
    @FocusState private var focusedField: Field?

    private enum Field {
        case title
        case budget
        case notes
    }

    init(
        viewModel: TourListViewModel,
        tour: TourPlan? = nil,
        availableEvents: [LiveEvent]
    ) {
        self.viewModel = viewModel
        self.tour = tour
        self.availableEvents = availableEvents

        let defaultStartDate = tour?.startDate ?? Calendar.autoupdatingCurrent.startOfDay(for: Date())
        _title = State(initialValue: tour?.title ?? "")
        _startDate = State(initialValue: defaultStartDate)
        _endDate = State(initialValue: tour?.endDate ?? defaultStartDate)
        _budget = State(initialValue: tour.map(\.budget))
        _notes = State(initialValue: tour?.notes ?? "")
        _selectedEventIDs = State(
            initialValue: Set(tour?.events.map(\.persistentModelID) ?? [])
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("ツアー情報") {
                    TextField("ツアー名", text: $title)
                        .focused($focusedField, equals: .title)
                        .submitLabel(.done)

                    DatePicker(
                        "開始日",
                        selection: $startDate,
                        displayedComponents: .date
                    )
                    DatePicker(
                        "終了日",
                        selection: $endDate,
                        in: startDate...,
                        displayedComponents: .date
                    )
                }

                Section("予算") {
                    TextField("予算額", value: $budget, format: .number)
                        .keyboardType(.numberPad)
                        .focused($focusedField, equals: .budget)
                }

                Section("メモ") {
                    TextField("移動や宿泊などのメモ（任意）", text: $notes, axis: .vertical)
                        .lineLimit(3...8)
                        .focused($focusedField, equals: .notes)
                }

                Section {
                    if selectableEvents.isEmpty {
                        Text("ツアー期間内のイベントがありません。")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(selectableEvents) { event in
                            Button {
                                toggleSelection(of: event)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(event.title)
                                            .foregroundStyle(.primary)
                                        Text(
                                            event.startDate,
                                            format: .dateTime.year().month().day()
                                        )
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if selectedEventIDs.contains(event.persistentModelID) {
                                        Image(systemName: "checkmark")
                                            .fontWeight(.semibold)
                                    }
                                }
                            }
                        }
                    }
                } header: {
                    Text("イベント")
                } footer: {
                    Text("別のツアーに登録済みのイベントは選択できません。")
                }
            }
            .navigationTitle(tour == nil ? "ツアーを登録" : "ツアーを編集")
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
            .alert(
                "保存できません",
                isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { if !$0 { viewModel.clearError() } }
                )
            ) {
                Button("OK") {
                    viewModel.clearError()
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    private func save() -> Bool {
        if let tour {
            return viewModel.updateTour(
                tour,
                title: title,
                startDate: startDate,
                endDate: endDate,
                budget: budget ?? 0,
                notes: notes,
                events: selectedEvents
            )
        }
        return viewModel.addTour(
            title: title,
            startDate: startDate,
            endDate: endDate,
            budget: budget ?? 0,
            notes: notes,
            events: selectedEvents
        )
    }

    private var selectableEvents: [LiveEvent] {
        availableEvents
            .filter { $0.tour == nil || $0.tour === tour }
            .filter { isWithinTourPeriod($0.startDate) }
            .sorted { $0.startDate < $1.startDate }
    }

    private var selectedEvents: [LiveEvent] {
        selectableEvents.filter {
            selectedEventIDs.contains($0.persistentModelID)
        }
    }

    private func toggleSelection(of event: LiveEvent) {
        if selectedEventIDs.contains(event.persistentModelID) {
            selectedEventIDs.remove(event.persistentModelID)
        } else {
            selectedEventIDs.insert(event.persistentModelID)
        }
    }

    private func isWithinTourPeriod(_ date: Date) -> Bool {
        let calendar = Calendar.autoupdatingCurrent
        let firstDay = calendar.startOfDay(for: startDate)
        guard let dayAfterLast = calendar.date(
            byAdding: .day,
            value: 1,
            to: calendar.startOfDay(for: endDate)
        ) else {
            return false
        }
        return firstDay <= date && date < dayAfterLast
    }
}
