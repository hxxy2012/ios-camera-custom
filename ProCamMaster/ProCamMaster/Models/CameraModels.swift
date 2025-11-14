//
//  CameraModels.swift
//  ProCam Master
//
//  相机数据模型定义
//  Created by Claude
//

import Foundation
import AVFoundation
import CoreGraphics

// MARK: - 拍摄模式
enum ShootingMode: String, CaseIterable, Identifiable {
    case photo = "照片"
    case video = "视频"
    case proRAW = "ProRAW"
    case portrait = "人像"
    case night = "夜景"
    case panorama = "全景"
    case timeLapse = "延时"
    case longExposure = "长曝光"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .photo: return "camera.fill"
        case .video: return "video.fill"
        case .proRAW: return "camera.aperture"
        case .portrait: return "person.crop.circle"
        case .night: return "moon.stars.fill"
        case .panorama: return "pano.fill"
        case .timeLapse: return "timer"
        case .longExposure: return "camera.shutter.button"
        }
    }
}

// MARK: - 对焦模式
enum FocusMode: String, CaseIterable, Identifiable {
    case autoSingle = "AF-S"
    case autoContinuous = "AF-C"
    case manual = "MF"

    var id: String { rawValue }

    var avMode: AVCaptureDevice.FocusMode {
        switch self {
        case .autoSingle: return .autoFocus
        case .autoContinuous: return .continuousFocus
        case .manual: return .locked
        }
    }

    var description: String {
        switch self {
        case .autoSingle: return "单次自动对焦"
        case .autoContinuous: return "连续自动对焦"
        case .manual: return "手动对焦"
        }
    }
}

// MARK: - 测光模式
enum MeteringMode: String, CaseIterable, Identifiable {
    case multiPattern = "评价测光"
    case centerWeighted = "中央重点"
    case spot = "点测光"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .multiPattern: return "square.grid.3x3"
        case .centerWeighted: return "circle.circle"
        case .spot: return "scope"
        }
    }
}

// MARK: - 白平衡预设
enum WhiteBalancePreset: String, CaseIterable, Identifiable {
    case auto = "自动"
    case daylight = "日光"
    case cloudy = "阴天"
    case shade = "阴影"
    case tungsten = "钨丝灯"
    case fluorescent = "荧光灯"
    case flash = "闪光灯"
    case custom = "自定义"

    var id: String { rawValue }

    var kelvin: Float {
        switch self {
        case .auto: return 5500
        case .daylight: return 5500
        case .cloudy: return 6500
        case .shade: return 7500
        case .tungsten: return 3200
        case .fluorescent: return 4000
        case .flash: return 5500
        case .custom: return 5500
        }
    }

    var icon: String {
        switch self {
        case .auto: return "wand.and.stars"
        case .daylight: return "sun.max.fill"
        case .cloudy: return "cloud.fill"
        case .shade: return "cloud.sun.fill"
        case .tungsten: return "lightbulb.fill"
        case .fluorescent: return "lightbulb"
        case .flash: return "bolt.fill"
        case .custom: return "slider.horizontal.3"
        }
    }
}

// MARK: - 摄像头类型
enum CameraType: String, CaseIterable, Identifiable {
    case ultraWide = "超广角"
    case wide = "广角"
    case telephoto2x = "2x长焦"
    case telephoto3x = "3x长焦"
    case telephoto5x = "5x长焦"
    case front = "前置"

    var id: String { rawValue }

    var deviceType: AVCaptureDevice.DeviceType {
        switch self {
        case .ultraWide: return .builtInUltraWideCamera
        case .wide: return .builtInWideAngleCamera
        case .telephoto2x, .telephoto3x, .telephoto5x: return .builtInTelephotoCamera
        case .front: return .builtInWideAngleCamera
        }
    }

    var zoomFactor: CGFloat {
        switch self {
        case .ultraWide: return 0.5
        case .wide: return 1.0
        case .telephoto2x: return 2.0
        case .telephoto3x: return 3.0
        case .telephoto5x: return 5.0
        case .front: return 1.0
        }
    }

    var focalLength: String {
        switch self {
        case .ultraWide: return "13mm"
        case .wide: return "24mm"
        case .telephoto2x: return "48mm"
        case .telephoto3x: return "77mm"
        case .telephoto5x: return "120mm"
        case .front: return "12mm"
        }
    }

    var icon: String {
        switch self {
        case .ultraWide: return "0.5"
        case .wide: return "1×"
        case .telephoto2x: return "2×"
        case .telephoto3x: return "3×"
        case .telephoto5x: return "5×"
        case .front: return "arrow.triangle.2.circlepath.camera"
        }
    }
}

// MARK: - 网格线类型
enum GridType: String, CaseIterable, Identifiable {
    case none = "无网格"
    case ruleOfThirds = "三分法"
    case goldenRatio = "黄金分割"
    case diagonal = "对角线"
    case square = "方格"
    case center = "中心十字"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .none: return "square"
        case .ruleOfThirds: return "square.grid.3x3"
        case .goldenRatio: return "grid"
        case .diagonal: return "line.diagonal"
        case .square: return "square.grid.4x3.fill"
        case .center: return "plus.square"
        }
    }
}

// MARK: - 曝光参数
struct ExposureSettings {
    var iso: Float = 100
    var shutterSpeed: CMTime = CMTime(value: 1, timescale: 125) // 1/125s
    var exposureCompensation: Float = 0.0 // EV
    var isAutoISO: Bool = false
    var isAutoShutter: Bool = false

    var shutterSpeedString: String {
        let seconds = CMTimeGetSeconds(shutterSpeed)
        if seconds >= 1 {
            return String(format: "%.1f\"", seconds)
        } else {
            return "1/\(Int(1/seconds))"
        }
    }

    var evString: String {
        if exposureCompensation == 0 {
            return "0"
        } else if exposureCompensation > 0 {
            return String(format: "+%.1f", exposureCompensation)
        } else {
            return String(format: "%.1f", exposureCompensation)
        }
    }
}

// MARK: - 对焦设置
struct FocusSettings {
    var mode: FocusMode = .autoSingle
    var lensPosition: Float = 0.5 // 0.0 (近) - 1.0 (远)
    var focusPoint: CGPoint = CGPoint(x: 0.5, y: 0.5)
    var isLocked: Bool = false
    var isPeakingEnabled: Bool = true
    var peakingColor: PeakingColor = .green

    enum PeakingColor: String, CaseIterable {
        case red = "红色"
        case yellow = "黄色"
        case green = "绿色"
        case blue = "蓝色"
    }
}

// MARK: - 白平衡设置
struct WhiteBalanceSettings {
    var preset: WhiteBalancePreset = .auto
    var temperature: Float = 5500 // Kelvin
    var tint: Float = 0 // -150 ~ +150
    var isLocked: Bool = false

    var temperatureString: String {
        return "\(Int(temperature))K"
    }
}

// MARK: - 相机设置
struct CameraSettings {
    var shootingMode: ShootingMode = .photo
    var exposure: ExposureSettings = ExposureSettings()
    var focus: FocusSettings = FocusSettings()
    var whiteBalance: WhiteBalanceSettings = WhiteBalanceSettings()
    var meteringMode: MeteringMode = .multiPattern
    var gridType: GridType = .ruleOfThirds
    var currentCamera: CameraType = .wide
    var zoomFactor: CGFloat = 1.0

    // ProRAW设置
    var isProRAWEnabled: Bool = false
    var proRAWResolution: ProRAWResolution = .mp48

    // 显示设置
    var isHistogramVisible: Bool = true
    var isLevelVisible: Bool = true
    var isInfoOverlayVisible: Bool = true

    enum ProRAWResolution: String, CaseIterable {
        case mp12 = "12MP"
        case mp48 = "48MP"
    }
}

// MARK: - 拍摄结果
struct CaptureResult {
    var imageData: Data?
    var metadata: [String: Any]?
    var error: Error?
    var timestamp: Date = Date()
}

// MARK: - 场景识别结果
struct SceneRecognition {
    var sceneType: SceneType
    var confidence: Float
    var suggestedSettings: CameraSettings?

    enum SceneType: String {
        case unknown = "未知"
        case portrait = "人像"
        case landscape = "风景"
        case night = "夜景"
        case sunset = "日落"
        case food = "美食"
        case pet = "宠物"
        case macro = "微距"
        case architecture = "建筑"
        case sport = "运动"
    }
}

// MARK: - 直方图数据
struct HistogramData {
    var red: [CGFloat]
    var green: [CGFloat]
    var blue: [CGFloat]
    var luminance: [CGFloat]

    init() {
        self.red = Array(repeating: 0, count: 256)
        self.green = Array(repeating: 0, count: 256)
        self.blue = Array(repeating: 0, count: 256)
        self.luminance = Array(repeating: 0, count: 256)
    }
}

// MARK: - 相机能力
struct CameraCapabilities {
    var minISO: Float
    var maxISO: Float
    var minShutterSpeed: CMTime
    var maxShutterSpeed: CMTime
    var minExposureCompensation: Float
    var maxExposureCompensation: Float
    var hasUltraWide: Bool
    var hasTelephoto: Bool
    var supportsProRAW: Bool
    var supports48MP: Bool
    var hasLiDAR: Bool

    static let `default` = CameraCapabilities(
        minISO: 25,
        maxISO: 3200,
        minShutterSpeed: CMTime(value: 1, timescale: 32000),
        maxShutterSpeed: CMTime(value: 30, timescale: 1),
        minExposureCompensation: -3.0,
        maxExposureCompensation: 3.0,
        hasUltraWide: false,
        hasTelephoto: false,
        supportsProRAW: false,
        supports48MP: false,
        hasLiDAR: false
    )
}
