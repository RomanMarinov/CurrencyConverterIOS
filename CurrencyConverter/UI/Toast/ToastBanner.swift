import SwiftUI

struct ToastBanner: View {
    let message: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(AppTheme.accent)
            Text(message)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
    }
}

private struct RatesRefreshToastModifier: ViewModifier {
    @Environment(RatesStore.self) private var store

    @State private var isVisible = false
    @State private var dismissTask: Task<Void, Never>?

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if isVisible {
                    ToastBanner(message: "Курсы обновлены")
                        .padding(.horizontal, 20)
                        .padding(.bottom, 56)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.82), value: isVisible)
            .onChange(of: store.successToastNonce) { _, nonce in
                guard nonce > 0 else { return }
                presentToast()
            }
    }

    private func presentToast() {
        dismissTask?.cancel()
        isVisible = true
        dismissTask = Task {
            try? await Task.sleep(for: .seconds(2.5))
            guard !Task.isCancelled else { return }
            isVisible = false
        }
    }
}

extension View {
    func ratesRefreshToast() -> some View {
        modifier(RatesRefreshToastModifier())
    }
}
