//
//  HistogramProcessor.swift
//  ProCam Master
//
//  直方图数据处理器
//  Created by Claude
//

import Foundation
import CoreImage
import UIKit
import Accelerate

class HistogramProcessor {

    /// 从图像生成直方图数据
    func generateHistogram(from image: CIImage) -> HistogramData {
        var histogramData = HistogramData()

        // 使用Core Image生成直方图
        guard let filter = CIFilter(name: "CIAreaHistogram") else {
            return histogramData
        }

        // 配置滤镜
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(256, forKey: "inputCount")
        filter.setValue(CIVector(x: 0, y: 0, z: image.extent.width, w: image.extent.height),
                       forKey: "inputExtent")

        guard let outputImage = filter.outputImage else {
            return histogramData
        }

        // 创建上下文
        let context = CIContext()

        // 提取直方图数据
        let rect = CGRect(x: 0, y: 0, width: 256, height: 1)
        var bitmap = [UInt8](repeating: 0, count: 256 * 4)

        context.render(outputImage,
                      toBitmap: &bitmap,
                      rowBytes: 256 * 4,
                      bounds: rect,
                      format: .RGBA8,
                      colorSpace: CGColorSpaceCreateDeviceRGB())

        // 解析数据
        for i in 0..<256 {
            let index = i * 4
            histogramData.red[i] = CGFloat(bitmap[index])
            histogramData.green[i] = CGFloat(bitmap[index + 1])
            histogramData.blue[i] = CGFloat(bitmap[index + 2])
            histogramData.luminance[i] = CGFloat(bitmap[index + 3])
        }

        // 归一化
        histogramData = normalize(histogramData)

        return histogramData
    }

    /// 从像素缓冲区生成直方图
    func generateHistogram(from pixelBuffer: CVPixelBuffer) -> HistogramData {
        var histogramData = HistogramData()

        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            return histogramData
        }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let pixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer)

        // 根据像素格式处理
        if pixelFormat == kCVPixelFormatType_32BGRA {
            let buffer = baseAddress.assumingMemoryBound(to: UInt8.self)

            var redBins = [UInt](repeating: 0, count: 256)
            var greenBins = [UInt](repeating: 0, count: 256)
            var blueBins = [UInt](repeating: 0, count: 256)

            // 采样像素（每4个像素采样1个以提高性能）
            for y in stride(from: 0, to: height, by: 4) {
                for x in stride(from: 0, to: width, by: 4) {
                    let pixelIndex = y * bytesPerRow + x * 4

                    let b = buffer[pixelIndex]
                    let g = buffer[pixelIndex + 1]
                    let r = buffer[pixelIndex + 2]

                    redBins[Int(r)] += 1
                    greenBins[Int(g)] += 1
                    blueBins[Int(b)] += 1
                }
            }

            // 转换为CGFloat数组
            for i in 0..<256 {
                histogramData.red[i] = CGFloat(redBins[i])
                histogramData.green[i] = CGFloat(greenBins[i])
                histogramData.blue[i] = CGFloat(blueBins[i])

                // 计算亮度（加权平均）
                let lum = 0.299 * Double(redBins[i]) +
                         0.587 * Double(greenBins[i]) +
                         0.114 * Double(blueBins[i])
                histogramData.luminance[i] = CGFloat(lum)
            }
        }

        // 归一化
        histogramData = normalize(histogramData)

        return histogramData
    }

    /// 归一化直方图数据
    private func normalize(_ data: HistogramData) -> HistogramData {
        var normalized = data

        // 找到最大值
        let maxRed = data.red.max() ?? 1
        let maxGreen = data.green.max() ?? 1
        let maxBlue = data.blue.max() ?? 1
        let maxLum = data.luminance.max() ?? 1

        // 归一化到0-1范围
        for i in 0..<256 {
            normalized.red[i] = data.red[i] / maxRed
            normalized.green[i] = data.green[i] / maxGreen
            normalized.blue[i] = data.blue[i] / maxBlue
            normalized.luminance[i] = data.luminance[i] / maxLum
        }

        return normalized
    }

    /// 分析曝光（基于直方图）
    func analyzeExposure(_ histogram: HistogramData) -> ExposureAnalysis {
        let luminance = histogram.luminance

        // 计算过曝像素百分比（亮度>90%）
        let overexposedCount = luminance[230...255].reduce(0, +)
        let overexposedPercent = overexposedCount / luminance.reduce(0, +)

        // 计算欠曝像素百分比（亮度<10%）
        let underexposedCount = luminance[0...25].reduce(0, +)
        let underexposedPercent = underexposedCount / luminance.reduce(0, +)

        // 计算平均亮度
        var weightedSum: CGFloat = 0
        var totalSum: CGFloat = 0
        for i in 0..<256 {
            weightedSum += CGFloat(i) * luminance[i]
            totalSum += luminance[i]
        }
        let averageBrightness = totalSum > 0 ? weightedSum / totalSum / 255.0 : 0

        return ExposureAnalysis(
            overexposedPercent: overexposedPercent,
            underexposedPercent: underexposedPercent,
            averageBrightness: averageBrightness
        )
    }
}

// MARK: - 曝光分析结果
struct ExposureAnalysis {
    let overexposedPercent: CGFloat
    let underexposedPercent: CGFloat
    let averageBrightness: CGFloat

    var isOverexposed: Bool {
        overexposedPercent > 0.05 // 超过5%
    }

    var isUnderexposed: Bool {
        underexposedPercent > 0.05 // 超过5%
    }

    var isWellExposed: Bool {
        !isOverexposed && !isUnderexposed && (0.4...0.6).contains(averageBrightness)
    }
}
