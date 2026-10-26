import SwiftUI
import WebKit

/// Receives messages from the game (window.webkit.messageHandlers.native.postMessage({...}))
/// and can run JavaScript in it.
final class GameBridge: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
    static let shared = GameBridge()
    weak var webView: WKWebView?

    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any] else { return }
        if let kind = body["haptic"] as? String { Haptics.play(kind) }
    }

    func send(_ js: String) {
        webView?.evaluateJavaScript(js, completionHandler: nil)
    }

    // Everything the game needs is in the bundle; keep any stray link out of the app window.
    func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = action.request.url, url.isFileURL || url.scheme == "about" {
            decisionHandler(.allow)
        } else {
            if let url = action.request.url {
                #if os(iOS)
                UIApplication.shared.open(url)
                #else
                NSWorkspace.shared.open(url)
                #endif
            }
            decisionHandler(.cancel)
        }
    }
}

enum GameWebViewFactory {
    static func make() -> WKWebView {
        let config = WKWebViewConfiguration()
        let content = WKUserContentController()
        content.add(GameBridge.shared, name: "native")
        #if os(iOS)
        let platform = UIDevice.current.userInterfaceIdiom == .pad ? "ipad" : "iphone"
        #else
        let platform = "mac"
        #endif
        let flag = "window.WG_APP={platform:'\(platform)',version:'\(Bundle.main.shortVersion)'};"
        content.addUserScript(WKUserScript(source: flag, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        config.userContentController = content
        config.websiteDataStore = .default()        // keeps generals' names & settings between launches
        #if os(iOS)
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        #endif

        let web = WKWebView(frame: .zero, configuration: config)
        web.navigationDelegate = GameBridge.shared
        GameBridge.shared.webView = web
        #if os(iOS)
        web.isOpaque = false
        web.backgroundColor = UIColor(red: 0.114, green: 0.094, blue: 0.071, alpha: 1)
        web.scrollView.backgroundColor = web.backgroundColor
        web.scrollView.isScrollEnabled = false
        web.scrollView.bounces = false
        web.scrollView.contentInsetAdjustmentBehavior = .never
        web.scrollView.pinchGestureRecognizer?.isEnabled = false
        web.allowsLinkPreview = false
        #else
        web.underPageBackgroundColor = NSColor(red: 0.114, green: 0.094, blue: 0.071, alpha: 1)
        web.allowsMagnification = false
        #endif
        #if DEBUG
        if #available(iOS 16.4, macOS 13.3, *) { web.isInspectable = true }
        #endif

        if let url = Bundle.main.url(forResource: "index", withExtension: "html") {
            web.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
        return web
    }
}

#if os(iOS)
struct GameWebView: UIViewRepresentable {
    func makeUIView(context: Context) -> WKWebView { GameWebViewFactory.make() }
    func updateUIView(_ view: WKWebView, context: Context) {}
}
#else
struct GameWebView: NSViewRepresentable {
    func makeNSView(context: Context) -> WKWebView { GameWebViewFactory.make() }
    func updateNSView(_ view: WKWebView, context: Context) {}
}
#endif

extension Bundle {
    var shortVersion: String { (infoDictionary?["CFBundleShortVersionString"] as? String) ?? "1.0" }
}
