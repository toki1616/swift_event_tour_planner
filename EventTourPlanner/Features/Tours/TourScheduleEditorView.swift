import SwiftUI

struct TourScheduleEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let viewModel: TourListViewModel?
    let tour: TourPlan?
    let item: TourScheduleItem?
    let tourStartDate: Date
    let tourEndDate: Date
    let onDraftSave: ((TourScheduleDraft) -> Bool)?
    let onDraftDelete: (() -> Void)?

    @State private var type: TourScheduleType
    @State private var title: String
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var departureLocation: String
    @State private var arrivalLocation: String
    @State private var reservationNumber: String
    @State private var notes: String
    @State private var isShowingDeleteConfirmation = false
    @FocusState private var focusedField: Field?

    private enum Field {
        case title
        case departureLocation
        case arrivalLocation
        case reservationNumber
        case notes
    }

    init(
        viewModel: TourListViewModel,
        tour: TourPlan,
        item: TourScheduleItem? = nil
    ) {
        self.viewModel = viewModel
        self.tour = tour
        self.item = item
        self.tourStartDate = tour.startDate
        self.tourEndDate = tour.endDate
        self.onDraftSave = nil
        self.onDraftDelete = nil

        let tourEndLimit = Calendar.autoupdatingCurrent.date(
            bySettingHour: 23,
            minute: 59,
            second: 59,
            of: tour.endDate
        ) ?? tour.endDate
        let defaultDate = item?.startDate
            ?? min(max(tour.startDate, Date()), tourEndLimit)
        _type = State(initialValue: item?.type ?? .transportation)
        _title = State(initialValue: item?.title ?? "")
        _startDate = State(initialValue: defaultDate)
        _endDate = State(initialValue: item?.endDate ?? defaultDate)
        _departureLocation = State(initialValue: item?.departureLocation ?? "")
        _arrivalLocation = State(initialValue: item?.arrivalLocation ?? "")
        _reservationNumber = State(initialValue: item?.reservationNumber ?? "")
        _notes = State(initialValue: item?.notes ?? "")
    }

    init(
        draft: TourScheduleDraft? = nil,
        tourStartDate: Date,
        tourEndDate: Date,
        onSave: @escaping (TourScheduleDraft) -> Bool,
        onDelete: (() -> Void)? = nil
    ) {
        viewModel = nil
        tour = nil
        item = nil
        self.tourStartDate = tourStartDate
        self.tourEndDate = tourEndDate
        onDraftSave = onSave
        onDraftDelete = onDelete

        let endLimit = Calendar.autoupdatingCurrent.date(
            bySettingHour: 23,
            minute: 59,
            second: 59,
            of: tourEndDate
        ) ?? tourEndDate
        let defaultDate = draft?.startDate
            ?? min(max(tourStartDate, Date()), endLimit)
        _type = State(initialValue: draft?.type ?? .transportation)
        _title = State(initialValue: draft?.title ?? "")
        _startDate = State(initialValue: defaultDate)
        _endDate = State(initialValue: draft?.endDate ?? defaultDate)
        _departureLocation = State(initialValue: draft?.departureLocation ?? "")
        _arrivalLocation = State(initialValue: draft?.arrivalLocation ?? "")
        _reservationNumber = State(initialValue: draft?.reservationNumber ?? "")
        _notes = State(initialValue: draft?.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("種類") {
                    Picker("種類", selection: $type) {
                        ForEach(TourScheduleType.allCases) { type in
                            Label(type.title, systemImage: type.systemImage)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section(type == .transportation ? "移動情報" : "宿泊情報") {
                    TextField(titlePlaceholder, text: $title)
                        .focused($focusedField, equals: .title)
                        .submitLabel(.done)

                    DatePicker(
                        startDateTitle,
                        selection: $startDate,
                        in: tourStartDate...tourEndLimit
                    )
                    DatePicker(
                        endDateTitle,
                        selection: $endDate,
                        in: startDate...tourEndLimit
                    )

                    if type == .transportation {
                        TextField("出発地（任意）", text: $departureLocation)
                            .focused($focusedField, equals: .departureLocation)
                        TextField("到着地（任意）", text: $arrivalLocation)
                            .focused($focusedField, equals: .arrivalLocation)
                    }
                }

                Section("予約情報") {
                    TextField("予約番号（任意）", text: $reservationNumber)
                        .textInputAutocapitalization(.characters)
                        .focused($focusedField, equals: .reservationNumber)
                    TextField("メモ（任意）", text: $notes, axis: .vertical)
                        .lineLimit(3...8)
                        .focused($focusedField, equals: .notes)
                }

                if item != nil || onDraftDelete != nil {
                    Section {
                        Button("削除", role: .destructive) {
                            isShowingDeleteConfirmation = true
                        }
                    }
                }
            }
            .navigationTitle(item == nil ? "予定を追加" : "予定を編集")
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
                    get: { viewModel?.errorMessage != nil },
                    set: { if !$0 { viewModel?.clearError() } }
                )
            ) {
                Button("OK") {
                    viewModel?.clearError()
                }
            } message: {
                Text(viewModel?.errorMessage ?? "")
            }
            .confirmationDialog(
                "この予定を削除しますか？",
                isPresented: $isShowingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("削除", role: .destructive) {
                    if let item {
                        viewModel?.deleteScheduleItem(item)
                    } else {
                        onDraftDelete?()
                    }
                    dismiss()
                }
                Button("キャンセル", role: .cancel) {}
            }
        }
    }

    private var tourEndLimit: Date {
        Calendar.autoupdatingCurrent.date(
            bySettingHour: 23,
            minute: 59,
            second: 59,
            of: tourEndDate
        ) ?? tourEndDate
    }

    private var titlePlaceholder: LocalizedStringKey {
        type == .transportation ? "交通手段・便名" : "宿泊施設名"
    }

    private var startDateTitle: LocalizedStringKey {
        type == .transportation ? "出発日時" : "チェックイン"
    }

    private var endDateTitle: LocalizedStringKey {
        type == .transportation ? "到着日時" : "チェックアウト"
    }

    private func save() -> Bool {
        if let onDraftSave {
            return onDraftSave(
                TourScheduleDraft(
                    type: type,
                    title: title,
                    startDate: startDate,
                    endDate: endDate,
                    departureLocation: departureLocation,
                    arrivalLocation: arrivalLocation,
                    reservationNumber: reservationNumber,
                    notes: notes
                )
            )
        }
        if let item, let viewModel {
            return viewModel.updateScheduleItem(
                item,
                type: type,
                title: title,
                startDate: startDate,
                endDate: endDate,
                departureLocation: departureLocation,
                arrivalLocation: arrivalLocation,
                reservationNumber: reservationNumber,
                notes: notes
            )
        }
        guard let viewModel, let tour else { return false }
        return viewModel.addScheduleItem(
            to: tour,
            type: type,
            title: title,
            startDate: startDate,
            endDate: endDate,
            departureLocation: departureLocation,
            arrivalLocation: arrivalLocation,
            reservationNumber: reservationNumber,
            notes: notes
        )
    }
}
