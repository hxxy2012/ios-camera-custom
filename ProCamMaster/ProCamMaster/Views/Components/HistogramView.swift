//
//  HistogramView.swift
//  ProCam Master
//
//  直方图显示视图
//  Created by Claude
//

import SwiftUI

// MARK: - 直方图视图
struct HistogramView: View {
    let data: HistogramData
    let showRGB: Bool
    let showLuminance: Bool

    init(data: HistogramData, showRGB: Bool = true, showLuminance: Bool = true) {
        self.data = data
        self.showRGB = showRGB
        self.showLuminance = showLuminance
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // 背景
                RoundedRectangle(cornerRadius: 8)
                    .fill(.black.opacity(0.7))

                // 直方图绘制
                Canvas { context, size in
                    let width = size.width
                    let height = size.height
                    let barWidth = width / 256

                    // 绘制亮度直方图
                    if showLuminance {
                        for i in 0..<256 {
                            let barHeight = height * data.luminance[i]
                            let x = CGFloat(i) * barWidth
                            let rect = CGRect(x: x, y: height - barHeight, width: barWidth, height: barHeight)

                            context.fill(
                                Path(rect),
                                with: .color(.white.opacity(0.6))
                            )
                        }
                    }

                    // 绘制RGB直方图
                    if showRGB {
                        // Red
                        for i in 0..<256 {
                            let barHeight = height * data.red[i] * 0.8
                            let x = CGFloat(i) * barWidth
                            let rect = CGRect(x: x, y: height - barHeight, width: barWidth, height: barHeight)

                            context.fill(
                                Path(rect),
                                with: .color(.red.opacity(0.5))
                            )
                        }

                        // Green
                        for i in 0..<256 {
                            let barHeight = height * data.green[i] * 0.8
                            let x = CGFloat(i) * barWidth
                            let rect = CGRect(x: x, y: height - barHeight, width: barWidth, height: barHeight)

                            context.fill(
                                Path(rect),
                                with: .color(.green.opacity(0.5))
                            )
                        }

                        // Blue
                        for i in 0..<256 {
                            let barHeight = height * data.blue[i] * 0.8
                            let x = CGFloat(i) * barWidth
                            let rect = CGRect(x: x, y: height - barHeight, width: barWidth, height: barHeight)

                            context.fill(
                                Path(rect),
                                with: .color(.blue.opacity(0.5))
                            )
                        }
                    }
                }
                .padding(4)
            }
        }
        .frame(width: 200, height: 100)
    }
}

// MARK: - 波形图视图
struct WaveformView: View {
    let data: HistogramData

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景
                RoundedRectangle(cornerRadius: 8)
                    .fill(.black.opacity(0.7))

                // 波形绘制
                Canvas { context, size in
                    let width = size.width
                    let height = size.height

                    // 绘制亮度波形
                    var path = Path()
                    path.move(to: CGPoint(x: 0, y: height))

                    for i in 0..<256 {
                        let x = (CGFloat(i) / 255) * width
                        let y = height * (1 - data.luminance[i])
                        path.addLine(to: CGPoint(x: x, y: y))
                    }

                    context.stroke(
                        path,
                        with: .color(.white),
                        lineWidth: 1.5
                    )
                }
                .padding(4)
            }
        }
        .frame(width: 200, height: 100)
    }
}

// MARK: - RGB Parade视图
struct RGBParadeView: View {
    let data: HistogramData

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景
                RoundedRectangle(cornerRadius: 8)
                    .fill(.black.opacity(0.7))

                // RGB分离波形
                HStack(spacing: 2) {
                    // Red通道
                    ChannelWaveform(values: data.red, color: .red)

                    // Green通道
                    ChannelWaveform(values: data.green, color: .green)

                    // Blue通道
                    ChannelWaveform(values: data.blue, color: .blue)
                }
                .padding(4)
            }
        }
        .frame(width: 200, height: 100)
    }
}

// MARK: - 单通道波形
struct ChannelWaveform: View {
    let values: [CGFloat]
    let color: Color

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                let width = size.width
                let height = size.height

                var path = Path()
                path.move(to: CGPoint(x: 0, y: height))

                for i in 0..<256 {
                    let x = (CGFloat(i) / 255) * width
                    let y = height * (1 - values[i])
                    path.addLine(to: CGPoint(x: x, y: y))
                }

                context.stroke(
                    path,
                    with: .color(color),
                    lineWidth: 1
                )
            }
        }
    }
}

// MARK: - 矢量示波器视图
struct VectorscopeView: View {
    let data: HistogramData

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景
                RoundedRectangle(cornerRadius: 8)
                    .fill(.black.opacity(0.7))

                // 圆形刻度
                Circle()
                    .stroke(.white.opacity(0.3), lineWidth: 1)
                    .padding(20)

                // 中心十字
                Path { path in
                    let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    path.move(to: CGPoint(x: center.x, y: 0))
                    path.addLine(to: CGPoint(x: center.x, y: geometry.size.height))
                    path.move(to: CGPoint(x: 0, y: center.y))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: center.y))
                }
                .stroke(.white.opacity(0.3), lineWidth: 1)

                // 色彩向量（简化版）
                Canvas { context, size in
                    let centerX = size.width / 2
                    let centerY = size.height / 2
                    let radius = min(size.width, size.height) / 2 - 20

                    // 绘制色彩点
                    for i in 0..<256 {
                        if data.luminance[i] > 0.1 {
                            let r = data.red[i]
                            let g = data.green[i]
                            let b = data.blue[i]

                            // 转换为极坐标
                            let angle = atan2(r - g, b - g)
                            let magnitude = sqrt(pow(r - g, 2) + pow(b - g, 2)) * radius

                            let x = centerX + cos(angle) * magnitude
                            let y = centerY + sin(angle) * magnitude

                            let point = CGPoint(x: x, y: y)
                            let rect = CGRect(x: point.x - 1, y: point.y - 1, width: 2, height: 2)

                            context.fill(
                                Path(ellipseIn: rect),
                                with: .color(Color(red: Double(r), green: Double(g), blue: Double(b)))
                            )
                        }
                    }
                }
                .padding(20)
            }
        }
        .frame(width: 150, height: 150)
    }
}

// MARK: - 假色图视图
struct FalseColorView: View {
    let data: HistogramData

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.black.opacity(0.7))

                VStack(alignment: .leading, spacing: 4) {
                    Text("假色图")
                        .font(.caption2)
                        .foregroundColor(.white)

                    // 色阶图例
                    HStack(spacing: 2) {
                        ColorBar(color: .purple, label: "< 0%")
                        ColorBar(color: .blue, label: "18%")
                        ColorBar(color: .cyan, label: "41%")
                        ColorBar(color: .green, label: "55%")
                        ColorBar(color: .yellow, label: "70%")
                        ColorBar(color: .red, label: "> 100%")
                    }
                    .font(.system(size: 8))
                }
                .padding(8)
            }
        }
        .frame(width: 200, height: 80)
    }
}

struct ColorBar: View {
    let color: Color
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Rectangle()
                .fill(color)
                .frame(height: 20)

            Text(label)
                .foregroundColor(.white.opacity(0.7))
        }
    }
}

// MARK: - 斑马纹叠加视图
struct ZebraPatternOverlay: View {
    let threshold: Float = 0.9 // 90%亮度阈值
    @State private var animate = false

    var body: some View {
        GeometryReader { geometry in
            // 斑马纹图案
            ZStack {
                ForEach(0..<20, id: \.self) { i in
                    Rectangle()
                        .fill(.white)
                        .frame(height: 4)
                        .offset(y: CGFloat(i * 20) + (animate ? 10 : 0))
                }
            }
            .mask(
                // 这里应该是基于像素亮度的蒙版
                // 实际实现需要从相机预览中提取像素数据
                Rectangle()
                    .fill(.clear)
            )
            .onAppear {
                withAnimation(.linear(duration: 0.5).repeatForever(autoreverses: false)) {
                    animate = true
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - 预览
struct HistogramView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            HistogramView(data: HistogramData())
            WaveformView(data: HistogramData())
            RGBParadeView(data: HistogramData())
            VectorscopeView(data: HistogramData())
            FalseColorView(data: HistogramData())
        }
        .padding()
        .background(Color.black)
    }
}
