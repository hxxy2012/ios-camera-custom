//
//  AIEnhancer.swift
//  ProCam Master
//
//  AI智能增强和参数建议引擎
//  Created by Claude
//

import Foundation
import CoreImage
import UIKit
import Vision

class AIEnhancer {

    // MARK: - Enhancement Result
    struct EnhancementResult {
        let enhancedImage: CIImage
        let adjustments: [Adjustment]
        let beforeHistogram: HistogramData
        let afterHistogram: HistogramData
        let processingTime: TimeInterval

        struct Adjustment {
            let parameter: String
            let originalValue: Float
            let enhancedValue: Float
            let change: Float

            var description: String {
                let changeStr = change > 0 ? "+\(String(format: "%.1f", change))" : String(format: "%.1f", change)
                return "\(parameter): \(String(format: "%.1f", originalValue)) → \(String(format: "%.1f", enhancedValue)) (\(changeStr))"
            }
        }
    }

    // MARK: - Camera Settings Suggestion
    struct SettingsSuggestion {
        let iso: Float?
        let shutterSpeed: CMTime?
        let ev: Float?
        let whiteBalance: Float?
        let focusMode: FocusMode?
        let reason: String

        var hasAdjustments: Bool {
            iso != nil || shutterSpeed != nil || ev != nil || whiteBalance != nil || focusMode != nil
        }
    }

    // MARK: - Private Properties
    private let context = CIContext(options: [.useSoftwareRenderer: false])

    // MARK: - Public Methods

    /// 一键智能增强
    func autoEnhance(image: CIImage) -> EnhancementResult {
        let startTime = Date()
        var enhanced = image
        var adjustments: [EnhancementResult.Adjustment] = []

        // 1. 自动曝光优化
        let (exposureImage, exposureAdj) = autoExposure(image: enhanced)
        enhanced = exposureImage
        if let adj = exposureAdj {
            adjustments.append(adj)
        }

        // 2. 自动对比度
        let (contrastImage, contrastAdj) = autoContrast(image: enhanced)
        enhanced = contrastImage
        if let adj = contrastAdj {
            adjustments.append(adj)
        }

        // 3. 自动色彩平衡
        let (colorImage, colorAdj) = autoColorBalance(image: enhanced)
        enhanced = colorImage
        if let adj = colorAdj {
            adjustments.append(adj)
        }

        // 4. 自动锐化
        let (sharpenImage, sharpenAdj) = autoSharpen(image: enhanced)
        enhanced = sharpenImage
        if let adj = sharpenAdj {
            adjustments.append(adj)
        }

        // 5. 自动降噪（如果需要）
        let (denoiseImage, denoiseAdj) = autoDenoisen(image: enhanced)
        enhanced = denoiseImage
        if let adj = denoiseAdj {
            adjustments.append(adj)
        }

        let processingTime = Date().timeIntervalSince(startTime)

        return EnhancementResult(
            enhancedImage: enhanced,
            adjustments: adjustments,
            beforeHistogram: HistogramData(),  // 需要实际计算
            afterHistogram: HistogramData(),   // 需要实际计算
            processingTime: processingTime
        )
    }

    /// AI曝光建议
    func suggestExposure(for scene: SceneRecognizer.Scene, currentBrightness: Float, iso: Float, shutterSpeed: CMTime) -> SettingsSuggestion {
        var suggestion = SettingsSuggestion(iso: nil, shutterSpeed: nil, ev: nil, whiteBalance: nil, focusMode: nil, reason: "")

        // 基于场景和当前亮度建议参数
        if currentBrightness < 0.2 {
            // 低光环境
            if scene == .night {
                return SettingsSuggestion(
                    iso: 3200,
                    shutterSpeed: CMTime(value: 1, timescale: 15),  // 1/15s
                    ev: 0.7,
                    whiteBalance: 3200,
                    focusMode: .autoSingle,
                    reason: "夜景模式：提高ISO和延长曝光时间，建议使用三脚架"
                )
            } else {
                return SettingsSuggestion(
                    iso: min(1600, iso * 2),
                    shutterSpeed: CMTime(value: 1, timescale: max(30, Int32(1.0 / CMTimeGetSeconds(shutterSpeed) / 2))),
                    ev: 0.5,
                    whiteBalance: nil,
                    focusMode: nil,
                    reason: "低光环境：建议提高ISO或延长曝光"
                )
            }
        } else if currentBrightness > 0.8 {
            // 高光环境
            return SettingsSuggestion(
                iso: max(100, iso / 2),
                shutterSpeed: CMTime(value: 1, timescale: min(8000, Int32(1.0 / CMTimeGetSeconds(shutterSpeed) * 2))),
                ev: -0.5,
                whiteBalance: nil,
                focusMode: nil,
                reason: "高光环境：建议降低ISO或缩短曝光时间"
            )
        }

        return suggestion
    }

    /// AI构图建议
    func suggestComposition(for scene: SceneRecognizer.Scene, faces: [FaceDetector.Face]) -> String {
        switch scene {
        case .portrait:
            if faces.isEmpty {
                return "人像模式：建议将人物放置在画面三分之一位置，注意背景虚化"
            } else {
                return "检测到\(faces.count)个人脸，建议使用眼部对焦，保持眼睛清晰"
            }

        case .landscape:
            return "风景模式：建议使用小光圈增加景深，将地平线放在三分之一位置"

        case .food:
            return "美食模式：建议45度俯拍，使用大光圈虚化背景，注意光线方向"

        case .architecture:
            return "建筑模式：注意垂直线条，避免畸变，尝试对称构图"

        case .sunset:
            return "日落模式：将太阳放在画面三分之一位置，注意剪影效果"

        default:
            return "建议使用三分法构图，保持画面平衡"
        }
    }

    /// AI参数调节建议（实时）
    func suggestParameters(histogram: HistogramData, currentSettings: CameraSettings) -> [String] {
        var suggestions: [String] = []

        // 分析直方图
        let analysis = HistogramProcessor().analyzeExposure(histogram)

        // 过曝建议
        if analysis.isOverexposed {
            suggestions.append("⚠️ 画面过曝\(Int(analysis.overexposedPercent * 100))%")
            suggestions.append("建议：降低ISO或缩短快门速度")
        }

        // 欠曝建议
        if analysis.isUnderexposed {
            suggestions.append("⚠️ 画面欠曝\(Int(analysis.underexposedPercent * 100))%")
            suggestions.append("建议：提高ISO或延长快门速度")
        }

        // 最佳曝光
        if analysis.isWellExposed {
            suggestions.append("✅ 曝光良好")
        }

        // ISO建议
        if currentSettings.exposure.iso > 3200 {
            suggestions.append("💡 高ISO (\(Int(currentSettings.exposure.iso)))可能产生噪点")
        }

        // 快门速度建议（手持安全快门）
        let shutterSeconds = CMTimeGetSeconds(currentSettings.exposure.shutterSpeed)
        let focalLength = currentSettings.zoomFactor * 24  // 假设24mm基准
        let safeShutter = 1.0 / Double(focalLength)

        if shutterSeconds > safeShutter && !currentSettings.focus.isLocked {
            suggestions.append("⚠️ 快门速度较慢，建议使用三脚架或提高快门速度")
        }

        return suggestions
    }

    // MARK: - Private Enhancement Methods

    /// 自动曝光
    private func autoExposure(image: CIImage) -> (CIImage, EnhancementResult.Adjustment?) {
        guard let filter = CIFilter(name: "CIExposureAdjust") else {
            return (image, nil)
        }

        // 分析图像亮度
        let avgBrightness = calculateAverageBrightness(image: image)

        // 计算曝光调整值
        var exposureValue: Float = 0

        if avgBrightness < 0.4 {
            // 偏暗，增加曝光
            exposureValue = Float((0.5 - avgBrightness) * 2)
        } else if avgBrightness > 0.6 {
            // 偏亮，减少曝光
            exposureValue = Float((0.5 - avgBrightness) * 1.5)
        }

        // 限制调整范围
        exposureValue = max(-1.0, min(1.0, exposureValue))

        if abs(exposureValue) < 0.1 {
            return (image, nil)
        }

        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(exposureValue, forKey: kCIInputEVKey)

        guard let output = filter.outputImage else {
            return (image, nil)
        }

        let adjustment = EnhancementResult.Adjustment(
            parameter: "曝光",
            originalValue: 0,
            enhancedValue: exposureValue,
            change: exposureValue
        )

        return (output, adjustment)
    }

    /// 自动对比度
    private func autoContrast(image: CIImage) -> (CIImage, EnhancementResult.Adjustment?) {
        guard let filter = CIFilter(name: "CIColorControls") else {
            return (image, nil)
        }

        // 自动对比度调整（通常增加10-20%）
        let contrastValue: Float = 1.15

        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(contrastValue, forKey: kCIInputContrastKey)

        guard let output = filter.outputImage else {
            return (image, nil)
        }

        let adjustment = EnhancementResult.Adjustment(
            parameter: "对比度",
            originalValue: 1.0,
            enhancedValue: contrastValue,
            change: contrastValue - 1.0
        )

        return (output, adjustment)
    }

    /// 自动色彩平衡
    private func autoColorBalance(image: CIImage) -> (CIImage, EnhancementResult.Adjustment?) {
        guard let filter = CIFilter(name: "CIColorControls") else {
            return (image, nil)
        }

        // 自动饱和度调整（通常增加5-15%）
        let saturationValue: Float = 1.1

        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(saturationValue, forKey: kCIInputSaturationKey)

        guard let output = filter.outputImage else {
            return (image, nil)
        }

        let adjustment = EnhancementResult.Adjustment(
            parameter: "饱和度",
            originalValue: 1.0,
            enhancedValue: saturationValue,
            change: saturationValue - 1.0
        )

        return (output, adjustment)
    }

    /// 自动锐化
    private func autoSharpen(image: CIImage) -> (CIImage, EnhancementResult.Adjustment?) {
        guard let filter = CIFilter(name: "CISharpenLuminance") else {
            return (image, nil)
        }

        let sharpnessValue: Float = 0.4

        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(sharpnessValue, forKey: kCIInputSharpnessKey)

        guard let output = filter.outputImage else {
            return (image, nil)
        }

        let adjustment = EnhancementResult.Adjustment(
            parameter: "锐化",
            originalValue: 0,
            enhancedValue: sharpnessValue,
            change: sharpnessValue
        )

        return (output, adjustment)
    }

    /// 自动降噪
    private func autoDenoisen(image: CIImage) -> (CIImage, EnhancementResult.Adjustment?) {
        guard let filter = CIFilter(name: "CINoiseReduction") else {
            return (image, nil)
        }

        // 基于图像ISO或亮度决定降噪强度
        let noiseLevel: Float = 0.02

        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(noiseLevel, forKey: "inputNoiseLevel")
        filter.setValue(0.4, forKey: "inputSharpness")

        guard let output = filter.outputImage else {
            return (image, nil)
        }

        let adjustment = EnhancementResult.Adjustment(
            parameter: "降噪",
            originalValue: 0,
            enhancedValue: noiseLevel,
            change: noiseLevel
        )

        return (output, adjustment)
    }

    // MARK: - Helper Methods

    /// 计算平均亮度
    private func calculateAverageBrightness(image: CIImage) -> CGFloat {
        guard let filter = CIFilter(name: "CIAreaAverage") else {
            return 0.5
        }

        let extent = image.extent
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(CIVector(cgRect: extent), forKey: kCIInputExtentKey)

        guard let outputImage = filter.outputImage else {
            return 0.5
        }

        var bitmap = [UInt8](repeating: 0, count: 4)
        context.render(outputImage,
                      toBitmap: &bitmap,
                      rowBytes: 4,
                      bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                      format: .RGBA8,
                      colorSpace: CGColorSpaceCreateDeviceRGB())

        let r = CGFloat(bitmap[0]) / 255.0
        let g = CGFloat(bitmap[1]) / 255.0
        let b = CGFloat(bitmap[2]) / 255.0

        // ITU-R BT.709标准计算亮度
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }
}
