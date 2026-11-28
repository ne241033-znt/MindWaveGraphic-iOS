// PureLogoSplashView.swift
// Authentication
//
// アプリ起動直後に表示されるロゴ画面。
// 約1.5秒後に自動的にAccountGuidanceViewへ遷移する。

import SwiftUI

struct PureLogoSplashView: View {
    var flowState: AppFlowState

    @State private var pulse: Bool = false
    @State private var logoGlow: Bool = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // 宇宙星空背景
            LaunchStarfieldBG()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // アプリ名ロゴ（グラデーション＋ネオングロー）
                VStack(spacing: 10) {
                    ZStack {
                        Text("MINDWAVEGRAPHIC")
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .tracking(1.2)
                            .foregroundStyle(.cyan)
                            .blur(radius: logoGlow ? 18 : 8)
                            .opacity(0.8)

                        Text("MINDWAVEGRAPHIC")
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .tracking(1.2)
                            .minimumScaleFactor(0.65)
                            .lineLimit(1)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        .white,
                                        Color(red: 0.66, green: 0.96, blue: 1.0),
                                        Color(red: 0.71, green: 0.64, blue: 1.0),
                                        Color(red: 0.94, green: 0.85, blue: 1.0)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: .cyan.opacity(0.8), radius: 10)
                    }
                    .padding(.horizontal, 16)

                    Text("YOUR MIND, YOUR UNIVERSE")
                        .font(.system(size: 9, weight: .medium))
                        .tracking(4)
                        .foregroundStyle(.white.opacity(0.65))
                }

                Spacer()

                // 下部ローディングドット
                HStack(spacing: 6) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(AuthDesign.accent.opacity(pulse ? 0.85 : 0.25))
                            .frame(width: 5, height: 5)
                            .animation(
                                .easeInOut(duration: 0.6)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(i) * 0.2),
                                value: pulse
                            )
                    }
                }
                .padding(.bottom, 56)
            }
        }
        .onAppear {
            pulse = true
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                logoGlow = true
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                flowState.authStatus = .accountGuidance
                print("[Navigation] logoSplash -> accountGuidance")
            }
        }
    }
}

#Preview {
    PureLogoSplashView(flowState: AppFlowState())
}
