import AppKit
import SwiftUI

class TextViewHolder {
    weak var textView: NSTextView?
}

struct TextViewIntrospect: NSViewRepresentable {
    let holder: TextViewHolder

    func makeNSView(context: Context) -> NSView {
        let view = IntrospectionView()
        view.holder = holder
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        (nsView as? IntrospectionView)?.holder = holder
    }

    class IntrospectionView: NSView {
        var holder: TextViewHolder?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            guard window != nil else { return }
            DispatchQueue.main.async { [weak self] in
                guard let self, let window = self.window else { return }
                self.holder?.textView = Self.findTextView(in: window.contentView)
            }
        }

        static func findTextView(in view: NSView?) -> NSTextView? {
            guard let view else { return nil }
            if let tv = view as? NSTextView, !tv.isFieldEditor { return tv }
            for sub in view.subviews {
                if let found = findTextView(in: sub) { return found }
            }
            return nil
        }
    }
}

extension NSNotification.Name {
    static let markdownInserted = NSNotification.Name("MarkdownInserted")
}
