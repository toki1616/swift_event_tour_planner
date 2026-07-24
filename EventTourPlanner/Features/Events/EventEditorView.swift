import SwiftUI

struct EventEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let viewModel: EventListViewModel

    @State private var title = ""
    @State private var venue = ""
    @State private var startDate = Date()

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
            .navigationTitle("イベントを登録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        if viewModel.addEvent(
                            title: title,
                            venue: venue,
                            startDate: startDate
                        ) {
                            dismiss()
                        }
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
