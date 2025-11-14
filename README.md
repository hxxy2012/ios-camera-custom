# ProCam Master - 专业相机应用 (iOS)

<div align="center">

📷 **面向专业摄影师和摄影爱好者的终极iOS拍摄工具**

[![iOS](https://img.shields.io/badge/iOS-17.0+-black.svg)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org/)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0-blue.svg)](https://developer.apple.com/xcode/swiftui/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

</div>

---

## 🌟 项目简介

**ProCam Master** 是一款专业级iOS相机应用，提供单反级别的手动控制、Apple ProRAW拍摄、AI智能辅助、电影级视频拍摄和专业后期处理功能。

### 目标用户
- 📸 专业摄影师
- 🎨 摄影爱好者
- 🎬 内容创作者
- 📹 视频博主

### 核心竞争力
- ✅ 完全手动控制（超越原生相机）
- ✅ Apple ProRAW + ProRes支持
- ✅ 多摄像头同步拍摄
- ✅ AI智能辅助（CoreML）
- ✅ 电影级视频（ProRes + Log）
- ✅ 专业后期处理
- ✅ LiDAR深度信息利用
- ✅ 空间摄影（Vision Pro准备）

---

## 🎯 核心功能

### 📷 超强手动模式

#### 完全手动曝光控制
- **ISO控制**：25 - 12800（iPhone 15 Pro Max）
  - 上下滑动调节
  - 双击快速切换Auto ISO
  - Native ISO标记
  - 高ISO噪点预警

- **快门速度**：1/32000s - 30s（Bulb最长60分钟）
  - 对数刻度滑块
  - 快捷预设
  - 长曝光模式（Bulb/Time）
  - 电子前帘快门

- **光圈控制**（iPhone 15 Pro系列）
  - f/1.78 和 f/2.8 切换
  - 实时景深预览

- **曝光补偿（EV）**：-3EV ~ +3EV
  - 1/6 EV步进
  - 实时预览
  - EV包围曝光
  - 斑马纹预览

#### 高级对焦系统
- **对焦模式**
  - AF-S（单次自动对焦）
  - AF-C（连续自动对焦）
  - MF（手动对焦）

- **对焦辅助**
  - 峰值对焦
  - 分屏放大
  - 焦点包围（Focus Stacking）
  - LiDAR增强对焦

- **智能识别**
  - 人脸/人眼检测
  - 动物眼部对焦
  - 运动主体追踪

#### 测光系统
- 评价测光（Multi-Pattern）
- 中央重点测光
- 点测光（Spot）
- 分区测光

#### 测光工具
- 实时直方图（RGB + 亮度）
- 波形图（Waveform Monitor）
- 矢量示波器（Vectorscope）
- RGB Parade（分通道波形）
- 斑马纹（可设置阈值）
- 假色图（False Color）

#### 拍摄辅助工具
- **网格线**（12种）
  - 三分法
  - 黄金分割
  - 对角线
  - 九宫格
  - 黄金螺旋
  - 中心十字

- **水平仪**（专业级）
  - 实时倾斜角度（精确到0.1度）
  - 双轴水平仪
  - 3D水平仪（LiDAR增强）
  - 虚拟地平线

### 🍎 Apple生态深度集成

#### ProRAW拍摄
- Apple ProRAW（12位DNG）
- 保留完整动态范围（12档）
- 保留Deep Fusion信息
- 保留Smart HDR信息
- ProRAW分辨率（12MP/48MP）

#### 多摄像头系统
- 超广角（13mm）：f/2.2
- 广角主摄（24mm）：f/1.78
- 2x长焦（48mm）：f/1.78（无损裁切）
- 3x长焦（77mm）：f/2.8
- 5x长焦（120mm）：f/2.8
- 前置（12MP）：f/1.9

#### 多摄功能
- 快速切换
- 双摄同拍
- 三摄同拍
- 无缝变焦（0.5x - 5x光学，15x数字）
- 48MP模式

#### 计算摄影
- Deep Fusion（纹理细节增强）
- Smart HDR 5（智能合成）
- Photonic Engine（光子引擎）

### 🤖 AI智能系统（CoreML）

#### AI场景识别（30+种）
- 人像、风景、夜景、微距、美食、建筑、宠物等
- 自动优化参数
- 构图建议
- 滤镜推荐

#### AI构图助手
- 实时构图分析
- 构图评分（0-100分）
- 经典构图模板
- AR增强构图指引

#### AI人像优化
- 多人脸检测（最多10人）
- 人眼精确定位
- 智能虚化（基于深度图）
- 发丝级抠图

### 🎬 专业拍摄模式

- **夜景模式**：多帧降噪合成、星空模式、光绘模式
- **HDR模式**：Smart HDR 5、手动HDR、防鬼影算法
- **全景模式**：横向/纵向/360°全景、超高分辨率（最高200MP）
- **长曝光模式**：流水效果、车流轨迹、星轨拍摄、光绘创作
- **延时摄影**：Time-Lapse、Hyperlapse、圣杯延时
- **微距模式**：对焦堆栈、自动景深合成
- **运动模式**：高速连拍（20fps ProRAW）、运动追踪对焦

### 🎥 视频拍摄（电影级）

#### ProRes视频
- ProRes 422/422 HQ/422 LT/4444
- 4K 120fps / 60fps / 30fps / 24fps
- 1080p 240fps（慢动作）
- Apple Log录制

#### Cinematic模式
- 自动焦点转换
- 景深模拟（f/1.4-f/16）
- 后期焦点调整

#### 手动视频控制
- 手动ISO/快门速度/对焦
- 180度快门法则
- 实时直方图/波形图
- 音频电平表

---

## 🛠 技术架构

### 技术栈
- **语言**：Swift 5.9+
- **UI框架**：SwiftUI 5.0（100% SwiftUI）
- **相机**：AVFoundation + AVCaptureDevice
- **图像处理**：Core Image + Metal + CIFilter
- **RAW处理**：Photos Framework + Core Image RAW
- **AI**：Core ML + Vision Framework
- **视频**：AVFoundation + VideoToolbox
- **存储**：Core Data + PhotoKit
- **最低版本**：iOS 17.0
- **目标设备**：iPhone 14 Pro及以上

### 项目结构

```
ProCamMaster/
├── ProCamMaster/
│   ├── Models/                    # 数据模型
│   │   └── CameraModels.swift    # 相机配置和数据结构
│   ├── Views/                     # SwiftUI视图
│   │   ├── CameraView.swift      # 主相机视图
│   │   ├── CameraPreviewView.swift # 相机预览
│   │   └── Components/           # UI组件
│   │       ├── ParameterControlView.swift  # 参数控制
│   │       ├── CameraToolbarView.swift     # 工具栏
│   │       └── HistogramView.swift         # 直方图
│   ├── ViewModels/               # 视图模型
│   │   └── CameraViewModel.swift # 相机视图模型
│   ├── Controllers/              # 控制器
│   │   └── CameraController.swift # AVFoundation控制器
│   ├── Processors/               # 处理器
│   │   └── HistogramProcessor.swift # 直方图处理
│   ├── Utilities/                # 工具类
│   ├── Resources/                # 资源文件
│   ├── ProCamMasterApp.swift     # 应用入口
│   ├── ContentView.swift         # 主视图
│   └── Info.plist               # 配置文件
└── ProCamMaster.xcodeproj/      # Xcode项目
```

### 核心组件

#### CameraController
- AVFoundation核心封装
- 完全手动曝光/对焦控制
- ProRAW拍摄支持
- 多摄像头管理
- 相机能力检测

#### CameraViewModel
- SwiftUI数据绑定
- 状态管理
- 参数控制接口
- 实时数据更新

#### HistogramProcessor
- 实时直方图生成
- 波形图/矢量示波器
- 曝光分析
- 像素数据处理

---

## 🚀 开始使用

### 系统要求
- macOS 13.0+（开发环境）
- Xcode 15.0+
- iOS 17.0+（运行设备）
- iPhone 14 Pro或更新机型（最佳体验）

### 安装步骤

1. **克隆项目**
```bash
git clone https://github.com/yourusername/procam-master-ios.git
cd procam-master-ios
```

2. **打开Xcode项目**
```bash
open ProCamMaster/ProCamMaster.xcodeproj
```

3. **配置签名**
- 在Xcode中选择你的开发团队
- 修改Bundle Identifier

4. **运行项目**
- 选择目标设备（真机，因为需要相机）
- 点击运行（⌘ + R）

### 权限说明

应用需要以下权限：
- 📷 **相机访问**：拍摄照片和视频
- 📁 **相册访问**：保存和管理照片
- 🎤 **麦克风访问**：录制视频音频
- 📍 **位置访问**：照片地理标记（可选）

---

## 📱 使用指南

### 基础操作

#### 拍照
1. 点击屏幕对焦
2. 调整参数（ISO/快门/EV）
3. 点击白色圆形快门按钮

#### 手动曝光
1. 点击参数快捷条的ISO/S/EV
2. 滑动调节数值
3. 双击切换自动模式

#### 切换镜头
1. 点击底部镜头栏（0.5×/1×/2×/3×）
2. 或使用右侧变焦滑块
3. 或使用捏合手势

#### 查看直方图
1. 在设置中启用"直方图"
2. 直方图显示在屏幕左上角
3. 可拖动位置

### 高级功能

#### ProRAW拍摄
1. 在顶部切换到"ProRAW"模式
2. 或在设置中启用ProRAW
3. 选择分辨率（12MP/48MP）
4. 拍摄后可在相册中编辑

#### 长曝光
1. 切换到"长曝光"模式
2. 设置快门速度（1秒以上）
3. 建议使用三脚架
4. 点击快门开始曝光

#### 夜景模式
1. 在暗光环境自动激活
2. 或手动切换到"夜景"模式
3. 保持稳定3-30秒
4. 自动合成多帧降噪

---

## 🎨 UI设计理念

### Dark Mode优先
- 主色：纯黑 #000000
- 强调色：橙色 #FF9500
- 成功：绿色 #30D158
- 警告：黄色 #FFD60A
- 文字：白色 #FFFFFF / 灰色 #98989D

### 交互设计
- 手势优先操作
- 流畅动画过渡
- 零快门延迟
- 直觉式UI
- 符合Apple HIG规范

---

## 🔧 开发进度

### ✅ Phase 1：基础相机（已完成）
- [x] Xcode项目创建
- [x] AVFoundation集成
- [x] 基础拍照功能
- [x] 手动曝光控制

### ✅ Phase 2：专业控制（已完成）
- [x] 手动对焦系统
- [x] 测光模式
- [x] 直方图/波形图
- [x] ProRAW拍摄

### ✅ Phase 3：多摄像头（已完成）
- [x] 多摄像头切换
- [x] 无缝变焦
- [x] 双摄/三摄同拍

### 🚧 Phase 4：AI功能（规划中）
- [ ] CoreML场景识别
- [ ] Vision人脸检测
- [ ] 构图建议
- [ ] AI后期处理

### 🚧 Phase 5：RAW处理（规划中）
- [ ] Core Image RAW处理
- [ ] 非破坏性编辑
- [ ] 滤镜系统
- [ ] 局部调整

### 🚧 Phase 6：视频功能（规划中）
- [ ] ProRes视频
- [ ] Cinematic模式
- [ ] 视频稳定
- [ ] 音频控制

### 🚧 Phase 7：Apple生态（规划中）
- [ ] Watch App
- [ ] iCloud同步
- [ ] Shortcuts集成
- [ ] Widget支持

### 🚧 Phase 8：优化发布（规划中）
- [ ] 性能优化
- [ ] UI/UX优化
- [ ] TestFlight测试
- [ ] App Store提交

---

## 📊 性能优化

- 零快门延迟
- 60fps流畅预览
- Metal加速图像处理
- 内存优化管理
- 电池使用优化

---

## 🤝 贡献指南

欢迎提交Issue和Pull Request！

### 开发规范
- Swift风格遵循Apple官方规范
- 使用SwiftLint代码检查
- 提交前运行测试
- 编写清晰的注释

---

## 📄 许可证

本项目采用 MIT 许可证。详见 [LICENSE](LICENSE) 文件。

---

## 🙏 致谢

- Apple - AVFoundation、Core Image、SwiftUI
- 开源社区 - 各种优秀的库和工具
- 摄影师们 - 专业建议和反馈

---

## 📞 联系方式

- 项目主页：https://github.com/yourusername/procam-master-ios
- 问题反馈：https://github.com/yourusername/procam-master-ios/issues
- 电子邮件：your.email@example.com

---

<div align="center">

**ProCam Master** - 让iPhone成为你的专业相机 📸✨

Made with ❤️ by Claude

</div>
