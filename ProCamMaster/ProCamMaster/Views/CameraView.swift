//
//  CameraView.swift
//  ProCam Master
//
//  主相机视图
//  Created by Claude
//

import SwiftUI

struct CameraView: View {
    @StateObject private var viewModel = CameraViewModel()
    @State private var showingParameterControl: ParameterControlType?
    @State private var focusPoint: CGPoint?
    @State private var showFocusBox = false

    enum ParameterControlType: Identifiable {
        case iso
        case shutterSpeed
        case ev
        case whiteBalance
        case focusMode

        var id: Int {
            hashValue
        }
    }

    var body: some View {
        ZStack {
            // 相机预览（全屏）
            CameraPreviewView(session: viewModel.getCameraSession())
                .ignoresSafeArea()
                .onAppear {
                    viewModel.startCamera()
                }
                .onDisappear {
                    viewModel.stopCamera()
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onEnded { value in
                            handleTap(at: value.location)
                        }
                )

            // 拍照闪光动画
            if viewModel.showCaptureAnimation {
                Color.white
                    .ignoresSafeArea()
                    .opacity(0.8)
                    .transition(.opacity)
            }

            // 网格线
            if viewModel.settings.gridType != .none {
                GridOverlayView(
                    gridType: viewModel.settings.gridType,
                    size: UIScreen.main.bounds.size
                )
                .allowsHitTesting(false)
            }

            // 对焦框
            if showFocusBox, let point = focusPoint {
                FocusBoxView(
                    point: point,
                    isLocked: viewModel.settings.focus.isLocked
                )
            }

            // UI叠加层
            VStack(spacing: 0) {
                // 顶部工具栏
                TopToolbarView(viewModel: viewModel)
                    .padding(.top, 50)

                Spacer()

                // 信息叠加（如果启用）
                if viewModel.settings.isInfoOverlayVisible {
                    InfoOverlayView(viewModel: viewModel)
                        .allowsHitTesting(false)
                }

                Spacer()

                // 相机镜头切换栏
                CameraLensBarView(viewModel: viewModel)
                    .padding(.bottom, 12)

                // 参数快捷条
                ParameterBarView(viewModel: viewModel)
                    .padding(.bottom, 20)
                    .onTapGesture {
                        // 可以添加点击事件
                    }

                // 底部操作栏
                BottomToolbarView(viewModel: viewModel)
                    .padding(.bottom, 40)
            }

            // 右侧变焦滑块
            VStack {
                Spacer()

                HStack {
                    Spacer()

                    ZoomSliderView(viewModel: viewModel)
                        .padding(.trailing, 16)
                        .padding(.bottom, 160)
                }
            }

            // 参数控制面板（底部弹出）
            if let controlType = showingParameterControl {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring()) {
                            showingParameterControl = nil
                        }
                    }

                VStack {
                    Spacer()

                    parameterControlView(for: controlType)
                        .transition(.move(edge: .bottom))
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                }
            }
        }
        .preferredColorScheme(.dark)
        .statusBar(hidden: true)
        .sheet(isPresented: $viewModel.isShowingGallery) {
            GalleryView()
        }
        .sheet(isPresented: $viewModel.isShowingSettings) {
            SettingsView(viewModel: viewModel)
        }
        .alert("错误", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("确定") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
    }

    // MARK: - Helper Methods

    @ViewBuilder
    private func parameterControlView(for type: ParameterControlType) -> some View {
        switch type {
        case .iso:
            ISOControlView(viewModel: viewModel)
        case .shutterSpeed:
            ShutterSpeedControlView(viewModel: viewModel)
        case .ev:
            EVControlView(viewModel: viewModel)
        case .whiteBalance:
            WhiteBalanceControlView(viewModel: viewModel)
        case .focusMode:
            FocusModeControlView(viewModel: viewModel)
        }
    }

    private func handleTap(at location: CGPoint) {
        let screenSize = UIScreen.main.bounds.size

        // 转换为0-1范围的坐标
        let point = CGPoint(
            x: location.x / screenSize.width,
            y: location.y / screenSize.height
        )

        // 设置对焦点
        viewModel.focusAt(point: point)

        // 显示对焦框
        focusPoint = location
        showFocusBox = true

        // 2秒后隐藏对焦框
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showFocusBox = false
            }
        }
    }
}

// MARK: - 临时画廊视图
struct GalleryView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack {
                Text("相册功能开发中...")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            .navigationTitle("相册")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 设置视图
struct SettingsView: View {
    @ObservedObject var viewModel: CameraViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Form {
                // 拍摄设置
                Section("拍摄设置") {
                    Toggle("ProRAW", isOn: $viewModel.settings.isProRAWEnabled)

                    if viewModel.settings.isProRAWEnabled {
                        Picker("ProRAW分辨率", selection: $viewModel.settings.proRAWResolution) {
                            Text("12MP").tag(CameraSettings.ProRAWResolution.mp12)
                            Text("48MP").tag(CameraSettings.ProRAWResolution.mp48)
                        }
                    }
                }

                // 显示设置
                Section("显示设置") {
                    Toggle("直方图", isOn: $viewModel.settings.isHistogramVisible)
                    Toggle("水平仪", isOn: $viewModel.settings.isLevelVisible)
                    Toggle("信息叠加", isOn: $viewModel.settings.isInfoOverlayVisible)

                    Picker("网格线", selection: $viewModel.settings.gridType) {
                        ForEach(GridType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                }

                // 对焦设置
                Section("对焦设置") {
                    Toggle("对焦峰值", isOn: $viewModel.settings.focus.isPeakingEnabled)

                    if viewModel.settings.focus.isPeakingEnabled {
                        Picker("峰值颜色", selection: $viewModel.settings.focus.peakingColor) {
                            ForEach(FocusSettings.PeakingColor.allCases, id: \.self) { color in
                                Text(color.rawValue).tag(color)
                            }
                        }
                    }
                }

                // 相机能力信息
                Section("相机能力") {
                    LabeledContent("ISO范围", value: "\(Int(viewModel.capabilities.minISO)) - \(Int(viewModel.capabilities.maxISO))")
                    LabeledContent("ProRAW支持", value: viewModel.capabilities.supportsProRAW ? "是" : "否")
                    LabeledContent("48MP支持", value: viewModel.capabilities.supports48MP ? "是" : "否")
                    LabeledContent("超广角", value: viewModel.capabilities.hasUltraWide ? "是" : "否")
                    LabeledContent("长焦", value: viewModel.capabilities.hasTelephoto ? "是" : "否")
                    LabeledContent("LiDAR", value: viewModel.capabilities.hasLiDAR ? "是" : "否")
                }

                // 关于
                Section("关于") {
                    LabeledContent("版本", value: "1.0.0")
                    LabeledContent("构建号", value: "1")
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 预览
struct CameraView_Previews: PreviewProvider {
    static var previews: some View {
        CameraView()
    }
}
