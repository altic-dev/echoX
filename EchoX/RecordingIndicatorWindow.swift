//
//  RecordingIndicatorWindow.swift
//  EchoX
//
//  Floating window that displays recording indicator with animated waveform
//

import Cocoa
import SwiftUI

class RecordingIndicatorWindow: NSWindow {
    private var animationTimer: Timer?

    init() {
        let screenFrame = NSScreen.main?.frame ?? NSRect.zero
        let windowWidth: CGFloat = 200
        let windowHeight: CGFloat = 60

        let xPos = (screenFrame.width - windowWidth) / 2
        let yPos = screenFrame.height * 0.15

        let contentRect = NSRect(
            x: xPos,
            y: yPos,
            width: windowWidth,
            height: windowHeight
        )

        super.init(
            contentRect: contentRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        self.level = .floating
        self.isOpaque = false
        self.backgroundColor = .clear
        self.ignoresMouseEvents = true
        self.collectionBehavior = [.canJoinAllSpaces, .stationary]

        let hostingView = NSHostingView(rootView: RecordingIndicatorView())
        self.contentView = hostingView

        self.orderOut(nil)
    }

    func show() {
        self.orderFront(nil)
        startAnimation()
    }

    func hide() {
        self.orderOut(nil)
        stopAnimation()
    }

    private func startAnimation() {
        if let contentView = self.contentView as? NSHostingView<RecordingIndicatorView> {
            contentView.rootView.isAnimating = true
        }
    }

    private func stopAnimation() {
        if let contentView = self.contentView as? NSHostingView<RecordingIndicatorView> {
            contentView.rootView.isAnimating = false
        }
    }
}

struct RecordingIndicatorView: View {
    @State var isAnimating: Bool = false
    @State private var phase: CGFloat = 0

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "mic.fill")
                .foregroundColor(.red)
                .font(.system(size: 20))

            HStack(spacing: 3) {
                ForEach(0..<5) { index in
                    WaveformBar(index: index, phase: phase)
                }
            }

            Text("Recording")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.85))
        )
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        .onAppear {
            startAnimation()
        }
        .onDisappear {
            isAnimating = false
        }
    }

    private func startAnimation() {
        isAnimating = true
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            guard isAnimating else {
                timer.invalidate()
                return
            }
            phase += 0.15
        }
    }
}

struct WaveformBar: View {
    let index: Int
    let phase: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color.white)
            .frame(width: 4, height: barHeight)
            .animation(.easeInOut(duration: 0.3), value: barHeight)
    }

    private var barHeight: CGFloat {
        let offset = CGFloat(index) * 0.5
        let amplitude = sin(phase + offset) * 0.5 + 0.5
        return 10 + amplitude * 20
    }
}
