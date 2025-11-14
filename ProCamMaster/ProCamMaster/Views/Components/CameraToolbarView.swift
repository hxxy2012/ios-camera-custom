//
//  CameraToolbarView.swift
//  ProCam Master
//
//  相机工具栏视图组件
//  Created by Claude
//

import SwiftUI

// MARK: - 顶部工具栏
struct TopToolbarView: View {
    @ObservedObject var viewModel: CameraViewModel

    var body: some View {
        HStack {
            // 闪光灯
            Button(action: {
                // 切换闪光灯
            }) {
                Image(systemName: "bolt.slash.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(.black.opacity(0.5)))
            }

            Spacer()

            // 拍摄模式
            Menu {
                ForEach(ShootingMode.allCases) { mode in
                    Button(action: {
                        viewModel.setShootingMode(mode)
                    }) {
                        Label(mode.rawValue, systemImage: mode.icon)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: viewModel.settings.shootingMode.icon)
                    Text(viewModel.settings.shootingMode.rawValue)
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(.black.opacity(0.6))
                )
            }

            Spacer()

            // 设置
            Button(action: {
                viewModel.isShowingSettings.toggle()
            }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(.black.opacity(0.5)))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
}

// MARK: - 底部操作栏
struct BottomToolbarView: View {
    @ObservedObject var viewModel: CameraViewModel

    var body: some View {
        HStack(spacing: 0) {
            // 相册按钮
            Button(action: {
                viewModel.isShowingGallery.toggle()
            }) {
                Image(systemName: "photo.on.rectangle")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
            }

            Spacer()

            // 快门按钮
            ShutterButtonView(viewModel: viewModel)

            Spacer()

            // 相机切换按钮
            Button(action: {
                // 切换前后相机
                if viewModel.settings.currentCamera == .front {
                    viewModel.switchCamera(to: .wide)
                } else {
                    viewModel.switchCamera(to: .front)
                }
            }) {
                Image(systemName: "arrow.triangle.2.circlepath.camera")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
            }
        }
        .padding(.horizontal, 30)
    }
}

// MARK: - 快门按钮
struct ShutterButtonView: View {
    @ObservedObject var viewModel: CameraViewModel
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            viewModel.capturePhoto()
        }) {
            ZStack {
                // 外圈
                Circle()
                    .strokeBorder(.white, lineWidth: 4)
                    .frame(width: 80, height: 80)

                // 内圈
                Circle()
                    .fill(.white)
                    .frame(width: 66, height: 66)
                    .scaleEffect(isPressed ? 0.9 : 1.0)

                // ProRAW指示器
                if viewModel.settings.isProRAWEnabled {
                    Text("RAW")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.black)
                }
            }
        }
        .buttonStyle(ShutterButtonStyle(isPressed: $isPressed))
    }
}

struct ShutterButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .onChange(of: configuration.isPressed) { newValue in
                isPressed = newValue
            }
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - 相机镜头切换栏
struct CameraLensBarView: View {
    @ObservedObject var viewModel: CameraViewModel

    let availableLenses: [CameraType] = [
        .ultraWide,
        .wide,
        .telephoto2x,
        .telephoto3x
    ]

    var body: some View {
        HStack(spacing: 16) {
            ForEach(availableLenses) { lens in
                Button(action: {
                    viewModel.switchCamera(to: lens)
                }) {
                    VStack(spacing: 4) {
                        Text(lens.icon)
                            .font(.system(size: 16, weight: .semibold))

                        Text(lens.focalLength)
                            .font(.system(size: 10))
                    }
                    .foregroundColor(
                        viewModel.settings.currentCamera == lens ? .orange : .white
                    )
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(
                                viewModel.settings.currentCamera == lens ?
                                Color.orange.opacity(0.2) : Color.clear
                            )
                    )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(.black.opacity(0.6))
        )
    }
}

// MARK: - 变焦滑块
struct ZoomSliderView: View {
    @ObservedObject var viewModel: CameraViewModel
    @State private var zoomFactor: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 8) {
            // 变焦倍数显示
            Text(String(format: "%.1f×", zoomFactor))
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(.black.opacity(0.7))
                )

            // 变焦滑块
            Slider(
                value: $zoomFactor,
                in: 0.5...10.0,
                step: 0.1,
                onEditingChanged: { editing in
                    if !editing {
                        viewModel.setZoom(zoomFactor)
                    }
                }
            )
            .accentColor(.orange)
            .frame(height: 120)
            .rotationEffect(.degrees(-90))
            .frame(width: 40, height: 120)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.black.opacity(0.5))
        )
        .onAppear {
            zoomFactor = viewModel.settings.zoomFactor
        }
    }
}

// MARK: - 网格线视图
struct GridOverlayView: View {
    let gridType: GridType
    let size: CGSize

    var body: some View {
        GeometryReader { geometry in
            switch gridType {
            case .none:
                EmptyView()

            case .ruleOfThirds:
                RuleOfThirdsGrid()

            case .goldenRatio:
                GoldenRatioGrid()

            case .diagonal:
                DiagonalGrid()

            case .square:
                SquareGrid()

            case .center:
                CenterCrossGrid()
            }
        }
    }
}

// 三分法网格
struct RuleOfThirdsGrid: View {
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height

            Path { path in
                // 垂直线
                path.move(to: CGPoint(x: width / 3, y: 0))
                path.addLine(to: CGPoint(x: width / 3, y: height))

                path.move(to: CGPoint(x: width * 2 / 3, y: 0))
                path.addLine(to: CGPoint(x: width * 2 / 3, y: height))

                // 水平线
                path.move(to: CGPoint(x: 0, y: height / 3))
                path.addLine(to: CGPoint(x: width, y: height / 3))

                path.move(to: CGPoint(x: 0, y: height * 2 / 3))
                path.addLine(to: CGPoint(x: width, y: height * 2 / 3))
            }
            .stroke(.white.opacity(0.5), lineWidth: 1)
        }
    }
}

// 黄金分割网格
struct GoldenRatioGrid: View {
    let goldenRatio: CGFloat = 0.618

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height

            Path { path in
                // 垂直线
                path.move(to: CGPoint(x: width * goldenRatio, y: 0))
                path.addLine(to: CGPoint(x: width * goldenRatio, y: height))

                path.move(to: CGPoint(x: width * (1 - goldenRatio), y: 0))
                path.addLine(to: CGPoint(x: width * (1 - goldenRatio), y: height))

                // 水平线
                path.move(to: CGPoint(x: 0, y: height * goldenRatio))
                path.addLine(to: CGPoint(x: width, y: height * goldenRatio))

                path.move(to: CGPoint(x: 0, y: height * (1 - goldenRatio)))
                path.addLine(to: CGPoint(x: width, y: height * (1 - goldenRatio)))
            }
            .stroke(.white.opacity(0.5), lineWidth: 1)
        }
    }
}

// 对角线网格
struct DiagonalGrid: View {
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                path.move(to: .zero)
                path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height))

                path.move(to: CGPoint(x: geometry.size.width, y: 0))
                path.addLine(to: CGPoint(x: 0, y: geometry.size.height))
            }
            .stroke(.white.opacity(0.5), lineWidth: 1)
        }
    }
}

// 方格网格
struct SquareGrid: View {
    let divisions = 6

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let cellWidth = width / CGFloat(divisions)
            let cellHeight = height / CGFloat(divisions)

            Path { path in
                // 垂直线
                for i in 1..<divisions {
                    let x = cellWidth * CGFloat(i)
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: height))
                }

                // 水平线
                for i in 1..<divisions {
                    let y = cellHeight * CGFloat(i)
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: width, y: y))
                }
            }
            .stroke(.white.opacity(0.3), lineWidth: 0.5)
        }
    }
}

// 中心十字
struct CenterCrossGrid: View {
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let centerX = width / 2
            let centerY = height / 2

            Path { path in
                // 垂直线
                path.move(to: CGPoint(x: centerX, y: 0))
                path.addLine(to: CGPoint(x: centerX, y: height))

                // 水平线
                path.move(to: CGPoint(x: 0, y: centerY))
                path.addLine(to: CGPoint(x: width, y: centerY))
            }
            .stroke(.white.opacity(0.6), lineWidth: 1.5)
        }
    }
}

// MARK: - 对焦框视图
struct FocusBoxView: View {
    let point: CGPoint
    let isLocked: Bool
    @State private var animate = false

    var body: some View {
        Rectangle()
            .stroke(isLocked ? Color.green : Color.orange, lineWidth: 2)
            .frame(width: 80, height: 80)
            .position(point)
            .scaleEffect(animate ? 1.0 : 1.2)
            .opacity(animate ? 1.0 : 0.8)
            .onAppear {
                withAnimation(.easeOut(duration: 0.3)) {
                    animate = true
                }
            }
    }
}

// MARK: - 信息叠加层
struct InfoOverlayView: View {
    @ObservedObject var viewModel: CameraViewModel

    var body: some View {
        VStack {
            HStack(alignment: .top) {
                // 左侧信息
                VStack(alignment: .leading, spacing: 8) {
                    InfoText("ISO \(Int(viewModel.settings.exposure.iso))")
                    InfoText(viewModel.settings.exposure.shutterSpeedString)
                    InfoText(viewModel.evString)
                }

                Spacer()

                // 右侧信息
                VStack(alignment: .trailing, spacing: 8) {
                    InfoText(viewModel.whiteBalanceString)
                    InfoText(viewModel.focusModeString)
                    InfoText("\(String(format: "%.1f", viewModel.settings.zoomFactor))×")
                }
            }
            .padding(16)

            Spacer()
        }
    }
}

struct InfoText: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .medium, design: .monospaced))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(.black.opacity(0.5))
            )
    }
}
