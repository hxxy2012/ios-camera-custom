//
//  RAWProcessor.swift
//  ProCam Master
//
//  ProRAW和DNG图像处理器
//  Created by Claude
//

import Foundation
import CoreImage
import Photos
import UIKit

class RAWProcessor {

    // MARK: - RAW Adjustments
    struct RAWAdjustments {
        // 基础调整
        var exposure: Float = 0.0           // -5 ~ +5 EV
        var contrast: Float = 0.0           // -100 ~ +100
        var highlights: Float = 0.0         // -100 ~ +100
        var shadows: Float = 0.0            // -100 ~ +100
        var whites: Float = 0.0             // -100 ~ +100
        var blacks: Float = 0.0             // -100 ~ +100

        // 色调
        var temperature: Float = 0.0        // -100 ~ +100 (相对于原始值)
        var tint: Float = 0.0               // -100 ~ +100

        // 细节
        var clarity: Float = 0.0            // -100 ~ +100
        var texture: Float = 0.0            // -100 ~ +100
        var vibrance: Float = 0.0           // -100 ~ +100
        var saturation: Float = 0.0         // -100 ~ +100

        // 锐化和降噪
        var sharpness: Float = 40.0         // 0 ~ 100
        var noiseReduction: Float = 0.0     // 0 ~ 100

        // 镜头校正
        var distortionCorrection: Bool = true
        var vignetteCorrection: Bool = true
        var chromaticAberrationCorrection: Bool = true

        // 裁剪和旋转
        var cropRect: CGRect? = nil
        var rotation: Float = 0.0           // -180 ~ +180 度

        static var `default`: RAWAdjustments {
            return RAWAdjustments()
        }

        mutating func reset() {
            self = RAWAdjustments.default
        }
    }

    // MARK: - Processing Result
    struct ProcessingResult {
        let processedImage: CIImage
        let originalImage: CIImage
        let adjustments: RAWAdjustments
        let metadata: [String: Any]?
        let processingTime: TimeInterval
    }

    // MARK: - Edit History
    struct EditHistoryStep {
        let adjustments: RAWAdjustments
        let timestamp: Date
        let description: String
    }

    // MARK: - Private Properties
    private let context = CIContext(options: [
        .workingColorSpace: CGColorSpace(name: CGColorSpace.displayP3)!,
        .outputColorSpace: CGColorSpace(name: CGColorSpace.displayP3)!,
        .useSoftwareRenderer: false
    ])

    private var editHistory: [EditHistoryStep] = []
    private let maxHistorySteps = 50

    // MARK: - Public Methods

    /// 加载RAW图像
    func loadRAWImage(from url: URL) -> CIImage? {
        guard let rawFilter = CIFilter(imageURL: url, options: [
            .applyOrientationProperty: true,
            CIRAWFilterOption.allowDraftMode.rawValue: false,
            CIRAWFilterOption.boostAmount.rawValue: 1.0
        ]) else {
            print("无法加载RAW图像")
            return nil
        }

        return rawFilter.outputImage
    }

    /// 处理RAW图像（应用所有调整）
    func processRAW(image: CIImage, adjustments: RAWAdjustments) -> ProcessingResult {
        let startTime = Date()
        var processed = image

        // 1. 基础曝光调整
        processed = applyExposure(to: processed, value: adjustments.exposure)

        // 2. 高光/阴影调整
        processed = applyHighlightsShadows(
            to: processed,
            highlights: adjustments.highlights,
            shadows: adjustments.shadows
        )

        // 3. 白色/黑色调整
        processed = applyWhitesBlacks(
            to: processed,
            whites: adjustments.whites,
            blacks: adjustments.blacks
        )

        // 4. 对比度调整
        processed = applyContrast(to: processed, value: adjustments.contrast)

        // 5. 白平衡调整
        processed = applyWhiteBalance(
            to: processed,
            temperature: adjustments.temperature,
            tint: adjustments.tint
        )

        // 6. 清晰度调整
        if adjustments.clarity != 0 {
            processed = applyClarity(to: processed, value: adjustments.clarity)
        }

        // 7. 纹理调整
        if adjustments.texture != 0 {
            processed = applyTexture(to: processed, value: adjustments.texture)
        }

        // 8. 饱和度和自然饱和度
        processed = applySaturation(
            to: processed,
            vibrance: adjustments.vibrance,
            saturation: adjustments.saturation
        )

        // 9. 锐化
        if adjustments.sharpness > 0 {
            processed = applySharpen(to: processed, amount: adjustments.sharpness)
        }

        // 10. 降噪
        if adjustments.noiseReduction > 0 {
            processed = applyNoiseReduction(to: processed, amount: adjustments.noiseReduction)
        }

        // 11. 镜头校正
        if adjustments.distortionCorrection || adjustments.vignetteCorrection || adjustments.chromaticAberrationCorrection {
            processed = applyLensCorrections(
                to: processed,
                distortion: adjustments.distortionCorrection,
                vignette: adjustments.vignetteCorrection,
                chromatic: adjustments.chromaticAberrationCorrection
            )
        }

        // 12. 裁剪和旋转
        if let cropRect = adjustments.cropRect {
            processed = processed.cropped(to: cropRect)
        }

        if adjustments.rotation != 0 {
            processed = processed.transformed(by: CGAffineTransform(rotationAngle: CGFloat(adjustments.rotation) * .pi / 180))
        }

        let processingTime = Date().timeIntervalSince(startTime)

        return ProcessingResult(
            processedImage: processed,
            originalImage: image,
            adjustments: adjustments,
            metadata: nil,
            processingTime: processingTime
        )
    }

    /// 导出为JPEG/HEIF
    func export(image: CIImage, format: ExportFormat, quality: Float = 0.95, to url: URL) throws {
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        switch format {
        case .jpeg:
            try context.writeJPEGRepresentation(
                of: image,
                to: url,
                colorSpace: colorSpace,
                options: [kCGImageDestinationLossyCompressionQuality as CIImageRepresentationOption: quality]
            )

        case .heif:
            try context.writeHEIFRepresentation(
                of: image,
                to: url,
                format: .RGBA8,
                colorSpace: colorSpace,
                options: [kCGImageDestinationLossyCompressionQuality as CIImageRepresentationOption: quality]
            )

        case .tiff:
            try context.writeTIFFRepresentation(
                of: image,
                to: url,
                format: .RGBA16,
                colorSpace: colorSpace,
                options: [:]
            )

        case .png:
            try context.writePNGRepresentation(
                of: image,
                to: url,
                format: .RGBA8,
                colorSpace: colorSpace,
                options: [:]
            )
        }
    }

    enum ExportFormat {
        case jpeg
        case heif
        case tiff
        case png
    }

    /// 添加到编辑历史
    func addToHistory(adjustments: RAWAdjustments, description: String) {
        let step = EditHistoryStep(
            adjustments: adjustments,
            timestamp: Date(),
            description: description
        )

        editHistory.append(step)

        // 限制历史记录数量
        if editHistory.count > maxHistorySteps {
            editHistory.removeFirst()
        }
    }

    /// 撤销
    func undo() -> RAWAdjustments? {
        guard editHistory.count > 1 else {
            return nil
        }

        editHistory.removeLast()
        return editHistory.last?.adjustments
    }

    /// 清除历史
    func clearHistory() {
        editHistory.removeAll()
    }

    // MARK: - Private Processing Methods

    /// 应用曝光调整
    private func applyExposure(to image: CIImage, value: Float) -> CIImage {
        guard value != 0, let filter = CIFilter(name: "CIExposureAdjust") else {
            return image
        }

        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(value, forKey: kCIInputEVKey)

        return filter.outputImage ?? image
    }

    /// 应用高光/阴影调整
    private func applyHighlightsShadows(to image: CIImage, highlights: Float, shadows: Float) -> CIImage {
        guard highlights != 0 || shadows != 0,
              let filter = CIFilter(name: "CIHighlightShadowAdjust") else {
            return image
        }

        filter.setValue(image, forKey: kCIInputImageKey)

        // 转换范围：-100~100 -> 0~2
        let highlightAmount = 1.0 - (highlights / 100.0)
        let shadowAmount = 1.0 + (shadows / 100.0)

        filter.setValue(highlightAmount, forKey: "inputHighlightAmount")
        filter.setValue(shadowAmount, forKey: "inputShadowAmount")

        return filter.outputImage ?? image
    }

    /// 应用白色/黑色调整
    private func applyWhitesBlacks(to image: CIImage, whites: Float, blacks: Float) -> CIImage {
        guard whites != 0 || blacks != 0,
              let filter = CIFilter(name: "CIWhitePointAdjust") else {
            return image
        }

        filter.setValue(image, forKey: kCIInputImageKey)

        // 白色和黑色点调整
        let whiteColor = CIColor(
            red: 1.0 - CGFloat(whites / 100.0 * 0.2),
            green: 1.0 - CGFloat(whites / 100.0 * 0.2),
            blue: 1.0 - CGFloat(whites / 100.0 * 0.2)
        )

        filter.setValue(whiteColor, forKey: "inputColor")

        return filter.outputImage ?? image
    }

    /// 应用对比度调整
    private func applyContrast(to image: CIImage, value: Float) -> CIImage {
        guard value != 0, let filter = CIFilter(name: "CIColorControls") else {
            return image
        }

        filter.setValue(image, forKey: kCIInputImageKey)

        // 转换范围：-100~100 -> 0~2
        let contrastValue = 1.0 + (value / 100.0)

        filter.setValue(contrastValue, forKey: kCIInputContrastKey)

        return filter.outputImage ?? image
    }

    /// 应用白平衡调整
    private func applyWhiteBalance(to image: CIImage, temperature: Float, tint: Float) -> CIImage {
        guard temperature != 0 || tint != 0,
              let filter = CIFilter(name: "CITemperatureAndTint") else {
            return image
        }

        filter.setValue(image, forKey: kCIInputImageKey)

        // 中性点（6500K）
        let neutral = CIVector(x: 6500, y: 0)

        // 目标点
        let targetTemp = 6500.0 + Double(temperature) * 50.0  // -100~+100 -> 1500K~11500K
        let target = CIVector(x: targetTemp, y: Double(tint))

        filter.setValue(neutral, forKey: "inputNeutral")
        filter.setValue(target, forKey: "inputTargetNeutral")

        return filter.outputImage ?? image
    }

    /// 应用清晰度调整
    private func applyClarity(to image: CIImage, value: Float) -> CIImage {
        guard let filter = CIFilter(name: "CIUnsharpMask") else {
            return image
        }

        filter.setValue(image, forKey: kCIInputImageKey)

        let intensity = abs(value) / 100.0 * 2.0
        filter.setValue(intensity, forKey: kCIInputIntensityKey)
        filter.setValue(10.0, forKey: kCIInputRadiusKey)

        return filter.outputImage ?? image
    }

    /// 应用纹理调整
    private func applyTexture(to image: CIImage, value: Float) -> CIImage {
        guard let filter = CIFilter(name: "CISharpenLuminance") else {
            return image
        }

        filter.setValue(image, forKey: kCIInputImageKey)

        let sharpness = value / 100.0
        filter.setValue(sharpness, forKey: kCIInputSharpnessKey)

        return filter.outputImage ?? image
    }

    /// 应用饱和度调整
    private func applySaturation(to image: CIImage, vibrance: Float, saturation: Float) -> CIImage {
        guard vibrance != 0 || saturation != 0,
              let filter = CIFilter(name: "CIColorControls") else {
            return image
        }

        filter.setValue(image, forKey: kCIInputImageKey)

        // 自然饱和度优先（更智能）
        let finalSaturation = 1.0 + ((vibrance + saturation) / 200.0)
        filter.setValue(finalSaturation, forKey: kCIInputSaturationKey)

        return filter.outputImage ?? image
    }

    /// 应用锐化
    private func applySharpen(to image: CIImage, amount: Float) -> CIImage {
        guard let filter = CIFilter(name: "CISharpenLuminance") else {
            return image
        }

        filter.setValue(image, forKey: kCIInputImageKey)

        let sharpness = amount / 100.0 * 2.0
        filter.setValue(sharpness, forKey: kCIInputSharpnessKey)

        return filter.outputImage ?? image
    }

    /// 应用降噪
    private func applyNoiseReduction(to image: CIImage, amount: Float) -> CIImage {
        guard let filter = CIFilter(name: "CINoiseReduction") else {
            return image
        }

        filter.setValue(image, forKey: kCIInputImageKey)

        let noiseLevel = amount / 100.0 * 0.1
        filter.setValue(noiseLevel, forKey: "inputNoiseLevel")
        filter.setValue(0.4, forKey: "inputSharpness")

        return filter.outputImage ?? image
    }

    /// 应用镜头校正
    private func applyLensCorrections(to image: CIImage, distortion: Bool, vignette: Bool, chromatic: Bool) -> CIImage {
        var corrected = image

        // 暗角校正
        if vignette, let filter = CIFilter(name: "CIVignetteEffect") {
            filter.setValue(corrected, forKey: kCIInputImageKey)
            filter.setValue(-1.0, forKey: kCIInputIntensityKey)  // 负值去除暗角
            filter.setValue(2.0, forKey: kCIInputRadiusKey)
            corrected = filter.outputImage ?? corrected
        }

        // 畸变校正（简化版）
        // 实际应用中需要根据镜头型号应用特定的校正配置

        return corrected
    }
}
