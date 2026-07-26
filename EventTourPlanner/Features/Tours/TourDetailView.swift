import SwiftUI

struct TourDetailView: View {
    let viewModel: TourListViewModel
    let eventViewModel: EventListViewModel
    let tour: TourPlan

    @State private var isShowingEditor = false
    @State private var isShowingScheduleEditor = false
    @State private var editingScheduleItem: TourScheduleItem?

    var body: some View {
        Form {
            Section("ツアー情報") {
                LabeledContent("ツアー名", value: tour.title)
                LabeledContent("期間") {
                    Text(
                        "\(tour.startDate.formatted(date: .abbreviated, time: .omitted))〜\(tour.endDate.formatted(date: .abbreviated, time: .omitted))"
                    )
                }
                if !tour.notes.isEmpty {
                    LabeledContent("メモ", value: tour.notes)
                }
            }

            if tour.budget > 0 || tour.totalExpense > 0 {
                Section("予算") {
                    if tour.budget > 0 {
                        LabeledContent("予算額") {
                            currencyText(tour.budget)
                        }
                    }
                    LabeledContent("支出済み") {
                        currencyText(tour.totalExpense)
                    }
                    if tour.budget > 0 {
                        LabeledContent("残額") {
                            currencyText(tour.remainingBudget)
                                .foregroundStyle(tour.remainingBudget < 0 ? .red : .primary)
                        }
                        ProgressView(value: min(tour.budgetUsageRate, 1))
                            .tint(tour.remainingBudget < 0 ? .red : .accentColor)
                        Text(
                            tour.budgetUsageRate,
                            format: .percent.precision(.fractionLength(0))
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
            }

            Section {
                if sortedScheduleItems.isEmpty {
                    Text("移動・宿泊予定はありません。")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(sortedScheduleItems) { item in
                        Button {
                            editingScheduleItem = item
                        } label: {
                            scheduleRow(item)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Button {
                    isShowingScheduleEditor = true
                } label: {
                    Label("予定を追加", systemImage: "plus.circle.fill")
                }
            } header: {
                Text("移動・宿泊")
            }

            Section("イベント") {
                if sortedEvents.isEmpty {
                    Text("紐付けられたイベントはありません。")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(sortedEvents) { event in
                        NavigationLink {
                            EventDetailView(
                                viewModel: eventViewModel,
                                event: event
                            )
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(event.title)
                                Text(
                                    event.startDate,
                                    format: .dateTime.year().month().day().hour().minute()
                                )
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                if event.totalExpense > 0 {
                                    currencyText(event.totalExpense)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("ツアー詳細")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("編集") {
                isShowingEditor = true
            }
        }
        .sheet(isPresented: $isShowingEditor) {
            TourEditorView(
                viewModel: viewModel,
                tour: tour,
                availableEvents: eventViewModel.events
            )
        }
        .sheet(isPresented: $isShowingScheduleEditor) {
            TourScheduleEditorView(
                viewModel: viewModel,
                tour: tour
            )
        }
        .sheet(item: $editingScheduleItem) { item in
            TourScheduleEditorView(
                viewModel: viewModel,
                tour: tour,
                item: item
            )
        }
    }

    private var sortedEvents: [LiveEvent] {
        tour.events.sorted { $0.startDate < $1.startDate }
    }

    private var sortedScheduleItems: [TourScheduleItem] {
        tour.scheduleItems.sorted { $0.startDate < $1.startDate }
    }

    private func scheduleRow(_ item: TourScheduleItem) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: item.type.systemImage)
                .foregroundStyle(.tint)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(scheduleDateText(for: item))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if item.type == .transportation {
                    let route = [item.departureLocation, item.arrivalLocation]
                        .filter { !$0.isEmpty }
                        .joined(separator: " → ")
                    if !route.isEmpty {
                        Text(route)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
    }

    private func scheduleDateText(for item: TourScheduleItem) -> String {
        let start = item.startDate.formatted(
            .dateTime.month().day().hour().minute()
        )
        let end = item.endDate.formatted(
            .dateTime.month().day().hour().minute()
        )
        return "\(start)〜\(end)"
    }

    private func currencyText(_ amount: Int) -> some View {
        Text(amount, format: .currency(code: currencyCode))
            .monospacedDigit()
    }

    private var currencyCode: String {
        Locale.autoupdatingCurrent.currency?.identifier ?? "JPY"
    }
}
