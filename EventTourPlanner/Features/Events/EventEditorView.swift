import SwiftUI

struct EventEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let viewModel: EventListViewModel
    let event: LiveEvent?

    @State private var title: String
    @State private var venue: String
    @State private var startDate: Date

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
}
