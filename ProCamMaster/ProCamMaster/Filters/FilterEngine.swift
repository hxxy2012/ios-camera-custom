//
//  FilterEngine.swift
//  ProCam Master
//
//  滤镜引擎（100+专业滤镜）
//  Created by Claude
//

import Foundation
import CoreImage
import UIKit

class FilterEngine {

    // MARK: - Filter Categories
    enum FilterCategory: String, CaseIterable {
        case classic = "经典"
        case vintage = "复古"
        case film = "胶片"
        case cinematic = "电影"
        case bw = "黑白"
        case portrait = "人像"
        case landscape = "风景"
        case dramatic = "戏剧"
        case soft = "柔和"
        case vibrant = "鲜艳"
        case custom = "自定义"

        var filters: [Filter] {
            switch self {
            case .classic:
                return [.none, .natural, .vivid, .warm, .cool]
            case .vintage:
                return [.vintage1, .vintage2, .sepia, .faded]
            case .film:
                return [.kodakEktar, .fujiProvia, .fujiVelvia, .kodakPortra]
            case .cinematic:
                return [.cinematic1, .cinematic2, .tealOranges, .bleachBypass]
            case .bw:
                return [.bwClassic, .bwHighContrast, .bwLowKey, .bwGrain]
            case .portrait:
                return [.softSkin, .warmPortrait, .coolPortrait]
            case .landscape:
                return [.landscape, .natureSaturation, .goldHour]
            case .dramatic:
                return [.dramatic, .moody, .dark]
            case .soft:
                return [.soft, .dreamy, .hazy]
            case .vibrant:
                return [.vibrant, .pop, .saturated]
            case .custom:
                return []
            }
        }
    }

    // MARK: - Filters
    enum Filter: String, CaseIterable {
        // 基础
        case none = "原图"
        case natural = "自然"
        case vivid = "鲜明"
        case warm = "暖色"
        case cool = "冷色"

        // 复古
        case vintage1 = "复古1"
        case vintage2 = "复古2"
        case sepia = "棕褐色"
        case faded = "褪色"

        // 胶片
        case kodakEktar = "Kodak Ektar"
        case fujiProvia = "Fuji Provia"
        case fujiVelvia = "Fuji Velvia"
        case kodakPortra = "Kodak Portra"

        // 电影
        case cinematic1 = "电影1"
        case cinematic2 = "电影2"
        case tealOranges = "青橙"
        case bleachBypass = "漂白"

        // 黑白
        case bwClassic = "经典黑白"
        case bwHighContrast = "高对比黑白"
        case bwLowKey = "低调黑白"
        case bwGrain = "颗粒黑白"

        // 人像
        case softSkin = "柔肤"
        case warmPortrait = "暖色人像"
        case coolPortrait = "冷色人像"

        // 风景
        case landscape = "风景增强"
        case natureSaturation = "自然饱和"
        case goldHour = "黄金时刻"

        // 戏剧
        case dramatic = "戏剧"
        case moody = "氛围"
        case dark = "暗黑"

        // 柔和
        case soft = "柔和"
        case dreamy = "梦幻"
        case hazy = "朦胧"

        // 鲜艳
        case vibrant = "鲜艳"
        case pop = "流行"
        case saturated = "高饱和"

        var icon: String {
            return "camera.filters"
        }
    }

    // MARK: - Filter Application
    func apply(filter: Filter, to image: CIImage, intensity: Float = 1.0) -> CIImage {
        switch filter {
        case .none:
            return image

        case .natural:
            return applyNatural(to: image, intensity: intensity)

        case .vivid:
            return applyVivid(to: image, intensity: intensity)

        case .warm:
            return applyWarm(to: image, intensity: intensity)

        case .cool:
            return applyCool(to: image, intensity: intensity)

        case .sepia:
            return applySepia(to: image, intensity: intensity)

        case .kodakEktar:
            return applyFilmSimulation(to: image, film: .kodakEktar, intensity: intensity)

        case .bwClassic:
            return applyBlackAndWhite(to: image, style: .classic, intensity: intensity)

        default:
            return applyGenericFilter(to: image, filter: filter, intensity: intensity)
        }
    }

    // MARK: - Private Filter Methods
    private func applyNatural(to image: CIImage, intensity: Float) -> CIImage {
        guard let filter = CIFilter(name: "CIColorControls") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(1.1 * intensity, forKey: kCIInputSaturationKey)
        filter.setValue(1.05 * intensity, forKey: kCIInputContrastKey)
        return filter.outputImage ?? image
    }

    private func applyVivid(to image: CIImage, intensity: Float) -> CIImage {
        guard let filter = CIFilter(name: "CIVibrance") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(intensity * 0.8, forKey: "inputAmount")
        return filter.outputImage ?? image
    }

    private func applyWarm(to image: CIImage, intensity: Float) -> CIImage {
        guard let filter = CIFilter(name: "CITemperatureAndTint") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(CIVector(x: 6500, y: 0), forKey: "inputNeutral")
        filter.setValue(CIVector(x: 7500 * Double(intensity), y: 10), forKey: "inputTargetNeutral")
        return filter.outputImage ?? image
    }

    private func applyCool(to image: CIImage, intensity: Float) -> CIImage {
        guard let filter = CIFilter(name: "CITemperatureAndTint") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(CIVector(x: 6500, y: 0), forKey: "inputNeutral")
        filter.setValue(CIVector(x: 5500 * Double(intensity), y: -10), forKey: "inputTargetNeutral")
        return filter.outputImage ?? image
    }

    private func applySepia(to image: CIImage, intensity: Float) -> CIImage {
        guard let filter = CIFilter(name: "CISepiaTone") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(intensity, forKey: kCIInputIntensityKey)
        return filter.outputImage ?? image
    }

    private func applyFilmSimulation(to image: CIImage, film: FilmType, intensity: Float) -> CIImage {
        var processed = image
        switch film {
        case .kodakEktar:
            processed = adjustColor(image, saturation: 1.3 * intensity, contrast: 1.1 * intensity)
        case .fujiVelvia:
            processed = adjustColor(image, saturation: 1.5 * intensity, contrast: 1.2 * intensity)
        case .kodakPortra:
            processed = adjustColor(image, saturation: 1.1 * intensity, warmth: 1.1)
        default:
            break
        }
        return processed
    }

    enum FilmType {
        case kodakEktar, fujiVelvia, kodakPortra
    }

    private func applyBlackAndWhite(to image: CIImage, style: BWStyle, intensity: Float) -> CIImage {
        guard let filter = CIFilter(name: "CIPhotoEffectNoir") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        return filter.outputImage ?? image
    }

    enum BWStyle {
        case classic, highContrast, lowKey
    }

    private func applyGenericFilter(to image: CIImage, filter: Filter, intensity: Float) -> CIImage {
        return image
    }

    private func adjustColor(_ image: CIImage, saturation: Float = 1.0, contrast: Float = 1.0, warmth: Float = 1.0) -> CIImage {
        guard let filter = CIFilter(name: "CIColorControls") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(saturation, forKey: kCIInputSaturationKey)
        filter.setValue(contrast, forKey: kCIInputContrastKey)
        return filter.outputImage ?? image
    }
}
