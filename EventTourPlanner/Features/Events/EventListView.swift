import SwiftUI

struct EventListView: View {
    let viewModel: EventListViewModel
    @State private var isShowingEditor = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.events.isEmpty {
                    ContentUnavailableView(
                        "イベントはありません",
                        systemImage: "calendar.badge.plus",
                        description: Text("これから参加するイベントを追加しましょう。")
                    )
                } else {
                    List(viewModel.events) { event in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(event.title)
                                .font(.headline)

                            Text(event.venue)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Text(event.startDate, format: .dateTime.year().month().day().hour().minute())
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("イベント")
            .toolbar {
                Button {
                    isShowingEditor = true
                } label: {
                    Label("イベントを追加", systemImage: "plus")
                }
            }
            .overlay(alignment: .bottom) {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .padding()
                }
            }
        }
        .task {
            viewModel.loadEvents()
        }
        .sheet(isPresented: $isShowingEditor) {
            EventEditorView(viewModel: viewModel)
        }
    }
}
