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
    @State private var scheduleDrafts: [TourScheduleDraft]
    @State private var isShowingScheduleEditor = false
    @State private var editingScheduleDraft: TourScheduleDraft?
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
        _scheduleDrafts = State(
            initialValue: tour?.scheduleItems
                .map {
                    TourScheduleDraft(
                        type: $0.type,
                        title: $0.title,
                        startDate: $0.startDate,
                        endDate: $0.endDate,
                        departureLocation: $0.departureLocation,
                        arrivalLocation: $0.arrivalLocation,
                        reservationNumber: $0.reservationNumber,
                        notes: $0.notes,
                        sourceItem: $0
                    )
                }
                .sorted { $0.startDate < $1.startDate } ?? []
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
                    ForEach(sortedScheduleDrafts) { draft in
                        Button {
                            editingScheduleDraft = draft
                        } label: {
                            HStack {
                                Label(
                                    draft.title,
                                    systemImage: draft.type.systemImage
                                )
                                .foregroundStyle(.primary)
                                Spacer()
                                Text(
                                    draft.startDate,
                                    format: .dateTime.month().day().hour().minute()
                                )
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .onDelete { offsets in
                        let drafts = sortedScheduleDrafts
                        let ids = offsets.map { drafts[$0].id }
                        scheduleDrafts.removeAll { ids.contains($0.id) }
                    }

                    Button {
                        isShowingScheduleEditor = true
                    } label: {
                        Label("予定を追加", systemImage: "plus.circle.fill")
                    }
                } header: {
                    Text("移動・宿泊")
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
            .sheet(isPresented: $isShowingScheduleEditor) {
                TourScheduleEditorView(
                    tourStartDate: startDate,
                    tourEndDate: endDate
                ) { draft in
                    scheduleDrafts.append(draft)
                    return true
                }
            }
            .sheet(item: $editingScheduleDraft) { draft in
                TourScheduleEditorView(
                    draft: draft,
                    tourStartDate: startDate,
                    tourEndDate: endDate,
                    onSave: { updatedDraft in
                        guard let index = scheduleDrafts.firstIndex(
                            where: { $0.id == draft.id }
                        ) else {
                            return false
                        }
                        scheduleDrafts[index].type = updatedDraft.type
                        scheduleDrafts[index].title = updatedDraft.title
                        scheduleDrafts[index].startDate = updatedDraft.startDate
                        scheduleDrafts[index].endDate = updatedDraft.endDate
                        scheduleDrafts[index].departureLocation = updatedDraft.departureLocation
                        scheduleDrafts[index].arrivalLocation = updatedDraft.arrivalLocation
                        scheduleDrafts[index].reservationNumber = updatedDraft.reservationNumber
                        scheduleDrafts[index].notes = updatedDraft.notes
                        return true
                    },
                    onDelete: {
                        scheduleDrafts.removeAll { $0.id == draft.id }
                    }
                )
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
                events: selectedEvents,
                scheduleItems: scheduleDrafts
            )
        }
        return viewModel.addTour(
            title: title,
            startDate: startDate,
            endDate: endDate,
            budget: budget ?? 0,
            notes: notes,
            events: selectedEvents,
            scheduleItems: scheduleDrafts
        )
    }

    private var sortedScheduleDrafts: [TourScheduleDraft] {
        scheduleDrafts.sorted { $0.startDate < $1.startDate }
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
