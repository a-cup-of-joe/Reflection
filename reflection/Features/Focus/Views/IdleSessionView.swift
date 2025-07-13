//
//  IdleSessionView.swift
//  reflection
//
//  Created by linan on 2025/7/13.
//

import SwiftUI

struct IdleSessionView: View {
    let onStartSession: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            BigCircleStartButton {
                onStartSession()
            }
            .padding(.horizontal, Spacing.xl)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
        .transition(.asymmetric(
            insertion: .move(edge: .leading),
            removal: .move(edge: .trailing)
        ))
    }
}

struct BigCircleStartButton: View {
    let onTap: () -> Void
    
    @EnvironmentObject var sessionViewModel: SessionViewModel
    @State private var isPressed = false
    @State private var isPulsing = false
    @State private var rotationAngle: Double = 0
    @State private var innerGlowOpacity = 0.3
    @State private var rippleScale: CGFloat = 1.0
    @State private var rippleOpacity = 0.0
    
    private let buttonSize: CGFloat = 240  // 增大按钮尺寸
    
    var body: some View {
        ZStack {
            
            // 主按钮
            Button(action: {
                // 触觉反馈
                NSHapticFeedbackManager.performHapticFeedback()
                
                // 涟漪效果
                withAnimation(.easeOut(duration: 0.6)) {
                    rippleScale = 1.5
                    rippleOpacity = 0.0
                }
                
                // 重置涟漪
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    rippleScale = 1.0
                    rippleOpacity = 1.0
                }
                
                onTap()
            }) {
                ZStack {
                    // 主圆形背景
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.primaryGreen.opacity(0.9),
                                    Color.primaryGreen,
                                    Color.primaryGreen.opacity(0.8)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: buttonSize, height: buttonSize)
                        .scaleEffect(isPressed ? 0.95 : 1.0)
                        .animation(.easeInOut(duration: 0.1), value: isPressed)
                    
                    // 内层光晕
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(innerGlowOpacity),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: buttonSize/2
                            )
                        )
                        .frame(width: buttonSize, height: buttonSize)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: innerGlowOpacity)
                    
                    // 旋转的装饰圆环
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        .frame(width: buttonSize - 30, height: buttonSize - 30)
                        .overlay(
                            Circle()
                                .trim(from: 0, to: 0.3)
                                .stroke(Color.white.opacity(0.6), lineWidth: 2)
                                .rotationEffect(.degrees(rotationAngle))
                        )
                    
                    // 播放图标和文字
                    VStack(spacing: Spacing.md) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 48, weight: .medium))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                            .scaleEffect(isPressed ? 0.9 : 1.0)
                            .rotationEffect(.degrees(isPressed ? -5 : 0))
                            .animation(.easeInOut(duration: 0.1), value: isPressed)
                        
                        VStack(spacing: Spacing.xs) {
                            Text("开始专注")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            Text("Focus Session")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .scaleEffect(isPressed ? 0.95 : 1.0)
                        .animation(.easeInOut(duration: 0.1), value: isPressed)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            isPressed = true
                            // 按下时的触觉反馈
                            NSHapticFeedbackManager.performHapticFeedback()
                        }
                    }
                    .onEnded { _ in
                        isPressed = false
                    }
            )
            .shadow(
                color: Color.primaryGreen.opacity(isPressed ? 0.4 : 0.6),
                radius: isPressed ? 12 : 20,
                x: 0,
                y: isPressed ? 6 : 10
            )
        }
        .onAppear {
            // 启动各种动画
            isPulsing = true
            
            // 内层光晕闪烁
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                innerGlowOpacity = 0.6
            }
            
            // 装饰圆环旋转
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
        }
    }
}

// 扩展触觉反馈
extension NSHapticFeedbackManager {
    static func performHapticFeedback() {
        let impactFeedback = NSHapticFeedbackManager.defaultPerformer
        impactFeedback.perform(.alignment, performanceTime: .now)
    }
}

#Preview {
    IdleSessionView(onStartSession: {})
}
