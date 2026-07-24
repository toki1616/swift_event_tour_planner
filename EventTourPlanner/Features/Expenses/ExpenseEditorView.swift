import SwiftUI

struct ExpenseEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let expense: EventExpense?
    let onSave: (String, Int, ExpenseCategory) -> Bool
    let onDelete: (() -> Void)?

    @State private var name: String
    @State private var amount: Int?
    @State private var category: ExpenseCategory
    @State private var isShowingDeleteConfirmation = false
    @FocusState private var focusedField: Field?

    private enum Field {
        case name
        case amount
    }

    init(
        expense: EventExpense? = nil,
        onSave: @escaping (String, Int, ExpenseCategory) -> Bool,
        onDelete: (() -> Void)? = nil
    ) {
        self.expense = expense
        self.onSave = onSave
        self.onDelete = onDelete
        _name = State(initialValue: expense?.name ?? "")
        _amount = State(initialValue: expense?.amount)
        _category = State(initialValue: expense?.category ?? .ticket)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("費用") {
                    Picker("カテゴリ", selection: $category) {
                        ForEach(ExpenseCategory.allCases) { category in
                            Label(category.title, systemImage: category.systemImage)
                                .tag(category)
                        }
                    }

                    TextField("費用名（任意）", text: $name)
                        .focused($focusedField, equals: .name)
                        .submitLabel(.done)

                    TextField("金額", value: $amount, format: .number)
                        .keyboardType(.numberPad)
                        .focused($focusedField, equals: .amount)
                }

                if onDelete != nil {
                    Section {
                        Button("削除", role: .destructive) {
                            isShowingDeleteConfirmation = true
                        }
                    }
                }
            }
            .navigationTitle(expense == nil ? "費用を追加" : "費用を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        guard let amount else { return }
                        if onSave(name, amount, category) {
                            dismiss()
                        }
                    }
                    .disabled((amount ?? 0) <= 0)
                }
            }
            .keyboardDoneButton(focusedField: $focusedField)
            .confirmationDialog(
                "この費用を削除しますか？",
                isPresented: $isShowingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("削除", role: .destructive) {
                    onDelete?()
                    dismiss()
                }
                Button("キャンセル", role: .cancel) {}
            }
        }
    }
}
