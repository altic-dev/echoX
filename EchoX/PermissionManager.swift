//
//  PermissionManager.swift
//  EchoX
//
//  Manages microphone and accessibility permission checks
//

import AVFoundation
import AppKit
import Combine

class PermissionManager: ObservableObject {
    @Published var microphoneStatus: PermissionStatus = .notDetermined
    @Published var accessibilityStatus: PermissionStatus = .notDetermined

    enum PermissionStatus {
        case notDetermined
        case granted
        case denied

        var displayText: String {
            switch self {
            case .notDetermined: return "Not Checked"
            case .granted: return "Granted"
            case .denied: return "Denied"
            }
        }

        var color: NSColor {
            switch self {
            case .notDetermined: return .systemOrange
            case .granted: return .systemGreen
            case .denied: return .systemRed
            }
        }
    }

    func checkMicrophonePermission() {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            microphoneStatus = .granted
        case .denied, .restricted:
            microphoneStatus = .denied
        case .notDetermined:
            microphoneStatus = .notDetermined
        @unknown default:
            microphoneStatus = .notDetermined
        }
    }

    func requestMicrophonePermission() {
        AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
            DispatchQueue.main.async {
                self?.microphoneStatus = granted ? .granted : .denied
            }
        }
    }

    func checkAccessibilityPermission() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)
        accessibilityStatus = accessEnabled ? .granted : .denied
    }

    func openSystemPreferences(for permission: String) {
        if permission == "microphone" {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
                NSWorkspace.shared.open(url)
            }
        } else if permission == "accessibility" {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
        }
    }

    func refreshPermissions() {
        checkMicrophonePermission()
        checkAccessibilityPermission()
    }
}
