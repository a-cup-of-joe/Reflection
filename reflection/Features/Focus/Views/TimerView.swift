//
//  TimerView.swift
//  reflection
//
//  Created by linan on 2025/7/9.
//

import SwiftUI

struct TimerView: View {
    let elapsedTime: TimeInterval
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            // 圆形进度环
            ZStack {
                ProgressCircle(
                    progress: CGFloat(sin(elapsedTime / 60.0) * 0.5 + 0.5),
                    size: 200,
                    lineWidth: 8
                )
                
                VStack(spacing: Spacing.sm) {
                    Text(elapsedTime.formatted())
                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                        .foregroundColor(.primary)
                    
                    Text("已专注时间")
                        .font(.caption)
                        .foregroundColor(.secondaryGray)
                }
            }
            
            // 状态指示器
            HStack(spacing: Spacing.sm) {
                Circle()
                    .fill(Color.primaryGreen)
                    .frame(width: 8, height: 8)
                    .scaleEffect(1.5)
                    .animation(.easeInOut(duration: 1.0).repeatForever(), value: elapsedTime)
                
                Text("专注中...")
                    .font(.caption)
                    .foregroundColor(.primaryGreen)
            }
        }
    }
}

#Preview {
    TimerView(elapsedTime: 1325) // 22分5秒
}
