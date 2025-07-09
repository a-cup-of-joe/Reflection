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
        
        init(onWindowAccess: @escaping (NSWindow?) -> Void) {
            self.onWindowAccess = onWindowAccess
            super.init()
        }
        
        func setupWindow(_ window: NSWindow?) {
            guard let window = window else { return }
            
            // 移除之前的观察者
            if let oldWindow = self.window {
                NotificationCenter.default.removeObserver(self, name: NSWindow.didExitFullScreenNotification, object: oldWindow)
                NotificationCenter.default.removeObserver(self, name: NSWindow.didEnterFullScreenNotification, object: oldWindow)
            }
            
            self.window = window
            
            // 添加全屏状态变化的观察者
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(windowDidExitFullScreen),
                name: NSWindow.didExitFullScreenNotification,
                object: window
            )
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(windowDidEnterFullScreen),
                name: NSWindow.didEnterFullScreenNotification,
                object: window
            )
            
            // 应用窗口设置
            applyWindowSettings(window)
        }
        
        @objc private func windowDidExitFullScreen() {
            // 退出全屏时重新应用设置
            DispatchQueue.main.async {
                if let window = self.window {
                    self.applyWindowSettings(window)
                }
            }
        }
        
        @objc private func windowDidEnterFullScreen() {
            // 进入全屏时也可以做一些处理
            if let window = self.window {
                self.applyWindowSettings(window)
            }
        }
        
        private func applyWindowSettings(_ window: NSWindow) {
            onWindowAccess(window)
        }
        
        deinit {
            if let window = self.window {
                NotificationCenter.default.removeObserver(self, name: NSWindow.didExitFullScreenNotification, object: window)
                NotificationCenter.default.removeObserver(self, name: NSWindow.didEnterFullScreenNotification, object: window)
            }
        }
    }
}

extension View {
    func onWindowAccess(_ onWindowAccess: @escaping (NSWindow?) -> Void) -> some View {
        self.background(WindowAccessor(onWindowAccess: onWindowAccess))
    }
}
