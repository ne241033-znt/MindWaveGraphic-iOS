// CockpitSpaceSceneView.swift
// MindWaveGraphic

import SwiftUI
import UIKit

// MARK: - 新コックピット＆宇宙シーン統合ビュー
struct CockpitSpaceSceneView: View {
    /// アプリ側のリアルタイム緊張・ストレススコア (0〜100)
    let score: Double

    /// 揺れを発動させる閾値（スコア70以上で振動）
    private var shouldShake: Bool {
        score >= 70
    }

    private var redOverlayOpacity: Double {
        if score <= 60 {
            return 0
        } else {
            return min((score - 60) / 40 * 0.25, 0.25)
        }
    }

    private var backgroundColor: Color {
        if score <= 30 {
            return Color.blue.opacity(0.35)
        } else if score <= 60 {
            return Color.black
        } else {
            return Color(red: 0.25, green: 0.0, blue: 0.0)
        }
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !shouldShake)) { timeline in
            let shakeX: CGFloat = shouldShake
                ? CGFloat(sin(timeline.date.timeIntervalSinceReferenceDate * 35) * 7)
                : 0
            let shakeY: CGFloat = shouldShake
                ? CGFloat(cos(timeline.date.timeIntervalSinceReferenceDate * 28) * 3)
                : 0

            GeometryReader { geometry in
                ZStack {
                    // 1. 背景
                    backgroundColor
                        .ignoresSafeArea()
                        .animation(.easeInOut(duration: 1.0), value: score)

                    // 2. 星空・隕石（白背景を透過して合成）
                    CustomStarfieldView(score: score)

                    // 3. 雷（スコア70以上）
                    CustomLightningView(score: score)

                    // 4. コックピット枠（周囲フレームとして控えめに配置）
                    if UIImage(named: "cockpit") != nil {
                        Image("cockpit")
                            .resizable()
                            .scaledToFill()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .opacity(0.28)
                            .mask(
                                RadialGradient(
                                    gradient: Gradient(stops: [
                                        .init(color: .clear, location: 0.35),
                                        .init(color: .black, location: 0.88)
                                    ]),
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: max(geometry.size.width, geometry.size.height) * 0.72
                                )
                            )
                            .ignoresSafeArea()
                            .allowsHitTesting(false)
                    }

                    // 5. スコア60超の赤オーバーレイ演出
                    Color.red
                        .opacity(redOverlayOpacity)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                        .animation(.easeInOut(duration: 1.0), value: score)
                }
                .offset(x: shakeX, y: shakeY)
            }
        }
    }
}

// MARK: - 3D星空・隕石
struct CustomStarfieldView: View {
    let score: Double

    private var intensity: Double { score / 100.0 }
    private var speed: Double { 0.2 + intensity * 2.5 }

    private var bigStarCount: Int {
        if score < 33 {
            return 0
        } else if score < 70 {
            return 14
        } else {
            return 26
        }
    }

    /// 白背景をピクセル単位で透明化した隕石 UIImage を生成
    private static let transparentMeteorUIImage: UIImage? = {
        guard let src = UIImage(named: "inseki")?.cgImage else { return nil }
        let width = src.width
        let height = src.height
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var rawData = [UInt8](repeating: 0, count: width * height * 4)

        guard let ctx = CGContext(
            data: &rawData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        ctx.draw(src, in: CGRect(x: 0, y: 0, width: width, height: height))

        // 白に近いピクセル（R, G, B すべて 225 以上）を透明化
        for i in stride(from: 0, to: rawData.count, by: 4) {
            let r = rawData[i]
            let g = rawData[i + 1]
            let b = rawData[i + 2]
            if r > 225 && g > 225 && b > 225 {
                rawData[i] = 0
                rawData[i + 1] = 0
                rawData[i + 2] = 0
                rawData[i + 3] = 0
            }
        }

        guard let outCG = ctx.makeImage() else { return nil }
        return UIImage(cgImage: outCG)
    }()

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let inseki: GraphicsContext.ResolvedImage? = {
                    if let uiImg = Self.transparentMeteorUIImage {
                        return context.resolve(Image(uiImage: uiImg))
                    } else if UIImage(named: "inseki") != nil {
                        return context.resolve(Image("inseki"))
                    }
                    return nil
                }()

                let time = timeline.date.timeIntervalSinceReferenceDate
                let centerX = size.width / 2
                let centerY = size.height / 2

                // 通常の星
                for i in 0..<800 {
                    let seed = Double(i)
                    let x3d = CGFloat(sin(seed * 12.9898) * 300)
                    let y3d = CGFloat(cos(seed * 78.233) * 300)

                    var z = 1000 - (time * 200 * speed + seed * 17).truncatingRemainder(dividingBy: 1000)
                    if z < 1 { z = 1 }

                    let perspective = CGFloat(400 / z)
                    let x = centerX + x3d * perspective
                    let y = centerY + y3d * perspective
                    let starSize = min(max(1, perspective * 4), 4)

                    let rect = CGRect(x: x, y: y, width: starSize, height: starSize)
                    context.fill(Path(ellipseIn: rect), with: .color(.white))

                    // 星の軌跡
                    if intensity > 0.3 {
                        let trail = starSize * CGFloat(intensity) * 10
                        var path = Path()
                        path.move(to: CGPoint(x: x, y: y))
                        path.addLine(
                            to: CGPoint(
                                x: centerX + x3d * CGFloat(400 / (z + Double(trail))),
                                y: centerY + y3d * CGFloat(400 / (z + Double(trail)))
                            )
                        )
                        context.stroke(
                            path,
                            with: .color(.white.opacity(0.8)),
                            lineWidth: starSize * 0.5
                        )
                    }
                }

                // 隕石（白背景を除去済みの inseki 画像）
                for i in 0..<bigStarCount {
                    let seed = Double(i * 137 + 1000)
                    let x3d = CGFloat(sin(seed * 15.23) * 350)
                    let y3d = CGFloat(cos(seed * 92.11) * 350)

                    var z = 1200 - (time * (250 + intensity * 400) + seed * 50).truncatingRemainder(dividingBy: 1200)
                    if z < 1 { z = 1 }

                    let perspective = CGFloat(500 / z)
                    let x = centerX + x3d * perspective
                    let y = centerY + y3d * perspective
                    let meteorSize = min(max(10, perspective * 65), 76)
                    let correctedAngle = Double.pi / 6

                    if let inseki {
                        context.drawLayer { layer in
                            layer.translateBy(x: x + meteorSize / 2, y: y + meteorSize / 2)
                            if x > centerX {
                                layer.scaleBy(x: -1, y: 1)
                            }
                            layer.rotate(by: .radians(correctedAngle))
                            layer.draw(
                                inseki,
                                in: CGRect(
                                    x: -meteorSize / 2,
                                    y: -meteorSize / 2,
                                    width: meteorSize,
                                    height: meteorSize
                                )
                            )
                        }
                    }
                }
            }
        }
    }
}

// MARK: - 雷エフェクト（スコア70以上）
struct CustomLightningView: View {
    let score: Double

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                guard score >= 70 else { return }

                let time = timeline.date.timeIntervalSinceReferenceDate

                let count: Int
                let interval: Double
                let duration: Double
                let lineWidth: CGFloat

                if score < 80 {
                    count = 32
                    interval = 1.2
                    duration = 0.28
                    lineWidth = 1.5
                } else if score < 90 {
                    count = 24
                    interval = 1.0
                    duration = 0.30
                    lineWidth = 2.5
                } else {
                    count = 20
                    interval = 0.75
                    duration = 0.35
                    lineWidth = 4.0
                }

                let lightningColor: Color
                if score < 80 {
                    lightningColor = .cyan
                } else if score < 90 {
                    lightningColor = .purple
                } else {
                    lightningColor = .white
                }

                for i in 0..<count {
                    let seed = Double(i)
                    let phase = (time + seed * 0.173).truncatingRemainder(dividingBy: interval)
                    guard phase < duration else { continue }

                    let flash = sin(Double.pi * phase / duration)
                    let opacity = 0.35 + flash * 0.65

                    let positionType = i % 3
                    let startX: CGFloat
                    if positionType == 0 {
                        startX = size.width * 0.03
                    } else if positionType == 1 {
                        startX = size.width * 0.97
                    } else {
                        startX = size.width * 0.5
                    }

                    let startY = CGFloat((seed * 83.7).truncatingRemainder(dividingBy: 100)) / 100 * size.height

                    let length: CGFloat
                    if score < 80 {
                        length = size.height * 0.15
                    } else if score < 90 {
                        length = size.height * 0.30
                    } else {
                        length = size.height * 0.48
                    }
                    let endY = min(startY + length, size.height)

                    let direction: CGFloat
                    if positionType == 0 {
                        direction = 1
                    } else if positionType == 1 {
                        direction = -1
                    } else {
                        direction = i % 2 == 0 ? 1 : -1
                    }

                    let endX = startX + direction * (
                        positionType == 2 ? size.width * 0.12 : size.width * 0.18
                    )

                    let currentWidth: CGFloat = positionType == 2 ? lineWidth * 1.3 : lineWidth
                    let isStraight = i % 4 == 0

                    var path = Path()
                    path.move(to: CGPoint(x: startX, y: startY))

                    if isStraight {
                        path.addLine(to: CGPoint(x: endX, y: endY))
                    } else {
                        let p1 = CGPoint(x: startX + direction * 15, y: startY + length * 0.25)
                        let p2 = CGPoint(x: startX - direction * 5,  y: startY + length * 0.50)
                        let p3 = CGPoint(x: startX + direction * 25, y: startY + length * 0.75)
                        let p4 = CGPoint(x: endX, y: endY)

                        path.addLine(to: p1)
                        path.addLine(to: p2)
                        path.addLine(to: p3)
                        path.addLine(to: p4)

                        if score >= 80 {
                            var branch = Path()
                            branch.move(to: p2)
                            branch.addLine(
                                to: CGPoint(
                                    x: p2.x + direction * 35,
                                    y: p2.y + length * 0.12
                                )
                            )
                            context.stroke(
                                branch,
                                with: .color(lightningColor.opacity(opacity * 0.8)),
                                lineWidth: currentWidth * 0.7
                            )
                        }
                    }

                    context.stroke(
                        path,
                        with: .color(lightningColor.opacity(opacity * 0.25)),
                        lineWidth: currentWidth * 5
                    )
                    context.stroke(
                        path,
                        with: .color(lightningColor.opacity(opacity)),
                        lineWidth: currentWidth
                    )
                }

                // 90以上の画面フラッシュ
                if score >= 90 {
                    let flashPhase = time.truncatingRemainder(dividingBy: 0.9)
                    if flashPhase < 0.12 {
                        let flashOpacity = (1 - flashPhase / 0.12) * 0.16
                        context.fill(
                            Path(CGRect(origin: .zero, size: size)),
                            with: .color(.white.opacity(flashOpacity))
                        )
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}
