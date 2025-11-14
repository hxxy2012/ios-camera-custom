//
//  CameraViewModel.swift
//  ProCam Master
//
//  相机视图模型
//  Created by Claude
//

import SwiftUI
import Combine
import AVFoundation

class CameraViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var settings: CameraSettings
    @Published var isSessionRunning = false
    @Published var captureResult: CaptureResult?
    @Published var errorMessage: String?
    @Published var histogramData = HistogramData()
    @Published var capabilities = CameraCapabilities.default

    // UI状态
    @Published var isShowingSettings = false
    @Published var isShowingGallery = false
    @Published var showCaptureAnimation = false

    // MARK: - Private Properties
    let cameraController: CameraController
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    init(cameraController: CameraController = CameraController()) {
        self.cameraController = cameraController
        self.settings = CameraSettings()

        setupBindings()
    }

    // MARK: - Public Methods

    /// 启动相机
    func startCamera() {
        cameraController.configureSession()
        cameraController.startSession()
    }

    /// 停止相机
    func stopCamera() {
        cameraController.stopSession()
    }

    /// 拍照
    func capturePhoto() {
        // 播放拍照动画
        withAnimation(.easeInOut(duration: 0.1)) {
            showCaptureAnimation = true
        }

        cameraController.capturePhoto()

        // 重置动画
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.showCaptureAnimation = false
        }
    }

    // MARK: - 曝光控制

    /// 设置ISO
    func setISO(_ value: Float) {
        settings.exposure.iso = value
        settings.exposure.isAutoISO = false
        cameraController.setISO(value)
    }

    /// 设置快门速度
    func setShutterSpeed(_ value: CMTime) {
        settings.exposure.shutterSpeed = value
        settings.exposure.isAutoShutter = false
        cameraController.setShutterSpeed(value)
    }

    /// 设置快门速度（根据分数）
    func setShutterSpeed(fraction: Int) {
        let shutterTime = CMTime(value: 1, timescale: Int32(fraction))
        setShutterSpeed(shutterTime)
    }

    /// 设置快门速度（秒）
    func setShutterSpeed(seconds: Double) {
        let shutterTime = CMTime(seconds: seconds, preferredTimescale: 1000)
        setShutterSpeed(shutterTime)
    }

    /// 设置曝光补偿
    func setExposureCompensation(_ value: Float) {
        settings.exposure.exposureCompensation = value
        cameraController.setExposureCompensation(value)
    }

    /// 切换自动ISO
    func toggleAutoISO() {
        settings.exposure.isAutoISO.toggle()
        // 实现自动ISO逻辑
    }

    /// 切换自动快门
    func toggleAutoShutter() {
        settings.exposure.isAutoShutter.toggle()
        // 实现自动快门逻辑
    }

    // MARK: - 对焦控制

    /// 设置对焦模式
    func setFocusMode(_ mode: FocusMode) {
        settings.focus.mode = mode
        cameraController.setFocusMode(mode)
    }

    /// 设置手动对焦位置
    func setManualFocus(lensPosition: Float) {
        settings.focus.lensPosition = lensPosition
        cameraController.setManualFocus(lensPosition: lensPosition)
    }

    /// 对焦到指定点
    func focusAt(point: CGPoint) {
        settings.focus.focusPoint = point
        cameraController.setFocusPoint(point)
    }

    /// 锁定对焦
    func lockFocus() {
        settings.focus.isLocked = true
        // 实现对焦锁定
    }

    /// 解锁对焦
    func unlockFocus() {
        settings.focus.isLocked = false
        // 实现对焦解锁
    }

    // MARK: - 白平衡控制

    /// 设置白平衡预设
    func setWhiteBalancePreset(_ preset: WhiteBalancePreset) {
        settings.whiteBalance.preset = preset
        settings.whiteBalance.temperature = preset.kelvin

        if preset != .auto {
            cameraController.setWhiteBalance(
                temperature: preset.kelvin,
                tint: settings.whiteBalance.tint
            )
        }
    }

    /// 设置自定义色温
    func setWhiteBalanceTemperature(_ temperature: Float) {
        settings.whiteBalance.temperature = temperature
        settings.whiteBalance.preset = .custom
        cameraController.setWhiteBalance(
            temperature: temperature,
            tint: settings.whiteBalance.tint
        )
    }

    /// 设置色调
    func setWhiteBalanceTint(_ tint: Float) {
        settings.whiteBalance.tint = tint
        cameraController.setWhiteBalance(
            temperature: settings.whiteBalance.temperature,
            tint: tint
        )
    }

    /// 锁定白平衡
    func lockWhiteBalance() {
        settings.whiteBalance.isLocked = true
    }

    /// 解锁白平衡
    func unlockWhiteBalance() {
        settings.whiteBalance.isLocked = false
    }

    // MARK: - 相机切换

    /// 切换相机
    func switchCamera(to type: CameraType) {
        settings.currentCamera = type
        cameraController.switchCamera(to: type)
    }

    /// 设置变焦
    func setZoom(_ factor: CGFloat) {
        settings.zoomFactor = factor
        cameraController.setZoom(factor)
    }

    // MARK: - 拍摄模式

    /// 切换拍摄模式
    func setShootingMode(_ mode: ShootingMode) {
        settings.shootingMode = mode

        // 根据模式调整设置
        switch mode {
        case .proRAW:
            settings.isProRAWEnabled = true

        case .night:
            // 夜景模式优化
            settings.exposure.iso = 3200
            settings.exposure.shutterSpeed = CMTime(value: 1, timescale: 4) // 1/4s

        default:
            settings.isProRAWEnabled = false
        }
    }

    /// 切换ProRAW
    func toggleProRAW() {
        settings.isProRAWEnabled.toggle()
    }

    /// 设置ProRAW分辨率
    func setProRAWResolution(_ resolution: CameraSettings.ProRAWResolution) {
        settings.proRAWResolution = resolution
    }

    // MARK: - 测光模式

    /// 设置测光模式
    func setMeteringMode(_ mode: MeteringMode) {
        settings.meteringMode = mode
    }

    // MARK: - 网格线

    /// 设置网格线类型
    func setGridType(_ type: GridType) {
        settings.gridType = type
    }

    // MARK: - 显示设置

    /// 切换直方图显示
    func toggleHistogram() {
        settings.isHistogramVisible.toggle()
    }

    /// 切换水平仪显示
    func toggleLevel() {
        settings.isLevelVisible.toggle()
    }

    /// 切换信息叠加
    func toggleInfoOverlay() {
        settings.isInfoOverlayVisible.toggle()
    }

    // MARK: - 快捷预设

    /// 获取常用快门速度预设
    func getCommonShutterSpeeds() -> [CMTime] {
        return [
            CMTime(value: 1, timescale: 8000),   // 1/8000
            CMTime(value: 1, timescale: 4000),   // 1/4000
            CMTime(value: 1, timescale: 2000),   // 1/2000
            CMTime(value: 1, timescale: 1000),   // 1/1000
            CMTime(value: 1, timescale: 500),    // 1/500
            CMTime(value: 1, timescale: 250),    // 1/250
            CMTime(value: 1, timescale: 125),    // 1/125
            CMTime(value: 1, timescale: 60),     // 1/60
            CMTime(value: 1, timescale: 30),     // 1/30
            CMTime(value: 1, timescale: 15),     // 1/15
            CMTime(value: 1, timescale: 8),      // 1/8
            CMTime(value: 1, timescale: 4),      // 1/4
            CMTime(value: 1, timescale: 2),      // 1/2
            CMTime(value: 1, timescale: 1),      // 1s
        ]
    }

    /// 获取常用ISO值
    func getCommonISOValues() -> [Float] {
        return [25, 50, 100, 200, 400, 800, 1600, 3200, 6400, 12800]
    }

    // MARK: - Private Methods

    /// 设置数据绑定
    private func setupBindings() {
        // 监听相机控制器状态
        cameraController.$isSessionRunning
            .assign(to: &$isSessionRunning)

        cameraController.$captureResult
            .assign(to: &$captureResult)

        cameraController.$histogramData
            .assign(to: &$histogramData)

        cameraController.$capabilities
            .assign(to: &$capabilities)

        // 监听错误
        cameraController.$error
            .compactMap { $0?.localizedDescription }
            .assign(to: &$errorMessage)

        // 同步设置
        cameraController.$currentSettings
            .assign(to: &$settings)
    }

    /// 获取相机会话（用于预览）
    func getCameraSession() -> AVCaptureSession {
        return cameraController.getSession()
    }
}

// MARK: - 便捷计算属性
extension CameraViewModel {

    /// ISO范围
    var isoRange: ClosedRange<Float> {
        return capabilities.minISO...capabilities.maxISO
    }

    /// EV范围
    var evRange: ClosedRange<Float> {
        return capabilities.minExposureCompensation...capabilities.maxExposureCompensation
    }

    /// 当前ISO字符串
    var isoString: String {
        if settings.exposure.isAutoISO {
            return "AUTO"
        }
        return "ISO \(Int(settings.exposure.iso))"
    }

    /// 当前快门速度字符串
    var shutterSpeedString: String {
        if settings.exposure.isAutoShutter {
            return "AUTO"
        }
        return settings.exposure.shutterSpeedString
    }

    /// 当前EV字符串
    var evString: String {
        return settings.exposure.evString
    }

    /// 当前白平衡字符串
    var whiteBalanceString: String {
        if settings.whiteBalance.preset == .auto {
            return "AWB"
        }
        return settings.whiteBalance.temperatureString
    }

    /// 当前对焦模式字符串
    var focusModeString: String {
        return settings.focus.mode.rawValue
    }
}
