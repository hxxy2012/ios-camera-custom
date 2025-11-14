//
//  Extensions.swift
//  ProCam Master
//
//  Swift扩展和工具函数
//  Created by Claude
//

import Foundation
import SwiftUI
import AVFoundation

// MARK: - Color Extensions
extension Color {
    // 品牌色
    static let cameraOrange = Color(hex: "#FF9500")
    static let cameraGreen = Color(hex: "#30D158")
    static let cameraYellow = Color(hex: "#FFD60A")
    static let cameraRed = Color(hex: "#FF3B30")
    static let cameraGray = Color(hex: "#98989D")

    // 从十六进制创建颜色
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - CMTime Extensions
extension CMTime {
    /// 转换为分数字符串（例如 "1/125"）
    var fractionString: String {
        let seconds = CMTimeGetSeconds(self)
        if seconds >= 1 {
            return String(format: "%.1f\"", seconds)
        } else {
            let denominator = Int(1.0 / seconds)
            return "1/\(denominator)"
        }
    }

    /// 转换为秒数
    var seconds: Double {
        return CMTimeGetSeconds(self)
    }

    /// 创建快门速度（分母）
    static func shutterSpeed(denominator: Int) -> CMTime {
        return CMTime(value: 1, timescale: Int32(denominator))
    }
}

// MARK: - Date Extensions
extension Date {
    /// 格式化为文件名
    var fileNameString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter.string(from: self)
    }

    /// 格式化为显示文本
    var displayString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}

// MARK: - View Extensions
extension View {
    /// 添加haptic反馈
    func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) -> some View {
        self.onTapGesture {
            let generator = UIImpactFeedbackGenerator(style: style)
            generator.impactOccurred()
        }
    }

    /// 条件修饰符
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Double Extensions
extension Double {
    /// 限制范围
    func clamped(to range: ClosedRange<Double>) -> Double {
        return min(max(self, range.lowerBound), range.upperBound)
    }

    /// 转换为百分比字符串
    var percentString: String {
        return String(format: "%.0f%%", self * 100)
    }
}

// MARK: - Float Extensions
extension Float {
    /// 限制范围
    func clamped(to range: ClosedRange<Float>) -> Float {
        return min(max(self, range.lowerBound), range.upperBound)
    }

    /// 格式化显示
    var formatted: String {
        return String(format: "%.1f", self)
    }
}

// MARK: - CGSize Extensions
extension CGSize {
    /// 宽高比
    var aspectRatio: CGFloat {
        return height > 0 ? width / height : 1.0
    }

    /// 对角线长度
    var diagonal: CGFloat {
        return sqrt(width * width + height * height)
    }
}

// MARK: - Array Extensions
extension Array where Element == CGFloat {
    /// 计算平均值
    var average: CGFloat {
        guard !isEmpty else { return 0 }
        return reduce(0, +) / CGFloat(count)
    }

    /// 查找最大值及其索引
    var maxWithIndex: (value: CGFloat, index: Int)? {
        guard !isEmpty else { return nil }
        var maxValue = self[0]
        var maxIndex = 0
        for (index, value) in enumerated() {
            if value > maxValue {
                maxValue = value
                maxIndex = index
            }
        }
        return (maxValue, maxIndex)
    }
}

// MARK: - UserDefaults Extensions
extension UserDefaults {
    /// 相机设置键
    enum CameraKeys: String {
        case defaultISO = "camera.default.iso"
        case defaultShutterSpeed = "camera.default.shutterSpeed"
        case gridType = "camera.grid.type"
        case showHistogram = "camera.show.histogram"
        case showLevel = "camera.show.level"
        case proRAWEnabled = "camera.proraw.enabled"
        case proRAWResolution = "camera.proraw.resolution"
    }

    /// 保存相机设置
    func saveCameraSettings(_ settings: CameraSettings) {
        set(settings.exposure.iso, forKey: CameraKeys.defaultISO.rawValue)
        set(settings.gridType.rawValue, forKey: CameraKeys.gridType.rawValue)
        set(settings.isHistogramVisible, forKey: CameraKeys.showHistogram.rawValue)
        set(settings.isLevelVisible, forKey: CameraKeys.showLevel.rawValue)
        set(settings.isProRAWEnabled, forKey: CameraKeys.proRAWEnabled.rawValue)
    }

    /// 加载相机设置
    func loadCameraSettings() -> CameraSettings {
        var settings = CameraSettings()

        if object(forKey: CameraKeys.defaultISO.rawValue) != nil {
            settings.exposure.iso = float(forKey: CameraKeys.defaultISO.rawValue)
        }

        if let gridTypeString = string(forKey: CameraKeys.gridType.rawValue),
           let gridType = GridType(rawValue: gridTypeString) {
            settings.gridType = gridType
        }

        settings.isHistogramVisible = bool(forKey: CameraKeys.showHistogram.rawValue)
        settings.isLevelVisible = bool(forKey: CameraKeys.showLevel.rawValue)
        settings.isProRAWEnabled = bool(forKey: CameraKeys.proRAWEnabled.rawValue)

        return settings
    }
}

// MARK: - FileManager Extensions
extension FileManager {
    /// 获取文档目录
    var documentsDirectory: URL {
        return urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    /// 获取缓存目录
    var cachesDirectory: URL {
        return urls(for: .cachesDirectory, in: .userDomainMask)[0]
    }

    /// 获取临时目录
    var temporaryDirectory: URL {
        return URL(fileURLWithPath: NSTemporaryDirectory())
    }

    /// 计算目录大小
    func directorySize(at url: URL) -> Int64 {
        var size: Int64 = 0

        if let enumerator = enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) {
            for case let fileURL as URL in enumerator {
                if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    size += Int64(fileSize)
                }
            }
        }

        return size
    }

    /// 格式化文件大小
    func formattedSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - Notification Extensions
extension Notification.Name {
    static let cameraSettingsChanged = Notification.Name("cameraSettingsChanged")
    static let photoCapture = Notification.Name("photoCaptured")
    static let videoRecordingStarted = Notification.Name("videoRecordingStarted")
    static let videoRecordingStopped = Notification.Name("videoRecordingStopped")
}
