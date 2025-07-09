//
//  reflectionApp.swift
//  reflection
//
//  Created by linan on 2025/7/9.
//
//  This is a MacOS app, not IOS!

import SwiftUI

@main
struct reflectionApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .background(Color.appBackground)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 1000, height: 700)
    }
}
