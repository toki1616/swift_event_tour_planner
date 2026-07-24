import SwiftUI
import UIKit

private struct KeyboardDoneModifier<Field: Hashable>: ViewModifier {
    let focusedField: FocusState<Field?>.Binding

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完了") {
                        focusedField.wrappedValue = nil
                    }
                }
            }
            .onSubmit {
                focusedField.wrappedValue = nil
            }
            .scrollDismissesKeyboard(.interactively)
            .background(
                KeyboardDismissTapInstaller(focusedField: focusedField)
            )
    }
}

private struct KeyboardDismissTapInstaller<Field: Hashable>: UIViewRepresentable {
    let focusedField: FocusState<Field?>.Binding

    func makeCoordinator() -> Coordinator {
        Coordinator(focusedField: focusedField)
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        DispatchQueue.main.async {
            context.coordinator.installGestureRecognizer(from: view)
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.focusedField = focusedField
        DispatchQueue.main.async {
            context.coordinator.installGestureRecognizer(from: uiView)
        }
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.uninstallGestureRecognizer()
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var focusedField: FocusState<Field?>.Binding
        private weak var installedView: UIView?
        private lazy var tapGestureRecognizer: UITapGestureRecognizer = {
            let gestureRecognizer = UITapGestureRecognizer(
                target: self,
                action: #selector(didTapOutsideInput)
            )
            gestureRecognizer.cancelsTouchesInView = false
            gestureRecognizer.delegate = self
            return gestureRecognizer
        }()

        init(focusedField: FocusState<Field?>.Binding) {
            self.focusedField = focusedField
        }

        func installGestureRecognizer(from view: UIView) {
            guard let targetView = view.window, installedView !== targetView else {
                return
            }
            uninstallGestureRecognizer()
            targetView.addGestureRecognizer(tapGestureRecognizer)
            installedView = targetView
        }

        func uninstallGestureRecognizer() {
            installedView?.removeGestureRecognizer(tapGestureRecognizer)
            installedView = nil
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldReceive touch: UITouch
        ) -> Bool {
            !isTextInput(touch.view)
        }

        private func isTextInput(_ view: UIView?) -> Bool {
            var currentView = view
            while let current = currentView {
                if current is UITextField || current is UITextView {
                    return true
                }
                currentView = current.superview
            }
            return false
        }

        @objc private func didTapOutsideInput() {
            focusedField.wrappedValue = nil
        }
    }
}

extension View {
    func keyboardDoneButton<Field: Hashable>(
        focusedField: FocusState<Field?>.Binding
    ) -> some View {
        modifier(KeyboardDoneModifier(focusedField: focusedField))
    }
}
