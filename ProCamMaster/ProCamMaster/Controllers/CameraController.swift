//
//  CameraController.swift
//  ProCam Master
//
//  AVFoundation相机核心控制器
//  Created by Claude
//

import AVFoundation
import CoreImage
import UIKit
import Photos
import Combine

class CameraController: NSObject, ObservableObject {

    // MARK: - Published Properties
    @Published var isSessionRunning = false
    @Published var captureResult: CaptureResult?
    @Published var error: CameraError?
    @Published var histogramData = HistogramData()
    @Published var currentSettings = CameraSettings()
    @Published var capabilities = CameraCapabilities.default

    // MARK: - Private Properties
    private let session = AVCaptureSession()
    private var currentDevice: AVCaptureDevice?
    private var photoOutput = AVCapturePhotoOutput()
    private var videoOutput = AVCaptureMovieFileOutput()
    private var audioInput: AVCaptureDeviceInput?

    private let sessionQueue = DispatchQueue(label: "com.procammaster.sessionqueue")
    private var setupResult: SessionSetupResult = .success
    private var cancellables = Set<AnyCancellable>()

    private var videoDeviceInput: AVCaptureDeviceInput?
    private var backgroundRecordingID: UIBackgroundTaskIdentifier?

    // KVO观察
    private var keyValueObservations = [NSKeyValueObservation]()

    // MARK: - Enums
    enum SessionSetupResult {
        case success
        case notAuthorized
        case configurationFailed
    }

    enum CameraError: Error, LocalizedError {
        case cameraUnavailable
        case cannotAddInput
        case cannotAddOutput
        case notAuthorized
        case captureSessionError(Error)

        var errorDescription: String? {
            switch self {
            case .cameraUnavailable:
                return "相机不可用"
            case .cannotAddInput:
                return "无法添加输入设备"
            case .cannotAddOutput:
                return "无法添加输出设备"
            case .notAuthorized:
                return "没有相机权限"
            case .captureSessionError(let error):
                return "拍摄错误: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Initialization
    override init() {
        super.init()
        checkPermissions()
    }

    // MARK: - Public Methods

    /// 开始相机会话
    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            switch self.setupResult {
            case .success:
                self.session.startRunning()
                DispatchQueue.main.async {
                    self.isSessionRunning = self.session.isRunning
                }

            case .notAuthorized:
                DispatchQueue.main.async {
                    self.error = .notAuthorized
                }

            case .configurationFailed:
                DispatchQueue.main.async {
                    self.error = .cameraUnavailable
                }
            }
        }
    }

    /// 停止相机会话
    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            if self.session.isRunning {
                self.session.stopRunning()
                DispatchQueue.main.async {
                    self.isSessionRunning = false
                }
            }
        }
    }

    /// 配置相机会话
    func configureSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            self.session.beginConfiguration()
            self.session.sessionPreset = .photo

            // 添加视频输入
            do {
                let videoDevice = self.getBestCamera(for: self.currentSettings.currentCamera)
                let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)

                if self.session.canAddInput(videoDeviceInput) {
                    self.session.addInput(videoDeviceInput)
                    self.videoDeviceInput = videoDeviceInput
                    self.currentDevice = videoDevice
                } else {
                    self.setupResult = .configurationFailed
                    self.session.commitConfiguration()
                    return
                }
            } catch {
                self.setupResult = .configurationFailed
                self.session.commitConfiguration()
                return
            }

            // 添加照片输出
            if self.session.canAddOutput(self.photoOutput) {
                self.session.addOutput(self.photoOutput)

                // 配置ProRAW
                if self.photoOutput.isAppleProRAWEnabled {
                    self.photoOutput.maxPhotoDimensions = CMVideoDimensions(width: 8064, height: 6048)
                    DispatchQueue.main.async {
                        self.capabilities.supportsProRAW = true
                        self.capabilities.supports48MP = true
                    }
                }

                // 配置照片输出
                self.photoOutput.isHighResolutionCaptureEnabled = true
                self.photoOutput.maxPhotoQualityPrioritization = .quality

            } else {
                self.setupResult = .configurationFailed
                self.session.commitConfiguration()
                return
            }

            // 添加音频输入（视频用）
            self.configureAudioSession()

            self.session.commitConfiguration()

            // 更新相机能力
            self.updateCameraCapabilities()

            // 应用当前设置
            self.applyCurrentSettings()
        }
    }

    /// 拍照
    func capturePhoto() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            var photoSettings: AVCapturePhotoSettings

            // 根据ProRAW设置选择格式
            if self.currentSettings.isProRAWEnabled,
               self.photoOutput.availableRawPhotoPixelFormatTypes.count > 0 {

                // ProRAW拍摄
                if let rawFormat = self.photoOutput.availableRawPhotoPixelFormatTypes.first {
                    photoSettings = AVCapturePhotoSettings(rawPixelFormatType: rawFormat)
                    photoSettings.photoQualityPrioritization = .quality
                } else {
                    photoSettings = AVCapturePhotoSettings()
                }

            } else {
                // 普通拍摄
                photoSettings = AVCapturePhotoSettings()
            }

            // 配置闪光灯
            if self.currentDevice?.isFlashAvailable == true {
                photoSettings.flashMode = .off // 默认关闭闪光灯
            }

            // 高分辨率拍摄
            photoSettings.isHighResolutionPhotoEnabled = true

            // 拍摄
            self.photoOutput.capturePhoto(with: photoSettings, delegate: self)
        }
    }

    // MARK: - 手动控制方法

    /// 设置ISO
    func setISO(_ iso: Float) {
        guard let device = currentDevice else { return }

        sessionQueue.async {
            do {
                try device.lockForConfiguration()

                let clampedISO = max(device.activeFormat.minISO, min(iso, device.activeFormat.maxISO))

                if device.exposureMode == .custom {
                    device.setExposureModeCustom(
                        duration: device.exposureDuration,
                        iso: clampedISO,
                        completionHandler: nil
                    )
                }

                device.unlockForConfiguration()

                DispatchQueue.main.async { [weak self] in
                    self?.currentSettings.exposure.iso = clampedISO
                }
            } catch {
                print("设置ISO失败: \(error)")
            }
        }
    }

    /// 设置快门速度
    func setShutterSpeed(_ shutterSpeed: CMTime) {
        guard let device = currentDevice else { return }

        sessionQueue.async {
            do {
                try device.lockForConfiguration()

                let clampedDuration = CMTimeClamp(
                    shutterSpeed,
                    min: device.activeFormat.minExposureDuration,
                    max: device.activeFormat.maxExposureDuration
                )

                if device.exposureMode == .custom {
                    device.setExposureModeCustom(
                        duration: clampedDuration,
                        iso: device.iso,
                        completionHandler: nil
                    )
                }

                device.unlockForConfiguration()

                DispatchQueue.main.async { [weak self] in
                    self?.currentSettings.exposure.shutterSpeed = clampedDuration
                }
            } catch {
                print("设置快门速度失败: \(error)")
            }
        }
    }

    /// 设置曝光补偿
    func setExposureCompensation(_ ev: Float) {
        guard let device = currentDevice else { return }

        sessionQueue.async {
            do {
                try device.lockForConfiguration()

                let clampedEV = max(
                    device.minExposureTargetBias,
                    min(ev, device.maxExposureTargetBias)
                )

                device.setExposureTargetBias(clampedEV, completionHandler: nil)

                device.unlockForConfiguration()

                DispatchQueue.main.async { [weak self] in
                    self?.currentSettings.exposure.exposureCompensation = clampedEV
                }
            } catch {
                print("设置曝光补偿失败: \(error)")
            }
        }
    }

    /// 设置对焦模式
    func setFocusMode(_ mode: FocusMode) {
        guard let device = currentDevice else { return }

        sessionQueue.async {
            do {
                try device.lockForConfiguration()

                if device.isFocusModeSupported(mode.avMode) {
                    device.focusMode = mode.avMode
                }

                device.unlockForConfiguration()

                DispatchQueue.main.async { [weak self] in
                    self?.currentSettings.focus.mode = mode
                }
            } catch {
                print("设置对焦模式失败: \(error)")
            }
        }
    }

    /// 设置手动对焦位置
    func setManualFocus(lensPosition: Float) {
        guard let device = currentDevice else { return }

        sessionQueue.async {
            do {
                try device.lockForConfiguration()

                let clampedPosition = max(0.0, min(lensPosition, 1.0))
                device.setFocusModeLocked(lensPosition: clampedPosition, completionHandler: nil)

                device.unlockForConfiguration()

                DispatchQueue.main.async { [weak self] in
                    self?.currentSettings.focus.lensPosition = clampedPosition
                }
            } catch {
                print("设置手动对焦失败: \(error)")
            }
        }
    }

    /// 设置对焦点
    func setFocusPoint(_ point: CGPoint) {
        guard let device = currentDevice else { return }

        sessionQueue.async {
            do {
                try device.lockForConfiguration()

                if device.isFocusPointOfInterestSupported {
                    device.focusPointOfInterest = point
                    device.focusMode = .autoFocus
                }

                if device.isExposurePointOfInterestSupported {
                    device.exposurePointOfInterest = point
                    device.exposureMode = .autoExpose
                }

                device.unlockForConfiguration()

                DispatchQueue.main.async { [weak self] in
                    self?.currentSettings.focus.focusPoint = point
                }
            } catch {
                print("设置对焦点失败: \(error)")
            }
        }
    }

    /// 设置白平衡
    func setWhiteBalance(temperature: Float, tint: Float) {
        guard let device = currentDevice else { return }

        sessionQueue.async {
            do {
                try device.lockForConfiguration()

                if device.isWhiteBalanceModeSupported(.locked) {
                    let temperatureAndTint = AVCaptureDevice.WhiteBalanceTemperatureAndTintValues(
                        temperature: temperature,
                        tint: tint
                    )
                    let gains = device.deviceWhiteBalanceGains(for: temperatureAndTint)
                    let normalizedGains = self.normalizeGains(gains, for: device)

                    device.setWhiteBalanceModeLocked(with: normalizedGains, completionHandler: nil)
                }

                device.unlockForConfiguration()

                DispatchQueue.main.async { [weak self] in
                    self?.currentSettings.whiteBalance.temperature = temperature
                    self?.currentSettings.whiteBalance.tint = tint
                }
            } catch {
                print("设置白平衡失败: \(error)")
            }
        }
    }

    /// 切换相机
    func switchCamera(to cameraType: CameraType) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            self.session.beginConfiguration()

            // 移除旧输入
            if let currentInput = self.videoDeviceInput {
                self.session.removeInput(currentInput)
            }

            // 添加新输入
            do {
                let newDevice = self.getBestCamera(for: cameraType)
                let newInput = try AVCaptureDeviceInput(device: newDevice)

                if self.session.canAddInput(newInput) {
                    self.session.addInput(newInput)
                    self.videoDeviceInput = newInput
                    self.currentDevice = newDevice

                    DispatchQueue.main.async {
                        self.currentSettings.currentCamera = cameraType
                    }

                    self.updateCameraCapabilities()
                }
            } catch {
                print("切换相机失败: \(error)")
            }

            self.session.commitConfiguration()
        }
    }

    /// 设置变焦
    func setZoom(_ factor: CGFloat) {
        guard let device = currentDevice else { return }

        sessionQueue.async {
            do {
                try device.lockForConfiguration()

                let maxZoom = device.activeFormat.videoMaxZoomFactor
                let clampedZoom = max(1.0, min(factor, maxZoom))

                device.videoZoomFactor = clampedZoom

                device.unlockForConfiguration()

                DispatchQueue.main.async { [weak self] in
                    self?.currentSettings.zoomFactor = clampedZoom
                }
            } catch {
                print("设置变焦失败: \(error)")
            }
        }
    }

    // MARK: - Helper Methods

    /// 检查权限
    private func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            break

        case .notDetermined:
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if !granted {
                    self?.setupResult = .notAuthorized
                }
                self?.sessionQueue.resume()
            }

        default:
            setupResult = .notAuthorized
        }
    }

    /// 获取最佳相机
    private func getBestCamera(for type: CameraType) -> AVCaptureDevice {
        let discoverySession: AVCaptureDevice.DiscoverySession

        switch type {
        case .front:
            discoverySession = AVCaptureDevice.DiscoverySession(
                deviceTypes: [.builtInWideAngleCamera],
                mediaType: .video,
                position: .front
            )

        case .ultraWide:
            discoverySession = AVCaptureDevice.DiscoverySession(
                deviceTypes: [.builtInUltraWideCamera],
                mediaType: .video,
                position: .back
            )

        case .telephoto2x, .telephoto3x, .telephoto5x:
            discoverySession = AVCaptureDevice.DiscoverySession(
                deviceTypes: [.builtInTelephotoCamera],
                mediaType: .video,
                position: .back
            )

        default:
            discoverySession = AVCaptureDevice.DiscoverySession(
                deviceTypes: [.builtInWideAngleCamera],
                mediaType: .video,
                position: .back
            )
        }

        return discoverySession.devices.first ?? AVCaptureDevice.default(for: .video)!
    }

    /// 配置音频会话
    private func configureAudioSession() {
        do {
            let audioDevice = AVCaptureDevice.default(for: .audio)
            let audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice!)

            if session.canAddInput(audioDeviceInput) {
                session.addInput(audioDeviceInput)
                self.audioInput = audioDeviceInput
            }
        } catch {
            print("配置音频失败: \(error)")
        }
    }

    /// 更新相机能力
    private func updateCameraCapabilities() {
        guard let device = currentDevice else { return }

        DispatchQueue.main.async { [weak self] in
            self?.capabilities = CameraCapabilities(
                minISO: device.activeFormat.minISO,
                maxISO: device.activeFormat.maxISO,
                minShutterSpeed: device.activeFormat.minExposureDuration,
                maxShutterSpeed: device.activeFormat.maxExposureDuration,
                minExposureCompensation: device.minExposureTargetBias,
                maxExposureCompensation: device.maxExposureTargetBias,
                hasUltraWide: self?.hasCamera(.ultraWide) ?? false,
                hasTelephoto: self?.hasCamera(.telephoto3x) ?? false,
                supportsProRAW: self?.photoOutput.isAppleProRAWSupported ?? false,
                supports48MP: true,
                hasLiDAR: false
            )
        }
    }

    /// 检查是否有特定相机
    private func hasCamera(_ type: CameraType) -> Bool {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [type.deviceType],
            mediaType: .video,
            position: .back
        )
        return !discoverySession.devices.isEmpty
    }

    /// 标准化白平衡增益
    private func normalizeGains(_ gains: AVCaptureDevice.WhiteBalanceGains,
                                for device: AVCaptureDevice) -> AVCaptureDevice.WhiteBalanceGains {
        var normalizedGains = gains

        normalizedGains.redGain = max(1.0, min(normalizedGains.redGain, device.maxWhiteBalanceGain))
        normalizedGains.greenGain = max(1.0, min(normalizedGains.greenGain, device.maxWhiteBalanceGain))
        normalizedGains.blueGain = max(1.0, min(normalizedGains.blueGain, device.maxWhiteBalanceGain))

        return normalizedGains
    }

    /// 应用当前设置
    private func applyCurrentSettings() {
        // 应用曝光设置
        if !currentSettings.exposure.isAutoISO {
            setISO(currentSettings.exposure.iso)
        }

        if !currentSettings.exposure.isAutoShutter {
            setShutterSpeed(currentSettings.exposure.shutterSpeed)
        }

        // 应用对焦设置
        setFocusMode(currentSettings.focus.mode)

        // 应用白平衡
        if currentSettings.whiteBalance.preset != .auto {
            setWhiteBalance(
                temperature: currentSettings.whiteBalance.temperature,
                tint: currentSettings.whiteBalance.tint
            )
        }
    }

    /// 获取当前会话
    func getSession() -> AVCaptureSession {
        return session
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension CameraController: AVCapturePhotoCaptureDelegate {

    func photoOutput(_ output: AVCapturePhotoOutput,
                    didFinishProcessingPhoto photo: AVCapturePhoto,
                    error: Error?) {

        if let error = error {
            DispatchQueue.main.async { [weak self] in
                self?.error = .captureSessionError(error)
            }
            return
        }

        guard let imageData = photo.fileDataRepresentation() else {
            return
        }

        // 保存到相册
        PHPhotoLibrary.requestAuthorization { [weak self] status in
            guard status == .authorized else { return }

            PHPhotoLibrary.shared().performChanges {
                let creationRequest = PHAssetCreationRequest.forAsset()
                creationRequest.addResource(with: .photo, data: imageData, options: nil)

                // 保存元数据
                if let metadata = photo.metadata as? [String: Any] {
                    print("照片元数据: \(metadata)")
                }

            } completionHandler: { success, error in
                DispatchQueue.main.async {
                    if success {
                        let result = CaptureResult(
                            imageData: imageData,
                            metadata: photo.metadata as? [String: Any],
                            error: nil
                        )
                        self?.captureResult = result
                    } else if let error = error {
                        self?.error = .captureSessionError(error)
                    }
                }
            }
        }
    }
}
