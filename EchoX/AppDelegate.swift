//
//  AppDelegate.swift
//  EchoX
//
//  Main application delegate managing menubar, shortcuts, and recording indicator
//

import Cocoa
import SwiftUI
import Carbon.HIToolbox
import AVFoundation

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var audioManager: AudioManager!
    var permissionManager: PermissionManager!
    var settingsWindow: NSWindow?
    var globalEventMonitor: Any?
    var localEventMonitor: Any?
    var recordingIndicator: RecordingIndicatorWindow?
    var permissionCheckTimer: Timer?
    var eventTapCreationFailed = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        audioManager = AudioManager()
        permissionManager = PermissionManager()
        setupGlobalKeyboardShortcut()
        requestPermissions()
        
        // Start monitoring for accessibility permission changes
        if eventTapCreationFailed {
            startPermissionMonitoring()
        }
    }

    func requestPermissions() {
        // Request microphone permission
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            DispatchQueue.main.async { [weak self] in
                self?.permissionManager.microphoneStatus = granted ? .granted : .denied
                if !granted {
                    self?.showPermissionAlert(for: "Microphone")
                }
            }
        }

        // Accessibility permission is checked automatically when creating event tap
        // If it fails, showAccessibilityAlert() will be called from setupGlobalKeyboardShortcut()
        permissionManager.checkAccessibilityPermission()
    }

    func showPermissionAlert(for permission: String) {
        let alert = NSAlert()
        alert.messageText = "\(permission) Permission Required"
        alert.informativeText = "EchoX needs \(permission.lowercased()) access to function properly. Please grant permission in System Settings."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open Settings")
        alert.addButton(withTitle: "Later")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            permissionManager.openSystemPreferences(for: permission.lowercased())
        }
    }

    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "waveform", accessibilityDescription: "EchoX")
        }

        let menu = NSMenu()

        menu.addItem(NSMenuItem(title: "Settings", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))

        statusItem?.menu = menu
    }

    func setupGlobalKeyboardShortcut() {
        recordingIndicator = RecordingIndicatorWindow()

        let eventMask = CGEventMask(1 << CGEventType.keyDown.rawValue) | CGEventMask(1 << CGEventType.keyUp.rawValue)

        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: CGEventTapOptions(rawValue: 0)!,  // Active filter (not passive listener)
            eventsOfInterest: eventMask,
            callback: { proxy, type, event, refcon in
                let appDelegate = Unmanaged<AppDelegate>.fromOpaque(refcon!).takeUnretainedValue()
                return appDelegate.handleGlobalKeyEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            print("ERROR: Failed to create event tap. Grant Accessibility permission in System Settings.")
            // macOS will show its own system dialog automatically
            eventTapCreationFailed = true
            return
        }

        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)

        print("Global keyboard shortcut enabled.")
    }

    func handleGlobalKeyEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .keyDown || type == .keyUp {
            let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
            let flags = event.flags

            // Build required modifier flags
            var requiredModifiers: CGEventFlags = []
            if audioManager.shortcutModifierFlags.contains(.command) { requiredModifiers.insert(.maskCommand) }
            if audioManager.shortcutModifierFlags.contains(.option) { requiredModifiers.insert(.maskAlternate) }
            if audioManager.shortcutModifierFlags.contains(.shift) { requiredModifiers.insert(.maskShift) }
            if audioManager.shortcutModifierFlags.contains(.control) { requiredModifiers.insert(.maskControl) }

            // Check if keyCode matches
            guard keyCode == audioManager.shortcutKeyCode else {
                return Unmanaged.passRetained(event)
            }

            // Extract only the modifier flags we care about from the event
            let relevantFlags = flags.intersection([.maskCommand, .maskAlternate, .maskShift, .maskControl])

            // Check if modifiers match exactly
            guard relevantFlags == requiredModifiers else {
                return Unmanaged.passRetained(event)
            }

            // At this point, we have a match - consume the event completely
            let isRepeat = event.getIntegerValueField(.keyboardEventAutorepeat) == 1

            DispatchQueue.main.async { [weak self] in
                if type == .keyDown && !isRepeat {
                    print("✓ Shortcut matched - starting recording")
                    self?.audioManager.startRecording()
                    self?.recordingIndicator?.show()
                } else if type == .keyUp {
                    print("✓ Shortcut released - stopping recording")
                    self?.audioManager.stopRecordingAndPlayback()
                    self?.recordingIndicator?.hide()
                }
            }

            // Return nil to completely block this event from propagating
            return nil
        }

        return Unmanaged.passRetained(event)
    }


    @objc func openSettings() {
        if settingsWindow == nil {
            let settingsView = SettingsView(
                audioManager: audioManager,
                permissionManager: permissionManager,
                onClose: { [weak self] in
                    self?.settingsWindow?.close()
                    self?.settingsWindow = nil
                }
            )
            let hostingController = NSHostingController(rootView: settingsView)

            settingsWindow = NSWindow(contentViewController: hostingController)
            settingsWindow?.title = "EchoX Settings"
            settingsWindow?.styleMask = [.titled, .closable]
            settingsWindow?.setContentSize(NSSize(width: 450, height: 500))
            settingsWindow?.center()
        }

        permissionManager.refreshPermissions()
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func quit() {
        NSApplication.shared.terminate(nil)
    }
    
    // MARK: - Permission Monitoring
    
    func startPermissionMonitoring() {
        // Check every 1 second if accessibility permission has been granted
        permissionCheckTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkAccessibilityPermissionAndRestart()
        }
    }
    
    func checkAccessibilityPermissionAndRestart() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)
        
        if accessEnabled {
            print("✓ Accessibility permission granted! Restarting app...")
            permissionCheckTimer?.invalidate()
            permissionCheckTimer = nil
            restartApp()
        }
    }
    
    func restartApp() {
        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = [Bundle.main.bundlePath]
        task.launch()
        
        NSApp.terminate(nil)
    }
}
