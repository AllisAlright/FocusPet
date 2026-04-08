//
//  FocusPetApp.swift
//  FocusPet
//
//  Created by xsy on 2026/3/14.
//

import SwiftUI

@main
struct FocusPetApp: App {
    @StateObject private var store = FocusPetStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
