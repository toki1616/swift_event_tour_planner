import SwiftUI

struct TourListView: View {
    let viewModel: TourListViewModel
    let eventViewModel: EventListViewModel

    @State private var isShowingEditor = false
    @State private var editingTour: TourPlan?
    @State private var tourPendingDeletion: TourPlan?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.tours.isEmpty {
                    ContentUnavailableView(
                        "ツアーはありません",
                        systemImage: "suitcase.rolling",
                        description: Text("複数のイベントをまとめるツアーを追加しましょう。")
                    )
                } else {
                    List(viewModel.tours) { tour in
                        NavigationLink {
                            TourDetailView(
                                eventViewModel: eventViewModel,
                                tour: tour
                            )
                        } label: {
                            tourRow(tour)
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                tourPendingDeletion = tour
                            } label: {
                                Label("削除", systemImage: "trash")
                            }

                            Button {
                                editingTour = tour
                            } label: {
                                Label("編集", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                    }
                }
            }
            .navigationTitle("ツアー")
            .toolbar {
                Button {
                    isShowingEditor = true
                } label: {
                    Label("ツアーを追加", systemImage: "plus")
                }
            }
        }
        .task {
            viewModel.loadTours()
            eventViewModel.loadEvents()
        }
        .sheet(isPresented: $isShowingEditor) {
            TourEditorView(
                viewModel: viewModel,
                availableEvents: eventViewModel.events
            )
        }
        .sheet(item: $editingTour) { tour in
            TourEditorView(
                viewModel: viewModel,
                tour: tour,
                availableEvents: eventViewModel.events
            )
        }
        .confirmationDialog(
            "「\(tourPendingDeletion?.title ?? "")」を削除しますか？",
            isPresented: Binding(
                get: { tourPendingDeletion != nil },
                set: { if !$0 { tourPendingDeletion = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("削除", role: .destructive) {
                if let tourPendingDeletion {
                    viewModel.deleteTour(tourPendingDeletion)
                }
                tourPendingDeletion = nil
            }
            Button("キャンセル", role: .cancel) {
                tourPendingDeletion = nil
            }
        } message: {
            Text("ツアーを削除してもイベントは削除されません。")
        }
        .alert(
            "エラー",
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

    private func tourRow(_ tour: TourPlan) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(tour.title)
                .font(.headline)
            Text(
                "\(tour.startDate.formatted(date: .abbreviated, time: .omitted))〜\(tour.endDate.formatted(date: .abbreviated, time: .omitted))"
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
