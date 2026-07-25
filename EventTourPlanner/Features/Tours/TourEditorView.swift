import SwiftUI

struct TourEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let viewModel: TourListViewModel
    let tour: TourPlan?

    @State private var title: String
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var budget: Int?
    @State private var notes: String
    @FocusState private var focusedField: Field?

    private enum Field {
        case title
        case budget
        case notes
    }

    init(viewModel: TourListViewModel, tour: TourPlan? = nil) {
        self.viewModel = viewModel
        self.tour = tour

        let defaultStartDate = tour?.startDate ?? Calendar.autoupdatingCurrent.startOfDay(for: Date())
        _title = State(initialValue: tour?.title ?? "")
        _startDate = State(initialValue: defaultStartDate)
        _endDate = State(initialValue: tour?.endDate ?? defaultStartDate)
        _budget = State(initialValue: tour.map(\.budget))
        _notes = State(initialValue: tour?.notes ?? "")
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
                notes: notes
            )
        }
        return viewModel.addTour(
            title: title,
            startDate: startDate,
            endDate: endDate,
            budget: budget ?? 0,
            notes: notes
        )
    }
}
