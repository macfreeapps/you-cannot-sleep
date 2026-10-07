import AppKit
import SwiftUI

struct HotKeyRecorderView: NSViewRepresentable {
    @Binding var combination: HotKeyCombination?

    func makeNSView(context: Context) -> HotKeyRecorderField {
        let field = HotKeyRecorderField()
        field.setAccessibilityLabel(String(localized: "Record global keyboard shortcut"))
        field.setAccessibilityHelp(String(localized: "Press a key with Command, Option, or Control."))
        field.onCapture = { keyCode, flags in
            let relevant = flags.intersection([.command, .option, .control, .shift])
            combination = HotKeyCombination(keyCode: keyCode, modifiers: UInt32(relevant.rawValue))
        }
        field.stringValue = combination?.displayString ?? String(localized: "Record shortcut")
        return field
    }

    func updateNSView(_ view: HotKeyRecorderField, context: Context) {
        view.stringValue = combination?.displayString ?? String(localized: "Record shortcut")
    }
}

final class HotKeyRecorderField: NSTextField {
    var onCapture: ((UInt16, NSEvent.ModifierFlags) -> Void)?

    override var acceptsFirstResponder: Bool { true }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        stringValue = String(localized: "Type a shortcut…")
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            window?.makeFirstResponder(nil)
            return
        }
        onCapture?(event.keyCode, event.modifierFlags)
    }
}
