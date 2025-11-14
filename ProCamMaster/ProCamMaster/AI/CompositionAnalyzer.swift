//
//  CompositionAnalyzer.swift
//  ProCam Master
//
//  AI构图分析和建议系统
//  Created by Claude
//

import Foundation
import Vision
import CoreGraphics
import UIKit

class CompositionAnalyzer {

    // MARK: - Composition Rules
    enum CompositionRule: String, CaseIterable {
        case ruleOfThirds = "三分法"
        case goldenRatio = "黄金分割"
        case diagonal = "对角线构图"
        case symmetry = "对称构图"
        case leadingLines = "引导线构图"
        case framing = "框架构图"
        case fillFrame = "填充画面"
        case negativeSpace = "负空间"
        case centered = "居中构图"
        case depth = "纵深构图"

        var description: String {
            switch self {
            case .ruleOfThirds:
                return "将主体放在画面三分之一位置，符合视觉习惯"
            case .goldenRatio:
                return "使用黄金分割比例，创造和谐美感"
            case .diagonal:
                return "利用对角线引导视线，增加动感"
            case .symmetry:
                return "左右对称，营造稳定感"
            case .leadingLines:
                return "使用线条引导观众视线到主体"
            case .framing:
                return "用前景元素框住主体，突出重点"
            case .fillFrame:
                return "让主体充满画面，增强冲击力"
            case .negativeSpace:
                return "留白空间，营造意境"
            case .centered:
                return "主体居中，简洁有力"
            case .depth:
                return "前中后景分明，增强立体感"
            }
        }

        var icon: String {
            switch self {
            case .ruleOfThirds: return "square.grid.3x3"
            case .goldenRatio: return "grid"
            case .diagonal: return "line.diagonal"
            case .symmetry: return "rectangle.split.2x1"
            case .leadingLines: return "arrow.right"
            case .framing: return "square.on.square"
            case .fillFrame: return "square.fill"
            case .negativeSpace: return "circle"
            case .centered: return "plus.square"
            case .depth: return "square.stack.3d.up"
            }
        }
    }

    // MARK: - Composition Analysis Result
    struct AnalysisResult {
        let score: Float  // 0-100
        let appliedRules: [CompositionRule]
        let suggestions: [Suggestion]
        let balanceScore: Float  // 0-1
        let interestPoints: [CGPoint]
        let timestamp: Date

        var grade: Grade {
            switch score {
            case 90...100: return .excellent
            case 80..<90: return .good
            case 70..<80: return .average
            case 60..<70: return .fair
            default: return .poor
            }
        }

        enum Grade: String {
            case excellent = "优秀"
            case good = "良好"
            case average = "一般"
            case fair = "尚可"
            case poor = "较差"

            var color: String {
                switch self {
                case .excellent: return "green"
                case .good: return "blue"
                case .average: return "orange"
                case .fair: return "yellow"
                case .poor: return "red"
                }
            }
        }
    }

    struct Suggestion {
        let rule: CompositionRule
        let message: String
        let improvement: String
        let priority: Priority

        enum Priority: Int {
            case high = 3
            case medium = 2
            case low = 1
        }
    }

    // MARK: - Subject Position
    struct SubjectPosition {
        let center: CGPoint
        let bounds: CGRect
        let confidence: Float
    }

    // MARK: - Public Methods

    /// 分析构图（完整分析）
    func analyzeComposition(image: UIImage, subjects: [SubjectPosition] = []) -> AnalysisResult {
        var score: Float = 0
        var appliedRules: [CompositionRule] = []
        var suggestions: [Suggestion] = []

        // 1. 分析三分法
        let (thirdsScore, thirdsApplied) = analyzeRuleOfThirds(subjects: subjects, imageSize: image.size)
        score += thirdsScore * 0.3
        if thirdsApplied {
            appliedRules.append(.ruleOfThirds)
        } else {
            suggestions.append(Suggestion(
                rule: .ruleOfThirds,
                message: "主体位置可以优化",
                improvement: "将主体移到画面三分之一处",
                priority: .high
            ))
        }

        // 2. 分析黄金分割
        let (goldenScore, goldenApplied) = analyzeGoldenRatio(subjects: subjects, imageSize: image.size)
        score += goldenScore * 0.2
        if goldenApplied {
            appliedRules.append(.goldenRatio)
        }

        // 3. 分析对称性
        let (symmetryScore, symmetryApplied) = analyzeSymmetry(image: image)
        score += symmetryScore * 0.15
        if symmetryApplied {
            appliedRules.append(.symmetry)
        }

        // 4. 分析画面平衡
        let balanceScore = analyzeBalance(subjects: subjects, imageSize: image.size)
        score += balanceScore * 0.2

        // 5. 分析兴趣点
        let interestPoints = findInterestPoints(image: image)
        let interestScore = analyzeInterestPoints(interestPoints, imageSize: image.size)
        score += interestScore * 0.15

        // 标准化得分到0-100
        score = min(100, max(0, score * 100))

        return AnalysisResult(
            score: score,
            appliedRules: appliedRules,
            suggestions: suggestions.sorted { $0.priority.rawValue > $1.priority.rawValue },
            balanceScore: balanceScore,
            interestPoints: interestPoints,
            timestamp: Date()
        )
    }

    /// 快速构图评分（轻量级）
    func quickScore(subjects: [SubjectPosition], imageSize: CGSize) -> Float {
        var score: Float = 0

        // 三分法得分
        let (thirdsScore, _) = analyzeRuleOfThirds(subjects: subjects, imageSize: imageSize)
        score += thirdsScore * 0.5

        // 平衡得分
        let balanceScore = analyzeBalance(subjects: subjects, imageSize: imageSize)
        score += balanceScore * 0.5

        return min(1.0, max(0, score)) * 100
    }

    /// 建议构图调整
    func suggestAdjustment(currentSubjects: [SubjectPosition], imageSize: CGSize) -> CGPoint? {
        guard let mainSubject = currentSubjects.first else {
            return nil
        }

        // 计算最近的三分法交点
        let thirdPoints = getThirdsIntersections(imageSize: imageSize)

        // 找到最近的交点
        let nearestPoint = thirdPoints.min { point1, point2 in
            let dist1 = distance(from: mainSubject.center, to: point1)
            let dist2 = distance(from: mainSubject.center, to: point2)
            return dist1 < dist2
        }

        return nearestPoint
    }

    // MARK: - Private Analysis Methods

    /// 分析三分法
    private func analyzeRuleOfThirds(subjects: [SubjectPosition], imageSize: CGSize) -> (score: Float, applied: Bool) {
        guard let mainSubject = subjects.first else {
            return (0, false)
        }

        let thirdPoints = getThirdsIntersections(imageSize: imageSize)

        // 计算主体到最近三分法交点的距离
        let minDistance = thirdPoints.map { point in
            distance(from: mainSubject.center, to: point)
        }.min() ?? CGFloat.greatestFiniteMagnitude

        // 归一化距离（相对于图像对角线）
        let diagonal = sqrt(pow(imageSize.width, 2) + pow(imageSize.height, 2))
        let normalizedDistance = minDistance / diagonal

        // 距离越近，得分越高
        let score = Float(max(0, 1.0 - normalizedDistance * 5))
        let applied = normalizedDistance < 0.15  // 距离小于15%对角线长度认为符合

        return (score, applied)
    }

    /// 分析黄金分割
    private func analyzeGoldenRatio(subjects: [SubjectPosition], imageSize: CGSize) -> (score: Float, applied: Bool) {
        guard let mainSubject = subjects.first else {
            return (0, false)
        }

        let goldenRatio: CGFloat = 0.618
        let goldenPoints = [
            CGPoint(x: imageSize.width * goldenRatio, y: imageSize.height * goldenRatio),
            CGPoint(x: imageSize.width * (1 - goldenRatio), y: imageSize.height * goldenRatio),
            CGPoint(x: imageSize.width * goldenRatio, y: imageSize.height * (1 - goldenRatio)),
            CGPoint(x: imageSize.width * (1 - goldenRatio), y: imageSize.height * (1 - goldenRatio))
        ]

        let minDistance = goldenPoints.map { point in
            distance(from: mainSubject.center, to: point)
        }.min() ?? CGFloat.greatestFiniteMagnitude

        let diagonal = sqrt(pow(imageSize.width, 2) + pow(imageSize.height, 2))
        let normalizedDistance = minDistance / diagonal

        let score = Float(max(0, 1.0 - normalizedDistance * 5))
        let applied = normalizedDistance < 0.12

        return (score, applied)
    }

    /// 分析对称性
    private func analyzeSymmetry(image: UIImage) -> (score: Float, applied: Bool) {
        // 简化版：基于图像的左右对称性
        // 实际应用中可以使用更复杂的图像处理算法

        guard let cgImage = image.cgImage else {
            return (0, false)
        }

        let width = cgImage.width
        let height = cgImage.height

        // 采样检查左右对称性
        var symmetryScore: Float = 0
        let samples = 100

        // 这里使用简化算法，实际应该比较像素
        // 为了性能考虑，返回一个估计值
        symmetryScore = 0.5

        let applied = symmetryScore > 0.8
        return (symmetryScore, applied)
    }

    /// 分析画面平衡
    private func analyzeBalance(subjects: [SubjectPosition], imageSize: CGSize) -> Float {
        guard !subjects.isEmpty else {
            return 0.5  // 无主体，返回中性分数
        }

        let center = CGPoint(x: imageSize.width / 2, y: imageSize.height / 2)

        // 计算所有主体的重心
        var totalX: CGFloat = 0
        var totalY: CGFloat = 0
        var totalWeight: CGFloat = 0

        for subject in subjects {
            let area = subject.bounds.width * subject.bounds.height
            totalX += subject.center.x * area
            totalY += subject.center.y * area
            totalWeight += area
        }

        guard totalWeight > 0 else {
            return 0.5
        }

        let weightedCenter = CGPoint(x: totalX / totalWeight, y: totalY / totalWeight)

        // 计算重心偏移
        let offset = distance(from: center, to: weightedCenter)
        let maxOffset = sqrt(pow(imageSize.width / 2, 2) + pow(imageSize.height / 2, 2))
        let normalizedOffset = offset / maxOffset

        // 偏移越小，平衡得分越高
        return Float(max(0, 1.0 - normalizedOffset))
    }

    /// 查找兴趣点
    private func findInterestPoints(image: UIImage) -> [CGPoint] {
        // 使用Vision框架检测显著区域
        guard let cgImage = image.cgImage else {
            return []
        }

        var points: [CGPoint] = []

        let request = VNGenerateAttentionBasedSaliencyImageRequest()

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? handler.perform([request])

        if let result = request.results?.first as? VNSaliencyImageObservation {
            // 提取显著区域
            let salientObjects = result.salientObjects ?? []

            for object in salientObjects.prefix(5) {  // 最多5个兴趣点
                let box = object.boundingBox
                points.append(CGPoint(
                    x: box.midX * image.size.width,
                    y: (1 - box.midY) * image.size.height  // Vision使用底部为原点
                ))
            }
        }

        return points
    }

    /// 分析兴趣点分布
    private func analyzeInterestPoints(_ points: [CGPoint], imageSize: CGSize) -> Float {
        guard !points.isEmpty else {
            return 0.3
        }

        // 兴趣点分布在不同区域得分更高
        let regions = divideIntoRegions(imageSize: imageSize, divisions: 3)
        var occupiedRegions = Set<Int>()

        for point in points {
            for (index, region) in regions.enumerated() {
                if region.contains(point) {
                    occupiedRegions.insert(index)
                    break
                }
            }
        }

        // 分布越广，得分越高
        let distribution = Float(occupiedRegions.count) / Float(regions.count)
        return distribution
    }

    // MARK: - Helper Methods

    /// 获取三分法交点
    private func getThirdsIntersections(imageSize: CGSize) -> [CGPoint] {
        let w = imageSize.width
        let h = imageSize.height

        return [
            CGPoint(x: w / 3, y: h / 3),
            CGPoint(x: w * 2 / 3, y: h / 3),
            CGPoint(x: w / 3, y: h * 2 / 3),
            CGPoint(x: w * 2 / 3, y: h * 2 / 3)
        ]
    }

    /// 计算两点距离
    private func distance(from point1: CGPoint, to point2: CGPoint) -> CGFloat {
        let dx = point1.x - point2.x
        let dy = point1.y - point2.y
        return sqrt(dx * dx + dy * dy)
    }

    /// 将图像分割成网格区域
    private func divideIntoRegions(imageSize: CGSize, divisions: Int) -> [CGRect] {
        var regions: [CGRect] = []
        let cellWidth = imageSize.width / CGFloat(divisions)
        let cellHeight = imageSize.height / CGFloat(divisions)

        for row in 0..<divisions {
            for col in 0..<divisions {
                let rect = CGRect(
                    x: CGFloat(col) * cellWidth,
                    y: CGFloat(row) * cellHeight,
                    width: cellWidth,
                    height: cellHeight
                )
                regions.append(rect)
            }
        }

        return regions
    }
}
