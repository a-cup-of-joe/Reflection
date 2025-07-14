//
//  TimeFormatters.swift
//  reflection
//
//  Created by linan on 2025/7/9.
//

import Foundation

// MARK: - TimeInterval Extensions
extension TimeInterval {
    /// 格式化时间长度为 "H:MM:SS" 或 "M:SS" 格式
    func formatted() -> String {
        let hours = Int(self) / 3600
        let minutes = Int(self) % 3600 / 60
        let seconds = Int(self) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    /// 格式化时间长度为简洁格式，如 "1h30m" 或 "30m"
    func formattedShort() -> String {
        let totalMinutes = Int(self / 60)
        let hours = totalMinutes / 60
        let mins = totalMinutes % 60
        
        if hours > 0 {
            return mins > 0 ? "\(hours)h\(mins)m" : "\(hours)h"
        } else {
            return "\(mins)m"
        }
    }
}

// MARK: - Int Extensions (for minutes)
extension Int {
    /// 将分钟数格式化为简洁时间格式
    func formattedAsTime() -> String {
        let hours = self / 60
        let mins = self % 60
        
        if hours > 0 {
            return mins > 0 ? "\(hours)h\(mins)m" : "\(hours)h"
        } else {
            return "\(mins)m"
        }
    }
}

// MARK: - Date Extensions
extension Date {
    /// 格式化为短时间格式
    func formattedTime() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    
    /// 格式化为日期格式
    func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: self)
    }
    
    /// 格式化为日期时间格式
    func formattedDateTime() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}

// MARK: - String Extensions
extension String {
    /// 解析时间输入字符串为 TimeInterval
    func parseAsTimeInterval() -> TimeInterval? {
        let components = self.components(separatedBy: ":")
        
        switch components.count {
        case 1:
            if let minutes = Double(components[0]) {
                return minutes * 60
            }
        case 2:
            if let hours = Double(components[0]),
               let minutes = Double(components[1]) {
                return hours * 3600 + minutes * 60
            }
        case 3:
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

// MARK: - TimeFormatters
struct TimeFormatters {
    /// 格式化时间长度为易读格式
    static func formatDuration(_ duration: TimeInterval) -> String {
        return duration.formattedShort()
    }
}
