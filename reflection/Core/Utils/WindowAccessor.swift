//
//  WindowAccessor.swift
//  reflection
//
//  Created by linan on 2025/7/9.
//

import SwiftUI
import AppKit

struct WindowAccessor: NSViewRepresentable {
    let onWindowAccess: (NSWindow?) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            context.coordinator.setupWindow(view.window)
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            context.coordinator.setupWindow(nsView.window)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onWindowAccess: onWindowAccess)
    }
    
    class Coordinator: NSObject {
        let onWindowAccess: (NSWindow?) -> Void
        private var window: NSWindow?
        private var timer: Timer?
        
        init(onWindowAccess: @escaping (NSWindow?) -> Void) {
            self.onWindowAccess = onWindowAccess
            super.init()
        }
        
        func setupWindow(_ window: NSWindow?) {
            guard let window = window else { return }
            
            // 移除之前的观察者
            if let oldWindow = self.window {
                removeObservers(for: oldWindow)
            }
            
            self.window = window
            
            // 添加多个窗口事件的观察者
            addObservers(for: window)
            
            // 应用窗口设置
            applyWindowSettings(window)
            
            // 启动定时器持续监控窗口状态
            startMonitoring()
        }
        
        private func addObservers(for window: NSWindow) {
            let notifications: [NSNotification.Name] = [
                NSWindow.didExitFullScreenNotification,
                NSWindow.didEnterFullScreenNotification,
                NSWindow.didMiniaturizeNotification,
                NSWindow.didDeminiaturizeNotification,
                NSWindow.didResizeNotification,
                NSWindow.didMoveNotification,
                NSWindow.didBecomeKeyNotification,
                NSWindow.didResignKeyNotification,
                NSWindow.didBecomeMainNotification,
                NSWindow.didResignMainNotification
            ]
            
            for notification in notifications {
                NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(windowStateChanged),
                    name: notification,
                    object: window
                )
            }
        }
        
        private func removeObservers(for window: NSWindow) {
            let notifications: [NSNotification.Name] = [
                NSWindow.didExitFullScreenNotification,
                NSWindow.didEnterFullScreenNotification,
                NSWindow.didMiniaturizeNotification,
                NSWindow.didDeminiaturizeNotification,
                NSWindow.didResizeNotification,
                NSWindow.didMoveNotification,
                NSWindow.didBecomeKeyNotification,
                NSWindow.didResignKeyNotification,
                NSWindow.didBecomeMainNotification,
                NSWindow.didResignMainNotification
            ]
            
            for notification in notifications {
                NotificationCenter.default.removeObserver(self, name: notification, object: window)
            }
        }
        
        @objc private func windowStateChanged() {
            // 延迟一点应用设置，确保窗口状态变化完成
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if let window = self.window {
                    self.applyWindowSettings(window)
                }
            }
        }
        
        private func startMonitoring() {
            // 停止之前的定时器
            timer?.invalidate()
            
            // 每0.5秒检查一次窗口状态并重新应用设置
            timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                DispatchQueue.main.async {
                    if let window = self.window {
                        self.applyWindowSettings(window)
                    }
                }
            }
        }
        
        private func applyWindowSettings(_ window: NSWindow) {
            onWindowAccess(window)
        }
        
        deinit {
            timer?.invalidate()
            if let window = self.window {
                removeObservers(for: window)
            }
        }
    }
}

extension View {
    func onWindowAccess(_ onWindowAccess: @escaping (NSWindow?) -> Void) -> some View {
        self.background(WindowAccessor(onWindowAccess: onWindowAccess))
    }
}
