//
//  EchoXApp.swift
//  EchoX
//
//  Created by Barathwaj Anandan on 11/12/25.
//

import SwiftUI

@main
struct EchoXApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
