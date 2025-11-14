//
//  SceneRecognizer.swift
//  ProCam Master
//
//  AI场景识别引擎（基于Vision和CoreML）
//  Created by Claude
//

import Foundation
import Vision
import CoreML
import UIKit
import CoreImage

class SceneRecognizer {

    // MARK: - Scene Types
    enum Scene: String, CaseIterable {
        case portrait = "人像"
        case landscape = "风景"
        case night = "夜景"
        case sunset = "日落"
        case food = "美食"
        case pet = "宠物"
        case macro = "微距"
        case architecture = "建筑"
        case sport = "运动"
        case indoor = "室内"
        case outdoor = "户外"
        case beach = "海滩"
        case mountain = "山脉"
        case forest = "森林"
        case city = "城市"
        case flowers = "花卉"
        case document = "文档"
        case text = "文字"
        case snow = "雪景"
        case rain = "雨天"

        var icon: String {
            switch self {
            case .portrait: return "person.fill"
            case .landscape: return "photo.on.rectangle"
            case .night: return "moon.stars.fill"
            case .sunset: return "sunset.fill"
            case .food: return "fork.knife"
            case .pet: return "pawprint.fill"
            case .macro: return "camera.macro"
            case .architecture: return "building.2.fill"
            case .sport: return "figure.run"
            case .indoor: return "house.fill"
            case .outdoor: return "tree.fill"
            case .beach: return "beach.umbrella.fill"
            case .mountain: return "mountain.2.fill"
            case .forest: return "leaf.fill"
            case .city: return "building.2.crop.circle"
            case .flowers: return "camera.filters"
            case .document: return "doc.text.fill"
            case .text: return "text.viewfinder"
            case .snow: return "snowflake"
            case .rain: return "cloud.rain.fill"
            }
        }

        var suggestedSettings: SceneSuggestion {
            switch self {
            case .portrait:
                return SceneSuggestion(
                    iso: 200,
                    shutterSpeed: 1/125,
                    aperture: .wide,
                    focusMode: .continuousFocus,
                    whiteBalance: 5500,
                    description: "人像模式：低ISO，快速快门，大光圈虚化背景"
                )
            case .landscape:
                return SceneSuggestion(
                    iso: 100,
                    shutterSpeed: 1/250,
                    aperture: .narrow,
                    focusMode: .autoFocus,
                    whiteBalance: 5500,
                    description: "风景模式：低ISO，小光圈提高景深"
                )
            case .night:
                return SceneSuggestion(
                    iso: 3200,
                    shutterSpeed: 1/30,
                    aperture: .wide,
                    focusMode: .autoFocus,
                    whiteBalance: 3200,
                    description: "夜景模式：高ISO，慢快门，建议使用三脚架"
                )
            case .sunset:
                return SceneSuggestion(
                    iso: 200,
                    shutterSpeed: 1/250,
                    aperture: .medium,
                    focusMode: .autoFocus,
                    whiteBalance: 5000,
                    description: "日落模式：适中参数，偏暖色温"
                )
            case .food:
                return SceneSuggestion(
                    iso: 400,
                    shutterSpeed: 1/60,
                    aperture: .wide,
                    focusMode: .autoFocus,
                    whiteBalance: 4500,
                    description: "美食模式：大光圈突出主体，偏暖色温"
                )
            case .macro:
                return SceneSuggestion(
                    iso: 200,
                    shutterSpeed: 1/250,
                    aperture: .medium,
                    focusMode: .manualFocus,
                    whiteBalance: 5500,
                    description: "微距模式：手动对焦，快速快门防抖"
                )
            default:
                return SceneSuggestion(
                    iso: 200,
                    shutterSpeed: 1/125,
                    aperture: .medium,
                    focusMode: .autoFocus,
                    whiteBalance: 5500,
                    description: "自动模式"
                )
            }
        }
    }

    // MARK: - Scene Suggestion
    struct SceneSuggestion {
        let iso: Float
        let shutterSpeed: Double  // 分母（例如125表示1/125秒）
        let aperture: Aperture
        let focusMode: FocusMode
        let whiteBalance: Float  // Kelvin
        let description: String

        enum Aperture {
            case wide      // f/1.78
            case medium    // f/2.8
            case narrow    // f/4+
        }
    }

    // MARK: - Recognition Result
    struct RecognitionResult {
        let scene: Scene
        let confidence: Float
        let suggestions: SceneSuggestion
        let timestamp: Date

        var isConfident: Bool {
            confidence > 0.7
        }
    }

    // MARK: - Private Properties
    private var currentRequest: VNRequest?

    // MARK: - Public Methods

    /// 识别场景（从像素缓冲区）
    func recognizeScene(from pixelBuffer: CVPixelBuffer, completion: @escaping (RecognitionResult?) -> Void) {
        // 使用Vision框架的场景分类
        let request = VNClassifyImageRequest { request, error in
            if let error = error {
                print("场景识别失败: \(error)")
                completion(nil)
                return
            }

            guard let observations = request.results as? [VNClassificationObservation],
                  let topResult = observations.first else {
                completion(nil)
                return
            }

            // 映射Vision的分类到我们的场景类型
            let scene = self.mapVisionClassToScene(topResult.identifier)
            let result = RecognitionResult(
                scene: scene,
                confidence: topResult.confidence,
                suggestions: scene.suggestedSettings,
                timestamp: Date()
            )

            completion(result)
        }

        // 配置请求
        request.imageCropAndScaleOption = .centerCrop

        // 执行请求
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
        }
    }

    /// 识别场景（从UIImage）
    func recognizeScene(from image: UIImage, completion: @escaping (RecognitionResult?) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(nil)
            return
        }

        let request = VNClassifyImageRequest { request, error in
            if let error = error {
                print("场景识别失败: \(error)")
                completion(nil)
                return
            }

            guard let observations = request.results as? [VNClassificationObservation],
                  let topResult = observations.first else {
                completion(nil)
                return
            }

            let scene = self.mapVisionClassToScene(topResult.identifier)
            let result = RecognitionResult(
                scene: scene,
                confidence: topResult.confidence,
                suggestions: scene.suggestedSettings,
                timestamp: Date()
            )

            completion(result)
        }

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
        }
    }

    /// 分析场景亮度
    func analyzeBrightness(from pixelBuffer: CVPixelBuffer) -> Float {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            return 0.5
        }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let buffer = baseAddress.assumingMemoryBound(to: UInt8.self)

        var totalBrightness: UInt64 = 0
        var sampleCount: UInt64 = 0

        // 采样（每16个像素采样1个）
        for y in stride(from: 0, to: height, by: 16) {
            for x in stride(from: 0, to: width, by: 16) {
                let pixelIndex = y * bytesPerRow + x * 4
                let b = buffer[pixelIndex]
                let g = buffer[pixelIndex + 1]
                let r = buffer[pixelIndex + 2]

                // 使用ITU-R BT.709标准计算亮度
                let brightness = UInt64(0.2126 * Float(r) + 0.7152 * Float(g) + 0.0722 * Float(b))
                totalBrightness += brightness
                sampleCount += 1
            }
        }

        return sampleCount > 0 ? Float(totalBrightness) / Float(sampleCount) / 255.0 : 0.5
    }

    /// 检测是否为低光环境
    func isLowLight(brightness: Float) -> Bool {
        return brightness < 0.2
    }

    /// 检测是否为高光环境
    func isBrightLight(brightness: Float) -> Bool {
        return brightness > 0.8
    }

    // MARK: - Private Methods

    /// 映射Vision分类到场景类型
    private func mapVisionClassToScene(_ identifier: String) -> Scene {
        let lowercaseId = identifier.lowercased()

        // 人像相关
        if lowercaseId.contains("person") || lowercaseId.contains("face") || lowercaseId.contains("portrait") {
            return .portrait
        }

        // 风景相关
        if lowercaseId.contains("landscape") || lowercaseId.contains("scenic") {
            return .landscape
        }

        // 夜景相关
        if lowercaseId.contains("night") || lowercaseId.contains("dark") {
            return .night
        }

        // 日落相关
        if lowercaseId.contains("sunset") || lowercaseId.contains("sunrise") || lowercaseId.contains("dusk") {
            return .sunset
        }

        // 美食相关
        if lowercaseId.contains("food") || lowercaseId.contains("meal") || lowercaseId.contains("dish") {
            return .food
        }

        // 宠物相关
        if lowercaseId.contains("pet") || lowercaseId.contains("dog") || lowercaseId.contains("cat") || lowercaseId.contains("animal") {
            return .pet
        }

        // 建筑相关
        if lowercaseId.contains("building") || lowercaseId.contains("architecture") || lowercaseId.contains("structure") {
            return .architecture
        }

        // 运动相关
        if lowercaseId.contains("sport") || lowercaseId.contains("athletic") || lowercaseId.contains("action") {
            return .sport
        }

        // 海滩相关
        if lowercaseId.contains("beach") || lowercaseId.contains("ocean") || lowercaseId.contains("sea") {
            return .beach
        }

        // 山脉相关
        if lowercaseId.contains("mountain") || lowercaseId.contains("peak") || lowercaseId.contains("hill") {
            return .mountain
        }

        // 森林相关
        if lowercaseId.contains("forest") || lowercaseId.contains("tree") || lowercaseId.contains("wood") {
            return .forest
        }

        // 城市相关
        if lowercaseId.contains("city") || lowercaseId.contains("urban") || lowercaseId.contains("street") {
            return .city
        }

        // 花卉相关
        if lowercaseId.contains("flower") || lowercaseId.contains("blossom") || lowercaseId.contains("plant") {
            return .flowers
        }

        // 文档相关
        if lowercaseId.contains("document") || lowercaseId.contains("paper") {
            return .document
        }

        // 文字相关
        if lowercaseId.contains("text") || lowercaseId.contains("writing") {
            return .text
        }

        // 雪景相关
        if lowercaseId.contains("snow") || lowercaseId.contains("winter") || lowercaseId.contains("ice") {
            return .snow
        }

        // 室内/户外
        if lowercaseId.contains("indoor") || lowercaseId.contains("interior") {
            return .indoor
        }

        if lowercaseId.contains("outdoor") || lowercaseId.contains("exterior") {
            return .outdoor
        }

        // 默认
        return .landscape
    }
}
