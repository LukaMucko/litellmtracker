import AppKit
import SwiftUI

enum AccessibilitySettings {
    @MainActor
    static var reduceTransparency: Bool {
        NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency
    }
}

private struct SpendGlassCardModifier: ViewModifier {
    let cornerRadius: CGFloat
    let tint: Color?
    let interactive: Bool

    func body(content: Content) -> some View {
        if AccessibilitySettings.reduceTransparency {
            content
                .background(Color(nsColor: .windowBackgroundColor), in: .rect(cornerRadius: cornerRadius))
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(.quaternary, lineWidth: 1)
                }
        } else {
            content
                .glassEffect(glass, in: .rect(cornerRadius: cornerRadius))
        }
    }

    private var glass: Glass {
        var effect = Glass.regular
        if let tint {
            effect = effect.tint(tint)
        }
        if interactive {
            effect = effect.interactive()
        }
        return effect
    }
}

extension View {
    func spendGlassCard(cornerRadius: CGFloat = 16, tint: Color? = nil, interactive: Bool = false) -> some View {
        modifier(SpendGlassCardModifier(cornerRadius: cornerRadius, tint: tint, interactive: interactive))
    }
}
