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
                    List {
                        ForEach(eventSections, id: \.date) { section in
                            Section {
                                ForEach(section.events) { event in
                                    NavigationLink {
                                        EventDetailView(
                                            viewModel: viewModel,
                                            event: event
                                        )
                                    } label: {
                                        eventRow(event)
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
                            } header: {
                                Text(
                                    section.date,
                                    format: .dateTime
                                        .year()
                                        .month(.wide)
                                        .day()
                                        .weekday(.wide)
                                )
                                .font(.headline)
                                .foregroundStyle(.primary)
                                .textCase(nil)
                            }
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

    private var eventSections: [(date: Date, events: [LiveEvent])] {
        let calendar = Calendar.autoupdatingCurrent
        let groupedEvents = Dictionary(
            grouping: viewModel.events,
            by: { calendar.startOfDay(for: $0.startDate) }
        )

        return groupedEvents
            .map { date, events in
                (
                    date: date,
                    events: events.sorted { $0.startDate < $1.startDate }
                )
            }
            .sorted { $0.date < $1.date }
    }

    private func eventRow(_ event: LiveEvent) -> some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 3) {
                if let meetupDate = event.meetupDate {
                    timeLabel("集合", date: meetupDate)
                }
                timeLabel("開演", date: event.startDate)
            }
            .frame(minWidth: 76, alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.headline)

                if !event.venue.isEmpty {
                    Label(event.venue, systemImage: "mappin.and.ellipse")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if event.budget > 0 {
                    ProgressView(value: min(event.budgetUsageRate, 1))
                        .tint(event.totalExpense > event.budget ? .red : .accentColor)

                    Label {
                        Text(
                            "\(event.totalExpense.formatted(.currency(code: currencyCode))) / \(event.budget.formatted(.currency(code: currencyCode)))"
                        )
                    } icon: {
                        Image(systemName: "chart.pie")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                } else if !event.expenses.isEmpty {
                    Label {
                        Text(event.totalExpense, format: .currency(code: currencyCode))
                            .monospacedDigit()
                    } icon: {
                        Image(systemName: "chart.pie")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func timeLabel(_ title: LocalizedStringKey, date: Date) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(date, format: .dateTime.hour().minute())
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.primary)
        }
    }

    private var currencyCode: String {
        Locale.autoupdatingCurrent.currency?.identifier ?? "JPY"
    }

}
