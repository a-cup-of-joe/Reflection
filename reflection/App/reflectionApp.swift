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
    // 在应用级别创建全局 ViewModel
    @StateObject private var dataManager = DataManager.shared
    @StateObject private var planViewModel = PlanViewModel.shared
    @StateObject private var sessionViewModel = SessionViewModel.shared
    @StateObject private var statisticsViewModel = StatisticsViewModel.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataManager)
                .environmentObject(planViewModel)
                .environmentObject(sessionViewModel)  
                .environmentObject(statisticsViewModel)
                .background(Color.appBackground)
                .frame(minWidth: 450, maxWidth: .infinity, minHeight: 400, maxHeight: .infinity)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 1000, height: 700)
    }
}
