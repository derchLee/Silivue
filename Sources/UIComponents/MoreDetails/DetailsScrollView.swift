import AppKit
import SwiftUI

/// A persistent, space-reserving scrollbar when detail content overflows.
struct DetailsScrollView<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            content()
                .background(DetailsScrollerConfiguration())
        }
    }
}

private struct DetailsScrollerConfiguration: NSViewRepresentable {
    func makeNSView(context: Context) -> ScrollerConfigurationView {
        ScrollerConfigurationView()
    }

    func updateNSView(_ nsView: ScrollerConfigurationView, context: Context) {
        nsView.configureWhenAttached()
    }
}

private final class ScrollerConfigurationView: NSView {
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        configureWhenAttached()
    }

    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        configureWhenAttached()
    }

    func configureWhenAttached() {
        DispatchQueue.main.async { [weak self] in
            guard let scrollView = self?.enclosingScrollView else { return }
            // Legacy style reserves a gutter and does not fade out after scrolling.
            scrollView.scrollerStyle = .legacy
            scrollView.hasVerticalScroller = true
            scrollView.hasHorizontalScroller = false
            scrollView.autohidesScrollers = true
            scrollView.scrollerKnobStyle = .light
            scrollView.appearance = NSAppearance(named: .darkAqua)
        }
    }
}
