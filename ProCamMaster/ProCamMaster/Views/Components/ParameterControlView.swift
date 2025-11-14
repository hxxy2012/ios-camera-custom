//
//  ParameterControlView.swift
//  ProCam Master
//
//  参数控制视图组件
//  Created by Claude
//

import SwiftUI
import AVFoundation

// MARK: - 参数快捷条
struct ParameterBarView: View {
    @ObservedObject var viewModel: CameraViewModel

    var body: some View {
        HStack(spacing: 20) {
            // ISO
            ParameterButton(
                label: "ISO",
                value: viewModel.isoString,
                isActive: !viewModel.settings.exposure.isAutoISO
            ) {
                // 显示ISO调节器
            }

            // 快门速度
            ParameterButton(
                label: "S",
                value: viewModel.shutterSpeedString,
                isActive: !viewModel.settings.exposure.isAutoShutter
            ) {
                // 显示快门速度调节器
            }

            // 曝光补偿
            ParameterButton(
                label: "EV",
                value: viewModel.evString,
                isActive: viewModel.settings.exposure.exposureCompensation != 0
            ) {
                // 显示EV调节器
            }

            // 白平衡
            ParameterButton(
                label: "WB",
                value: viewModel.whiteBalanceString,
                isActive: viewModel.settings.whiteBalance.preset != .auto
            ) {
                // 显示白平衡调节器
            }

            // 对焦模式
            ParameterButton(
                label: "AF",
                value: viewModel.focusModeString,
                isActive: viewModel.settings.focus.mode != .autoSingle
            ) {
                // 显示对焦模式选择器
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.black.opacity(0.7))
        )
    }
}

// MARK: - 参数按钮
struct ParameterButton: View {
    let label: String
    let value: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)

                Text(value)
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundColor(isActive ? .orange : .white)
            }
            .frame(minWidth: 50)
        }
    }
}

// MARK: - ISO调节器
struct ISOControlView: View {
    @ObservedObject var viewModel: CameraViewModel
    @State private var currentISO: Float = 100

    var body: some View {
        VStack(spacing: 20) {
            // 标题
            HStack {
                Text("ISO")
                    .font(.headline)

                Spacer()

                // Auto按钮
                Button(action: {
                    viewModel.toggleAutoISO()
                }) {
                    Text("AUTO")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            viewModel.settings.exposure.isAutoISO ? Color.orange : Color.gray.opacity(0.3)
                        )
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }

            // ISO滑块
            VStack(spacing: 8) {
                Slider(
                    value: $currentISO,
                    in: viewModel.isoRange,
                    step: 25,
                    onEditingChanged: { editing in
                        if !editing {
                            viewModel.setISO(currentISO)
                        }
                    }
                )
                .accentColor(.orange)
                .disabled(viewModel.settings.exposure.isAutoISO)

                // 数值显示
                Text("ISO \(Int(currentISO))")
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }

            // 快捷预设
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.getCommonISOValues(), id: \.self) { iso in
                        Button(action: {
                            currentISO = iso
                            viewModel.setISO(iso)
                        }) {
                            Text("\(Int(iso))")
                                .font(.system(.body, design: .monospaced))
                                .fontWeight(.medium)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    currentISO == iso ? Color.orange : Color.gray.opacity(0.3)
                                )
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.black.opacity(0.9))
        )
        .onAppear {
            currentISO = viewModel.settings.exposure.iso
        }
    }
}

// MARK: - 快门速度调节器
struct ShutterSpeedControlView: View {
    @ObservedObject var viewModel: CameraViewModel
    @State private var selectedIndex: Int = 6

    let shutterSpeeds = [
        (value: 8000, display: "1/8000"),
        (value: 4000, display: "1/4000"),
        (value: 2000, display: "1/2000"),
        (value: 1000, display: "1/1000"),
        (value: 500, display: "1/500"),
        (value: 250, display: "1/250"),
        (value: 125, display: "1/125"),
        (value: 60, display: "1/60"),
        (value: 30, display: "1/30"),
        (value: 15, display: "1/15"),
        (value: 8, display: "1/8"),
        (value: 4, display: "1/4"),
        (value: 2, display: "1/2"),
        (value: 1, display: "1\""),
    ]

    var body: some View {
        VStack(spacing: 20) {
            // 标题
            HStack {
                Text("快门速度")
                    .font(.headline)

                Spacer()

                // Auto按钮
                Button(action: {
                    viewModel.toggleAutoShutter()
                }) {
                    Text("AUTO")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            viewModel.settings.exposure.isAutoShutter ? Color.orange : Color.gray.opacity(0.3)
                        )
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }

            // Picker
            Picker("快门速度", selection: $selectedIndex) {
                ForEach(0..<shutterSpeeds.count, id: \.self) { index in
                    Text(shutterSpeeds[index].display)
                        .tag(index)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 150)
            .onChange(of: selectedIndex) { newValue in
                let speed = shutterSpeeds[newValue]
                viewModel.setShutterSpeed(fraction: speed.value)
            }

            // 当前值显示
            Text(shutterSpeeds[selectedIndex].display)
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .foregroundColor(.orange)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.black.opacity(0.9))
        )
    }
}

// MARK: - 曝光补偿调节器
struct EVControlView: View {
    @ObservedObject var viewModel: CameraViewModel
    @State private var currentEV: Float = 0.0

    var body: some View {
        VStack(spacing: 20) {
            // 标题
            Text("曝光补偿")
                .font(.headline)

            // EV滑块
            VStack(spacing: 8) {
                HStack {
                    Text("-3")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Slider(
                        value: $currentEV,
                        in: viewModel.evRange,
                        step: 0.3,
                        onEditingChanged: { editing in
                            if !editing {
                                viewModel.setExposureCompensation(currentEV)
                            }
                        }
                    )
                    .accentColor(.orange)

                    Text("+3")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // 数值显示
                Text(String(format: "%+.1f EV", currentEV))
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundColor(currentEV == 0 ? .white : .orange)
            }

            // 重置按钮
            Button(action: {
                currentEV = 0
                viewModel.setExposureCompensation(0)
            }) {
                Text("重置")
                    .font(.body)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.gray.opacity(0.3))
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.black.opacity(0.9))
        )
        .onAppear {
            currentEV = viewModel.settings.exposure.exposureCompensation
        }
    }
}

// MARK: - 白平衡调节器
struct WhiteBalanceControlView: View {
    @ObservedObject var viewModel: CameraViewModel

    var body: some View {
        VStack(spacing: 20) {
            // 标题
            Text("白平衡")
                .font(.headline)

            // 预设选择
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(WhiteBalancePreset.allCases) { preset in
                        Button(action: {
                            viewModel.setWhiteBalancePreset(preset)
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: preset.icon)
                                    .font(.system(size: 20))

                                Text(preset.rawValue)
                                    .font(.caption2)
                            }
                            .frame(width: 70, height: 70)
                            .background(
                                viewModel.settings.whiteBalance.preset == preset ? Color.orange : Color.gray.opacity(0.3)
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                    }
                }
            }

            // 自定义色温
            if viewModel.settings.whiteBalance.preset == .custom {
                VStack(spacing: 12) {
                    Text("色温: \(Int(viewModel.settings.whiteBalance.temperature))K")
                        .font(.system(.body, design: .monospaced))

                    Slider(
                        value: Binding(
                            get: { viewModel.settings.whiteBalance.temperature },
                            set: { viewModel.setWhiteBalanceTemperature($0) }
                        ),
                        in: 2000...10000,
                        step: 100
                    )
                    .accentColor(.orange)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.black.opacity(0.9))
        )
    }
}

// MARK: - 对焦模式选择器
struct FocusModeControlView: View {
    @ObservedObject var viewModel: CameraViewModel

    var body: some View {
        VStack(spacing: 20) {
            // 标题
            Text("对焦模式")
                .font(.headline)

            // 模式选择
            HStack(spacing: 12) {
                ForEach(FocusMode.allCases) { mode in
                    Button(action: {
                        viewModel.setFocusMode(mode)
                    }) {
                        VStack(spacing: 8) {
                            Text(mode.rawValue)
                                .font(.system(size: 18, weight: .bold, design: .monospaced))

                            Text(mode.description)
                                .font(.caption2)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            viewModel.settings.focus.mode == mode ? Color.orange : Color.gray.opacity(0.3)
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
            }

            // 手动对焦滑块
            if viewModel.settings.focus.mode == .manual {
                VStack(spacing: 12) {
                    Text("对焦距离")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack {
                        Text("近")
                            .font(.caption)

                        Slider(
                            value: Binding(
                                get: { viewModel.settings.focus.lensPosition },
                                set: { viewModel.setManualFocus(lensPosition: $0) }
                            ),
                            in: 0...1
                        )
                        .accentColor(.orange)

                        Text("远")
                            .font(.caption)
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.black.opacity(0.9))
        )
    }
}
