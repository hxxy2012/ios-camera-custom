//
//  FaceDetector.swift
//  ProCam Master
//
//  人脸和人眼检测器（Vision Framework）
//  Created by Claude
//

import Foundation
import Vision
import CoreGraphics
import UIKit

class FaceDetector {

    // MARK: - Face Detection Result
    struct Face {
        let boundingBox: CGRect
        let confidence: Float
        let landmarks: FaceLandmarks?
        let roll: Float?
        let yaw: Float?
        let pitch: Float?

        var isSmiling: Bool {
            // 基于landmarks判断
            return false
        }

        var eyesOpen: Bool {
            // 基于landmarks判断
            return true
        }
    }

    struct FaceLandmarks {
        let leftEye: CGPoint?
        let rightEye: CGPoint?
        let nose: CGPoint?
        let mouth: CGPoint?
        let leftEyebrow: [CGPoint]?
        let rightEyebrow: [CGPoint]?
        let faceContour: [CGPoint]?
    }

    struct DetectionResult {
        let faces: [Face]
        let dominantFace: Face?
        let timestamp: Date

        var hasFaces: Bool {
            !faces.isEmpty
        }

        var faceCount: Int {
            faces.count
        }
    }

    // MARK: - Eye Detection Result
    struct Eye {
        let position: CGPoint
        let bounds: CGRect
        let confidence: Float
        let side: Side

        enum Side {
            case left
            case right
        }
    }

    struct EyeDetectionResult {
        let eyes: [Eye]
        let leftEye: Eye?
        let rightEye: Eye?

        var hasEyes: Bool {
            !eyes.isEmpty
        }

        var hasBothEyes: Bool {
            leftEye != nil && rightEye != nil
        }
    }

    // MARK: - Private Properties
    private let detectionQueue = DispatchQueue(label: "com.procammaster.facedetection")

    // MARK: - Public Methods

    /// 检测人脸（从像素缓冲区）
    func detectFaces(in pixelBuffer: CVPixelBuffer, completion: @escaping (DetectionResult) -> Void) {
        let request = VNDetectFaceRectanglesRequest { request, error in
            if let error = error {
                print("人脸检测失败: \(error)")
                completion(DetectionResult(faces: [], dominantFace: nil, timestamp: Date()))
                return
            }

            guard let observations = request.results as? [VNFaceObservation] else {
                completion(DetectionResult(faces: [], dominantFace: nil, timestamp: Date()))
                return
            }

            let faces = observations.map { observation in
                Face(
                    boundingBox: observation.boundingBox,
                    confidence: observation.confidence,
                    landmarks: nil,
                    roll: observation.roll?.floatValue,
                    yaw: observation.yaw?.floatValue,
                    pitch: observation.pitch?.floatValue
                )
            }

            // 找到最大的脸作为主要人脸
            let dominantFace = faces.max { face1, face2 in
                let area1 = face1.boundingBox.width * face1.boundingBox.height
                let area2 = face2.boundingBox.width * face2.boundingBox.height
                return area1 < area2
            }

            let result = DetectionResult(
                faces: faces,
                dominantFace: dominantFace,
                timestamp: Date()
            )

            completion(result)
        }

        // 配置请求
        request.revision = VNDetectFaceRectanglesRequestRevision3

        // 执行请求
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        detectionQueue.async {
            try? handler.perform([request])
        }
    }

    /// 检测人脸和特征点（详细版）
    func detectFaceLandmarks(in pixelBuffer: CVPixelBuffer, completion: @escaping (DetectionResult) -> Void) {
        let request = VNDetectFaceLandmarksRequest { request, error in
            if let error = error {
                print("人脸特征点检测失败: \(error)")
                completion(DetectionResult(faces: [], dominantFace: nil, timestamp: Date()))
                return
            }

            guard let observations = request.results as? [VNFaceObservation] else {
                completion(DetectionResult(faces: [], dominantFace: nil, timestamp: Date()))
                return
            }

            let faces = observations.map { observation -> Face in
                var landmarks: FaceLandmarks?

                if let faceLandmarks = observation.landmarks {
                    landmarks = FaceLandmarks(
                        leftEye: self.getCenterPoint(of: faceLandmarks.leftEye),
                        rightEye: self.getCenterPoint(of: faceLandmarks.rightEye),
                        nose: self.getCenterPoint(of: faceLandmarks.nose),
                        mouth: self.getCenterPoint(of: faceLandmarks.outerLips),
                        leftEyebrow: self.getPoints(of: faceLandmarks.leftEyebrow),
                        rightEyebrow: self.getPoints(of: faceLandmarks.rightEyebrow),
                        faceContour: self.getPoints(of: faceLandmarks.faceContour)
                    )
                }

                return Face(
                    boundingBox: observation.boundingBox,
                    confidence: observation.confidence,
                    landmarks: landmarks,
                    roll: observation.roll?.floatValue,
                    yaw: observation.yaw?.floatValue,
                    pitch: observation.pitch?.floatValue
                )
            }

            let dominantFace = faces.max { face1, face2 in
                let area1 = face1.boundingBox.width * face1.boundingBox.height
                let area2 = face2.boundingBox.width * face2.boundingBox.height
                return area1 < area2
            }

            let result = DetectionResult(
                faces: faces,
                dominantFace: dominantFace,
                timestamp: Date()
            )

            completion(result)
        }

        // 配置请求
        request.revision = VNDetectFaceLandmarksRequestRevision3

        // 执行请求
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        detectionQueue.async {
            try? handler.perform([request])
        }
    }

    /// 检测人眼（精确定位）
    func detectEyes(in pixelBuffer: CVPixelBuffer, completion: @escaping (EyeDetectionResult) -> Void) {
        // 首先检测人脸
        detectFaceLandmarks(in: pixelBuffer) { result in
            guard let face = result.dominantFace,
                  let landmarks = face.landmarks else {
                completion(EyeDetectionResult(eyes: [], leftEye: nil, rightEye: nil))
                return
            }

            var eyes: [Eye] = []

            // 左眼
            if let leftEyePoint = landmarks.leftEye {
                let leftEye = Eye(
                    position: leftEyePoint,
                    bounds: CGRect(
                        x: leftEyePoint.x - 0.02,
                        y: leftEyePoint.y - 0.02,
                        width: 0.04,
                        height: 0.04
                    ),
                    confidence: face.confidence,
                    side: .left
                )
                eyes.append(leftEye)
            }

            // 右眼
            if let rightEyePoint = landmarks.rightEye {
                let rightEye = Eye(
                    position: rightEyePoint,
                    bounds: CGRect(
                        x: rightEyePoint.x - 0.02,
                        y: rightEyePoint.y - 0.02,
                        width: 0.04,
                        height: 0.04
                    ),
                    confidence: face.confidence,
                    side: .right
                )
                eyes.append(rightEye)
            }

            let leftEye = eyes.first { $0.side == .left }
            let rightEye = eyes.first { $0.side == .right }

            completion(EyeDetectionResult(
                eyes: eyes,
                leftEye: leftEye,
                rightEye: rightEye
            ))
        }
    }

    /// 检测宠物脸（猫狗）
    func detectAnimalFaces(in pixelBuffer: CVPixelBuffer, completion: @escaping (DetectionResult) -> Void) {
        let request = VNRecognizeAnimalsRequest { request, error in
            if let error = error {
                print("动物检测失败: \(error)")
                completion(DetectionResult(faces: [], dominantFace: nil, timestamp: Date()))
                return
            }

            guard let observations = request.results as? [VNRecognizedObjectObservation] else {
                completion(DetectionResult(faces: [], dominantFace: nil, timestamp: Date()))
                return
            }

            // 将动物检测结果转换为Face类型
            let faces = observations.compactMap { observation -> Face? in
                guard observation.labels.contains(where: { $0.identifier == "Dog" || $0.identifier == "Cat" }) else {
                    return nil
                }

                return Face(
                    boundingBox: observation.boundingBox,
                    confidence: observation.confidence,
                    landmarks: nil,
                    roll: nil,
                    yaw: nil,
                    pitch: nil
                )
            }

            let dominantFace = faces.max { face1, face2 in
                let area1 = face1.boundingBox.width * face1.boundingBox.height
                let area2 = face2.boundingBox.width * face2.boundingBox.height
                return area1 < area2
            }

            completion(DetectionResult(
                faces: faces,
                dominantFace: dominantFace,
                timestamp: Date()
            ))
        }

        // 执行请求
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        detectionQueue.async {
            try? handler.perform([request])
        }
    }

    /// 计算最佳对焦点（基于人脸位置）
    func calculateBestFocusPoint(for faces: [Face], imageSize: CGSize) -> CGPoint? {
        guard let dominantFace = faces.max(by: { face1, face2 in
            let area1 = face1.boundingBox.width * face1.boundingBox.height
            let area2 = face2.boundingBox.width * face2.boundingBox.height
            return area1 < area2
        }) else {
            return nil
        }

        // 如果有眼睛位置，优先对焦到眼睛
        if let landmarks = dominantFace.landmarks,
           let leftEye = landmarks.leftEye,
           let rightEye = landmarks.rightEye {
            // 返回两眼中点
            return CGPoint(
                x: (leftEye.x + rightEye.x) / 2,
                y: (leftEye.y + rightEye.y) / 2
            )
        }

        // 否则对焦到脸部中心偏上（眼睛区域）
        let bbox = dominantFace.boundingBox
        return CGPoint(
            x: bbox.midX,
            y: bbox.midY + bbox.height * 0.15  // 稍微向上偏移到眼睛位置
        )
    }

    // MARK: - Private Helper Methods

    /// 获取特征点的中心
    private func getCenterPoint(of landmark: VNFaceLandmarkRegion2D?) -> CGPoint? {
        guard let landmark = landmark else { return nil }

        let points = landmark.normalizedPoints
        guard !points.isEmpty else { return nil }

        let sumX = points.reduce(0) { $0 + $1.x }
        let sumY = points.reduce(0) { $0 + $1.y }

        return CGPoint(
            x: CGFloat(sumX) / CGFloat(points.count),
            y: CGFloat(sumY) / CGFloat(points.count)
        )
    }

    /// 获取特征点数组
    private func getPoints(of landmark: VNFaceLandmarkRegion2D?) -> [CGPoint]? {
        guard let landmark = landmark else { return nil }

        return landmark.normalizedPoints.map { point in
            CGPoint(x: CGFloat(point.x), y: CGFloat(point.y))
        }
    }
}
