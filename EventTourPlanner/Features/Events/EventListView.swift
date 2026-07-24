import SwiftUI

struct EventListView: View {
    let viewModel: EventListViewModel
    @State private var isShowingEditor = false
    @State private var editingEvent: LiveEvent?
    @State private var eventPendingDeletion: LiveEvent?

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
                        .contentShape(Rectangle())
                        .onTapGesture {
                            editingEvent = event
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                eventPendingDeletion = event
                            } label: {
                                Label("削除", systemImage: "trash")
                            }

                            Button {
                                editingEvent = event
                            } label: {
                                Label("編集", systemImage: "pencil")
                            }
                            .tint(.blue)
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
        .sheet(item: $editingEvent) { event in
            EventEditorView(viewModel: viewModel, event: event)
        }
        .confirmationDialog(
            deleteConfirmationTitle,
            isPresented: isShowingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("削除", role: .destructive) {
                if let event = eventPendingDeletion {
                    viewModel.deleteEvent(event)
                }
                eventPendingDeletion = nil
            }

            Button("キャンセル", role: .cancel) {
                eventPendingDeletion = nil
            }
        } message: {
            Text("削除したイベントは元に戻せません。")
        }
    }

    private var isShowingDeleteConfirmation: Binding<Bool> {
        Binding(
            get: { eventPendingDeletion != nil },
            set: { isPresented in
                if !isPresented {
                    eventPendingDeletion = nil
                }
            }
        )
    }

    private var deleteConfirmationTitle: String {
        String(
            format: String(localized: "delete.confirmation_format"),
            locale: .autoupdatingCurrent,
            eventPendingDeletion?.title ?? ""
        )
    }

}
