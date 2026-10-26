#if os(iOS)
import UIKit

/// Light touches of feedback: a tick on orders, a thump on a whistle, a buzz on a score.
enum Haptics {
    private static let light = UIImpactFeedbackGenerator(style: .light)
    private static let medium = UIImpactFeedbackGenerator(style: .medium)
    private static let rigid = UIImpactFeedbackGenerator(style: .rigid)
    private static let select = UISelectionFeedbackGenerator()
    private static let notify = UINotificationFeedbackGenerator()

    static func play(_ kind: String) {
        switch kind {
        case "select": select.selectionChanged()
        case "order": medium.impactOccurred()
        case "whistle": rigid.impactOccurred(intensity: 0.8)
        case "score": notify.notificationOccurred(.success)
        case "against": notify.notificationOccurred(.warning)
        case "win": notify.notificationOccurred(.success)
        case "lose": notify.notificationOccurred(.error)
        default: light.impactOccurred()
        }
    }
}
#else
import AppKit

enum Haptics {
    static func play(_ kind: String) {
        // Force Touch trackpads only; quietly does nothing elsewhere.
        let pattern: NSHapticFeedbackManager.FeedbackPattern = kind == "select" ? .alignment : .generic
        NSHapticFeedbackManager.defaultPerformer.perform(pattern, performanceTime: .now)
    }
}
#endif
