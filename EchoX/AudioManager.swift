//
//  AudioManager.swift
//  EchoX
//
//  Handles audio recording, playback, and user settings
//

import AVFoundation
import AppKit
import Combine

class AudioManager: ObservableObject {
    @Published var playbackDelay: Double = 0.5
    @Published var selectedInputDevice: AVCaptureDevice?
    @Published var isRecording = false
    @Published var shortcutKeyCode: UInt16 = 6  // Z key
    @Published var shortcutModifierFlags: NSEvent.ModifierFlags = [.command, .shift]

    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var recordedFileURL: URL?

    init() {
        loadSettings()
    }

    func loadSettings() {
        if let savedDelay = UserDefaults.standard.value(forKey: "playbackDelay") as? Double {
            playbackDelay = savedDelay
        }
        if let savedKeyCode = UserDefaults.standard.value(forKey: "shortcutKeyCode") as? UInt16 {
            shortcutKeyCode = savedKeyCode
        }
        if let savedModifiers = UserDefaults.standard.value(forKey: "shortcutModifierFlags") as? UInt {
            shortcutModifierFlags = NSEvent.ModifierFlags(rawValue: savedModifiers)
        }
    }

    func saveSettings() {
        UserDefaults.standard.set(playbackDelay, forKey: "playbackDelay")
        UserDefaults.standard.set(shortcutKeyCode, forKey: "shortcutKeyCode")
        UserDefaults.standard.set(shortcutModifierFlags.rawValue, forKey: "shortcutModifierFlags")
    }

    func startRecording() {
        guard !isRecording else { return }

        let tempDir = FileManager.default.temporaryDirectory
        recordedFileURL = tempDir.appendingPathComponent("recording_\(UUID().uuidString).m4a")

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: recordedFileURL!, settings: settings)
            audioRecorder?.record()
            isRecording = true
            print("Recording started")
        } catch {
            print("Failed to start recording: \(error)")
        }
    }

    func stopRecordingAndPlayback() {
        guard isRecording else { return }

        audioRecorder?.stop()
        isRecording = false
        print("Recording stopped")

        DispatchQueue.main.asyncAfter(deadline: .now() + playbackDelay) { [weak self] in
            self?.playRecording()
        }
    }

    func playRecording() {
        guard let url = recordedFileURL else {
            print("No recording found")
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
            print("Playing recording")

            DispatchQueue.main.asyncAfter(deadline: .now() + (audioPlayer?.duration ?? 0) + 0.5) { [weak self] in
                self?.cleanupRecording()
            }
        } catch {
            print("Failed to play recording: \(error)")
        }
    }

    func cleanupRecording() {
        guard let url = recordedFileURL else { return }

        try? FileManager.default.removeItem(at: url)
        recordedFileURL = nil
    }

    func getAvailableInputDevices() -> [AVCaptureDevice] {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.microphone, .external],
            mediaType: .audio,
            position: .unspecified
        )
        return discoverySession.devices
    }
}
