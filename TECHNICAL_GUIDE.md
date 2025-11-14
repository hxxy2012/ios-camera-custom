# ProCam Master - 技术指南

## 目录

1. [架构设计](#架构设计)
2. [核心组件](#核心组件)
3. [数据流](#数据流)
4. [相机控制](#相机控制)
5. [图像处理](#图像处理)
6. [性能优化](#性能优化)
7. [测试指南](#测试指南)
8. [部署指南](#部署指南)

---

## 架构设计

### MVVM架构

```
┌─────────────────────────────────────────┐
│              SwiftUI Views              │
│  (CameraView, ParameterControlView)     │
└──────────────────┬──────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────┐
│           View Models                    │
│         (CameraViewModel)                │
└──────────────────┬──────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────┐
│           Controllers                    │
│        (CameraController)                │
└──────────────────┬──────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────┐
│         AVFoundation APIs                │
│   (AVCaptureSession, AVCaptureDevice)   │
└─────────────────────────────────────────┘
```

### 设计模式

- **MVVM**：视图和业务逻辑分离
- **Observer**：Combine框架实现响应式编程
- **Delegate**：AVFoundation回调处理
- **Singleton**：相机控制器单例
- **Factory**：相机配置工厂

---

## 核心组件

### 1. CameraController

**职责**：
- 管理AVCaptureSession
- 控制相机硬件参数
- 处理拍照/录像
- 管理输入/输出设备

**关键方法**：

```swift
class CameraController {
    // 配置会话
    func configureSession()

    // 手动曝光
    func setISO(_ iso: Float)
    func setShutterSpeed(_ speed: CMTime)
    func setExposureCompensation(_ ev: Float)

    // 手动对焦
    func setFocusMode(_ mode: FocusMode)
    func setManualFocus(lensPosition: Float)
    func setFocusPoint(_ point: CGPoint)

    // 白平衡
    func setWhiteBalance(temperature: Float, tint: Float)

    // 相机切换
    func switchCamera(to type: CameraType)
    func setZoom(_ factor: CGFloat)

    // 拍摄
    func capturePhoto()
}
```

**线程安全**：
- 所有相机操作在`sessionQueue`上执行
- UI更新在主线程
- 使用`async/await`处理异步操作

### 2. CameraViewModel

**职责**：
- 桥接View和Controller
- 管理UI状态
- 处理用户输入
- 提供便捷接口

**关键属性**：

```swift
class CameraViewModel: ObservableObject {
    @Published var settings: CameraSettings
    @Published var isSessionRunning: Bool
    @Published var captureResult: CaptureResult?
    @Published var errorMessage: String?
    @Published var histogramData: HistogramData
    @Published var capabilities: CameraCapabilities
}
```

**数据绑定**：
- 使用Combine框架
- `@Published`属性自动触发UI更新
- 双向绑定简化状态管理

### 3. HistogramProcessor

**职责**：
- 生成实时直方图
- 分析曝光
- 处理像素数据

**算法**：

```swift
// 从像素缓冲区生成直方图
func generateHistogram(from pixelBuffer: CVPixelBuffer) -> HistogramData {
    // 1. 锁定像素缓冲区
    CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)

    // 2. 采样像素（每4个采样1个）
    for y in stride(from: 0, to: height, by: 4) {
        for x in stride(from: 0, to: width, by: 4) {
            // 统计RGB值
        }
    }

    // 3. 归一化
    // 4. 返回数据
}
```

---

## 数据流

### 拍照流程

```
用户点击快门
    ↓
CameraView触发capturePhoto()
    ↓
CameraViewModel.capturePhoto()
    ↓
CameraController.capturePhoto()
    ↓
配置AVCapturePhotoSettings
    ↓
photoOutput.capturePhoto(with:delegate:)
    ↓
AVCapturePhotoCaptureDelegate回调
    ↓
didFinishProcessingPhoto
    ↓
保存到相册（PHPhotoLibrary）
    ↓
更新CaptureResult
    ↓
UI显示结果
```

### 参数调整流程

```
用户滑动ISO滑块
    ↓
@Binding绑定更新
    ↓
CameraViewModel.setISO(newValue)
    ↓
CameraController.setISO(newValue)
    ↓
sessionQueue.async {
    device.lockForConfiguration()
    device.setExposureModeCustom(iso:)
    device.unlockForConfiguration()
}
    ↓
@Published属性更新
    ↓
UI自动刷新
```

---

## 相机控制

### 手动曝光

#### ISO控制

```swift
func setISO(_ iso: Float) {
    guard let device = currentDevice else { return }

    sessionQueue.async {
        do {
            try device.lockForConfiguration()

            // 限制ISO范围
            let clampedISO = max(
                device.activeFormat.minISO,
                min(iso, device.activeFormat.maxISO)
            )

            // 设置自定义曝光
            if device.exposureMode == .custom {
                device.setExposureModeCustom(
                    duration: device.exposureDuration,
                    iso: clampedISO,
                    completionHandler: nil
                )
            }

            device.unlockForConfiguration()
        } catch {
            print("设置ISO失败: \(error)")
        }
    }
}
```

#### 快门速度控制

```swift
func setShutterSpeed(_ shutterSpeed: CMTime) {
    guard let device = currentDevice else { return }

    sessionQueue.async {
        do {
            try device.lockForConfiguration()

            // 限制快门速度范围
            let clampedDuration = CMTimeClamp(
                shutterSpeed,
                min: device.activeFormat.minExposureDuration,
                max: device.activeFormat.maxExposureDuration
            )

            device.setExposureModeCustom(
                duration: clampedDuration,
                iso: device.iso,
                completionHandler: nil
            )

            device.unlockForConfiguration()
        } catch {
            print("设置快门速度失败: \(error)")
        }
    }
}
```

### 手动对焦

#### 焦点位置控制

```swift
func setManualFocus(lensPosition: Float) {
    guard let device = currentDevice else { return }

    sessionQueue.async {
        do {
            try device.lockForConfiguration()

            // 0.0 = 近, 1.0 = 远
            let clampedPosition = max(0.0, min(lensPosition, 1.0))

            device.setFocusModeLocked(
                lensPosition: clampedPosition,
                completionHandler: nil
            )

            device.unlockForConfiguration()
        } catch {
            print("设置手动对焦失败: \(error)")
        }
    }
}
```

#### 对焦点设置

```swift
func setFocusPoint(_ point: CGPoint) {
    guard let device = currentDevice else { return }

    sessionQueue.async {
        do {
            try device.lockForConfiguration()

            // 设置对焦点
            if device.isFocusPointOfInterestSupported {
                device.focusPointOfInterest = point
                device.focusMode = .autoFocus
            }

            // 同时设置测光点
            if device.isExposurePointOfInterestSupported {
                device.exposurePointOfInterest = point
                device.exposureMode = .autoExpose
            }

            device.unlockForConfiguration()
        } catch {
            print("设置对焦点失败: \(error)")
        }
    }
}
```

### 白平衡控制

```swift
func setWhiteBalance(temperature: Float, tint: Float) {
    guard let device = currentDevice else { return }

    sessionQueue.async {
        do {
            try device.lockForConfiguration()

            if device.isWhiteBalanceModeSupported(.locked) {
                // 创建色温和色调值
                let temperatureAndTint = AVCaptureDevice.WhiteBalanceTemperatureAndTintValues(
                    temperature: temperature,
                    tint: tint
                )

                // 转换为RGB增益
                let gains = device.deviceWhiteBalanceGains(for: temperatureAndTint)

                // 标准化增益值
                let normalizedGains = normalizeGains(gains, for: device)

                // 设置白平衡
                device.setWhiteBalanceModeLocked(
                    with: normalizedGains,
                    completionHandler: nil
                )
            }

            device.unlockForConfiguration()
        } catch {
            print("设置白平衡失败: \(error)")
        }
    }
}

// 标准化白平衡增益
private func normalizeGains(_ gains: AVCaptureDevice.WhiteBalanceGains,
                            for device: AVCaptureDevice) -> AVCaptureDevice.WhiteBalanceGains {
    var normalizedGains = gains
    let maxGain = device.maxWhiteBalanceGain

    normalizedGains.redGain = max(1.0, min(normalizedGains.redGain, maxGain))
    normalizedGains.greenGain = max(1.0, min(normalizedGains.greenGain, maxGain))
    normalizedGains.blueGain = max(1.0, min(normalizedGains.blueGain, maxGain))

    return normalizedGains
}
```

### 多摄像头切换

```swift
func switchCamera(to cameraType: CameraType) {
    sessionQueue.async {
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
            }
        } catch {
            print("切换相机失败: \(error)")
        }

        self.session.commitConfiguration()
    }
}

// 获取最佳相机设备
private func getBestCamera(for type: CameraType) -> AVCaptureDevice {
    let discoverySession: AVCaptureDevice.DiscoverySession

    switch type {
    case .ultraWide:
        discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInUltraWideCamera],
            mediaType: .video,
            position: .back
        )
    case .wide:
        discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: .back
        )
    case .telephoto3x:
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
```

### ProRAW拍摄

```swift
func captureProRAW() {
    sessionQueue.async {
        var photoSettings: AVCapturePhotoSettings

        // 检查ProRAW支持
        if self.photoOutput.availableRawPhotoPixelFormatTypes.count > 0 {
            // 创建ProRAW设置
            if let rawFormat = self.photoOutput.availableRawPhotoPixelFormatTypes.first {
                photoSettings = AVCapturePhotoSettings(rawPixelFormatType: rawFormat)

                // 启用Apple ProRAW
                if self.photoOutput.isAppleProRAWSupported {
                    photoSettings.rawPhotoPixelFormatType = rawFormat
                }

                // 设置最大分辨率
                photoSettings.maxPhotoDimensions = CMVideoDimensions(
                    width: 8064,  // 48MP
                    height: 6048
                )

                // 高质量优先
                photoSettings.photoQualityPrioritization = .quality
            } else {
                photoSettings = AVCapturePhotoSettings()
            }
        } else {
            photoSettings = AVCapturePhotoSettings()
        }

        // 拍摄
        self.photoOutput.capturePhoto(with: photoSettings, delegate: self)
    }
}
```

---

## 图像处理

### 直方图生成

```swift
func generateHistogram(from pixelBuffer: CVPixelBuffer) -> HistogramData {
    var histogramData = HistogramData()

    // 锁定像素缓冲区
    CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
    defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

    guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
        return histogramData
    }

    let width = CVPixelBufferGetWidth(pixelBuffer)
    let height = CVPixelBufferGetHeight(pixelBuffer)
    let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)

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

    // 转换为CGFloat数组并归一化
    let maxRed = CGFloat(redBins.max() ?? 1)
    let maxGreen = CGFloat(greenBins.max() ?? 1)
    let maxBlue = CGFloat(blueBins.max() ?? 1)

    for i in 0..<256 {
        histogramData.red[i] = CGFloat(redBins[i]) / maxRed
        histogramData.green[i] = CGFloat(greenBins[i]) / maxGreen
        histogramData.blue[i] = CGFloat(blueBins[i]) / maxBlue

        // 计算亮度（ITU-R BT.709标准）
        let lum = 0.2126 * Double(redBins[i]) +
                 0.7152 * Double(greenBins[i]) +
                 0.0722 * Double(blueBins[i])
        histogramData.luminance[i] = CGFloat(lum)
    }

    return histogramData
}
```

### 曝光分析

```swift
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
```

---

## 性能优化

### 1. 线程管理

```swift
// 使用串行队列处理相机操作
private let sessionQueue = DispatchQueue(label: "com.procammaster.sessionqueue")

// UI更新在主线程
DispatchQueue.main.async {
    self.isSessionRunning = self.session.isRunning
}
```

### 2. 内存优化

- 使用`autoreleasepool`处理大量图像
- 及时释放不用的CVPixelBuffer
- 限制直方图采样率（每4个像素采样1个）

```swift
autoreleasepool {
    // 图像处理代码
}
```

### 3. 电池优化

- 使用`AVCaptureDevice.Format`选择合适的格式
- 不使用时停止会话
- 降低预览帧率（可选）

### 4. 启动优化

- 延迟加载非必要组件
- 异步初始化相机
- 使用占位符视图

---

## 测试指南

### 单元测试

```swift
import XCTest
@testable import ProCamMaster

class CameraControllerTests: XCTestCase {
    var cameraController: CameraController!

    override func setUp() {
        super.setUp()
        cameraController = CameraController()
    }

    func testISORange() {
        // 测试ISO范围
        XCTAssertGreaterThanOrEqual(cameraController.capabilities.minISO, 25)
        XCTAssertLessThanOrEqual(cameraController.capabilities.maxISO, 12800)
    }

    func testCameraSwitch() {
        // 测试相机切换
        cameraController.switchCamera(to: .ultraWide)
        XCTAssertEqual(cameraController.currentSettings.currentCamera, .ultraWide)
    }
}
```

### UI测试

```swift
import XCTest

class CameraUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUp() {
        super.setUp()
        app.launch()
    }

    func testCapturePhoto() {
        // 点击快门按钮
        app.buttons["ShutterButton"].tap()

        // 验证拍照动画
        XCTAssertTrue(app.staticTexts["拍照成功"].exists)
    }
}
```

### 性能测试

```swift
func testCameraStartupPerformance() {
    measure {
        cameraController.startSession()
    }
}

func testHistogramGenerationPerformance() {
    let pixelBuffer = createTestPixelBuffer()

    measure {
        _ = histogramProcessor.generateHistogram(from: pixelBuffer)
    }
}
```

---

## 部署指南

### 1. 准备发布

```bash
# 清理构建
xcodebuild clean

# 归档
xcodebuild archive \
    -scheme ProCamMaster \
    -archivePath ./build/ProCamMaster.xcarchive

# 导出IPA
xcodebuild -exportArchive \
    -archivePath ./build/ProCamMaster.xcarchive \
    -exportPath ./build \
    -exportOptionsPlist ExportOptions.plist
```

### 2. TestFlight

1. 在App Store Connect创建应用
2. 上传构建
3. 填写测试信息
4. 邀请测试者

### 3. App Store提交

**必需素材**：
- App图标（1024x1024）
- 截图（多种设备尺寸）
- 预览视频（可选）
- 隐私政策URL
- 应用描述

**审核要点**：
- 相机权限说明清晰
- 功能描述准确
- 无崩溃和严重Bug
- 符合Apple审核指南

---

## 常见问题

### Q: 相机预览黑屏？
A: 检查相机权限、检查AVCaptureSession是否运行

### Q: ProRAW拍摄失败？
A: 确认设备支持ProRAW（iPhone 12 Pro及以上）

### Q: 手动对焦不生效？
A: 确认`focusMode`设置为`.locked`或`.manual`

### Q: 性能问题？
A: 降低直方图采样率、使用Metal加速、优化UI刷新

---

## 参考资料

- [Apple AVFoundation文档](https://developer.apple.com/documentation/avfoundation)
- [Apple Core Image文档](https://developer.apple.com/documentation/coreimage)
- [SwiftUI文档](https://developer.apple.com/documentation/swiftui)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)

---

最后更新：2025-11-14
