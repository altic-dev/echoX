//
//  ShortcutRecorder.swift
//  EchoX
//
//  Custom view for recording keyboard shortcuts
//

import SwiftUI
import AppKit

struct ShortcutRecorder: NSViewRepresentable {
    @Binding var keyCode: UInt16
    @Binding var modifierFlags: NSEvent.ModifierFlags

    func makeNSView(context: Context) -> ShortcutRecorderView {
        let view = ShortcutRecorderView()
        view.onShortcutCapture = { keyCode, flags in
            self.keyCode = keyCode
            self.modifierFlags = flags
        }
        return view
    }

    func updateNSView(_ nsView: ShortcutRecorderView, context: Context) {
        nsView.keyCode = keyCode
        nsView.modifierFlags = modifierFlags
    }
}

class ShortcutRecorderView: NSView {
    var keyCode: UInt16 = 5
    var modifierFlags: NSEvent.ModifierFlags = .option
    var onShortcutCapture: ((UInt16, NSEvent.ModifierFlags) -> Void)?
    var isRecording = false

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    func setup() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        layer?.borderColor = NSColor.separatorColor.cgColor
        layer?.borderWidth = 1
        layer?.cornerRadius = 4
    }

    override var acceptsFirstResponder: Bool { true }

    override func mouseDown(with event: NSEvent) {
        isRecording = true
        layer?.borderColor = NSColor.controlAccentColor.cgColor
        layer?.borderWidth = 2
        needsDisplay = true
        window?.makeFirstResponder(self)
    }

    override func keyDown(with event: NSEvent) {
        guard isRecording else { return }

        if event.keyCode == 53 {
            isRecording = false
            layer?.borderColor = NSColor.separatorColor.cgColor
            layer?.borderWidth = 1
            needsDisplay = true
            return
        }

        let modifiers = event.modifierFlags.intersection([.command, .option, .shift, .control])

        if modifiers.isEmpty {
            return
        }

        keyCode = event.keyCode
        modifierFlags = modifiers
        onShortcutCapture?(keyCode, modifiers)

        isRecording = false
        layer?.borderColor = NSColor.separatorColor.cgColor
        layer?.borderWidth = 1
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let text: String
        if isRecording {
            text = "Press shortcut..."
        } else {
            text = shortcutString()
        }

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13),
            .foregroundColor: NSColor.labelColor,
            .paragraphStyle: paragraphStyle
        ]

        let textRect = NSRect(x: 0, y: (bounds.height - 20) / 2, width: bounds.width, height: 20)
        text.draw(in: textRect, withAttributes: attributes)
    }

    func shortcutString() -> String {
        var parts: [String] = []

        if modifierFlags.contains(.control) { parts.append("⌃") }
        if modifierFlags.contains(.option) { parts.append("⌥") }
        if modifierFlags.contains(.shift) { parts.append("⇧") }
        if modifierFlags.contains(.command) { parts.append("⌘") }

        parts.append(keyCodeToString(keyCode))

        return parts.joined()
    }

    func keyCodeToString(_ keyCode: UInt16) -> String {
        switch keyCode {
        case 0: return "A"
        case 1: return "S"
        case 2: return "D"
        case 3: return "F"
        case 4: return "H"
        case 5: return "G"
        case 6: return "Z"
        case 7: return "X"
        case 8: return "C"
        case 9: return "V"
        case 11: return "B"
        case 12: return "Q"
        case 13: return "W"
        case 14: return "E"
        case 15: return "R"
        case 16: return "Y"
        case 17: return "T"
        case 31: return "O"
        case 32: return "U"
        case 34: return "I"
        case 35: return "P"
        case 37: return "L"
        case 38: return "J"
        case 40: return "K"
        case 45: return "N"
        case 46: return "M"
        case 49: return "Space"
        default: return "?"
        }
    }

    override var intrinsicContentSize: NSSize {
        return NSSize(width: 200, height: 30)
    }
}
