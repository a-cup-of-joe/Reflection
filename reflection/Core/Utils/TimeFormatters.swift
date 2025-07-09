//
//  TimeFormatters.swift
//  reflection
//
//  Created by linan on 2025/7/9.
//

import Foundation

struct TimeFormatters {
    static func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    static func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    static func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    static func parseTimeInput(_ input: String) -> TimeInterval? {
        let components = input.components(separatedBy: ":")
        
        switch components.count {
        case 1:
            // 只有分钟
            if let minutes = Double(components[0]) {
                return minutes * 60
            }
        case 2:
            // 小时:分钟
            if let hours = Double(components[0]),
               let minutes = Double(components[1]) {
                return hours * 3600 + minutes * 60
            }
        case 3:
            // 小时:分钟:秒
            if let hours = Double(components[0]),
               let minutes = Double(components[1]),
               let seconds = Double(components[2]) {
                return hours * 3600 + minutes * 60 + seconds
            }
        default:
            return nil
        }
        
        return nil
    }
}
