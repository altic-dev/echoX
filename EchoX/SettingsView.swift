//
//  SettingsView.swift
//  EchoX
//
//  Settings UI for delay, shortcuts, audio devices, and permissions
//

import SwiftUI
import AVFoundation

struct SettingsView: View {
    @ObservedObject var audioManager: AudioManager
    @ObservedObject var permissionManager: PermissionManager
    var onClose: () -> Void
    @State private var inputDevices: [AVCaptureDevice] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("EchoX Settings")
                .font(.title)
                .padding(.bottom, 10)

            VStack(alignment: .leading, spacing: 8) {
                Text("Playback Delay")
                    .font(.headline)

                HStack {
                    Slider(value: $audioManager.playbackDelay, in: 0.0...5.0, step: 0.1)
                        .frame(maxWidth: 250)

                    Text(String(format: "%.1f s", audioManager.playbackDelay))
                        .frame(width: 50, alignment: .trailing)
                        .monospacedDigit()
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Keyboard Shortcut")
                    .font(.headline)

                ShortcutRecorder(
                    keyCode: $audioManager.shortcutKeyCode,
                    modifierFlags: $audioManager.shortcutModifierFlags
                )
                .frame(height: 30)

                Text("Click to record new shortcut, ESC to cancel")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Audio Input")
                    .font(.headline)

                if inputDevices.isEmpty {
                    Text("Loading devices...")
                        .foregroundColor(.secondary)
                } else {
                    Picker("", selection: $audioManager.selectedInputDevice) {
                        Text("Default").tag(nil as AVCaptureDevice?)
                        ForEach(inputDevices, id: \.uniqueID) { device in
                            Text(device.localizedName).tag(device as AVCaptureDevice?)
                        }
                    }
                    .labelsHidden()
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Permissions")
                    .font(.headline)

                HStack {
                    Image(systemName: "mic.fill")
                        .foregroundColor(Color(permissionManager.microphoneStatus.color))
                        .frame(width: 20)

                    Text("Microphone:")
                        .frame(width: 120, alignment: .leading)

                    Text(permissionManager.microphoneStatus.displayText)
                        .foregroundColor(Color(permissionManager.microphoneStatus.color))
                        .frame(width: 100, alignment: .leading)

                    Spacer()

                    if permissionManager.microphoneStatus != .granted {
                        Button("Open Settings") {
                            permissionManager.openSystemPreferences(for: "microphone")
                        }
                        .buttonStyle(.bordered)
                    }
                }

                HStack {
                    Image(systemName: "hand.raised.fill")
                        .foregroundColor(Color(permissionManager.accessibilityStatus.color))
                        .frame(width: 20)

                    Text("Accessibility:")
                        .frame(width: 120, alignment: .leading)

                    Text(permissionManager.accessibilityStatus.displayText)
                        .foregroundColor(Color(permissionManager.accessibilityStatus.color))
                        .frame(width: 100, alignment: .leading)

                    Spacer()

                    if permissionManager.accessibilityStatus != .granted {
                        Button("Open Settings") {
                            permissionManager.openSystemPreferences(for: "accessibility")
                        }
                        .buttonStyle(.bordered)
                    }
                }

                Text("Note: Accessibility permission is required for global shortcuts")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack {
                Button("Refresh") {
                    permissionManager.refreshPermissions()
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Save") {
                    audioManager.saveSettings()
                    onClose()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 450, height: 500)
        .onAppear {
            inputDevices = audioManager.getAvailableInputDevices()
            permissionManager.refreshPermissions()
        }
    }
}
