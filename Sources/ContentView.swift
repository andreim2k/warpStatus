import SwiftUI
import Combine

struct ContentView: View {
    @ObservedObject var warpUsageService: WarpUsageService
    var onQuit: () -> Void
    @State private var backgroundAnimation = false
    @State private var particleAnimation = false

    var body: some View {
        VStack(spacing: 0) {
            // Header with animated gradient
            headerSection
            
            // Main content with glass cards
            contentSection
            
            // Action buttons
            actionSection
        }
        .padding(24)
        .frame(width: 360, height: 420)
        .background(
            ZStack {
                // Animated background gradient
                backgroundGradient
                
                // Floating particles
                particleOverlay
                
                // Glass overlay
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.3), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
            }
        )
        .onAppear {
            backgroundAnimation = true
            particleAnimation = true
            warpUsageService.loadUsageData(force: true)
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.cyan.opacity(0.6), .blue.opacity(0.4)],
                                center: .center,
                                startRadius: 5,
                                endRadius: 20
                            )
                        )
                        .frame(width: 32, height: 32)
                        .scaleEffect(backgroundAnimation ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 2).repeatForever(), value: backgroundAnimation)
                    
                    Image(systemName: "terminal.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Warp AI Usage")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    Text("Real-time • Live Updates")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if warpUsageService.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.cyan)
                }
            }
            
            Divider()
                .background(.white.opacity(0.2))
        }
    }

    private var contentSection: some View {
        VStack(spacing: 16) {
            if let data = warpUsageService.usageData {
                LiquidGlassPlanCard(data: data)
                LiquidGlassUsageCard(data: data)
                if !data.isUnlimited {
                    LiquidGlassProgressCard(data: data)
                }
                LiquidGlassResetCard(data: data)
            } else if let error = warpUsageService.lastError {
                LiquidGlassErrorCard(error: error)
            } else {
                LiquidGlassLoadingCard()
            }
        }
    }
    
    private var actionSection: some View {
        VStack(spacing: 16) {
            Divider()
                .background(.white.opacity(0.2))
            
            HStack(spacing: 12) {
                Button("Refresh") {
                    warpUsageService.loadUsageData(force: true)
                }
                .buttonStyle(LiquidGlassButtonStyle(color: .cyan))
                
                Spacer()
                
                Button("Quit") {
                    onQuit()
                }
                .buttonStyle(LiquidGlassButtonStyle(color: .red))
            }
            
            if let lastUpdateTime = warpUsageService.lastUpdateTime {
                Text("Last updated: \(lastUpdateTime, formatter: timeFormatter)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color.cyan.opacity(0.1),
                Color.blue.opacity(0.08),
                Color.purple.opacity(0.05),
                Color.cyan.opacity(0.1)
            ],
            startPoint: backgroundAnimation ? .topLeading : .bottomTrailing,
            endPoint: backgroundAnimation ? .bottomTrailing : .topLeading
        )
        .animation(.easeInOut(duration: 8).repeatForever(autoreverses: true), value: backgroundAnimation)
    }
    
    private var particleOverlay: some View {
        ZStack {
            ForEach(0..<6, id: \.self) { i in
                Circle()
                    .fill(.white.opacity(0.03))
                    .frame(width: CGFloat.random(in: 3...6))
                    .position(
                        x: CGFloat.random(in: 0...360),
                        y: CGFloat.random(in: 0...420)
                    )
                    .animation(
                        .linear(duration: Double.random(in: 4...8))
                        .repeatForever(autoreverses: true),
                        value: particleAnimation
                    )
            }
        }
        .allowsHitTesting(false)
    }

    private func colorForPercentage(_ percentage: Double) -> Color {
        if percentage > 0.9 {
            return .red
        } else if percentage > 0.7 {
            return .orange
        } else {
            return .green
        }
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        return formatter
    }
}

// MARK: - Liquid Glass Components

struct LiquidGlassPlanCard: View {
    let data: WarpUsageData
    @State private var isAnimating = false
    
    var body: some View {
        HStack {
            Image(systemName: "crown.fill")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.yellow)
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 2).repeatForever(), value: isAnimating)
            
            Text("Plan:")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(data.subscriptionDisplayName)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
        }
        .padding(16)
        .background(liquidGlassBackground(color: .yellow))
        .onAppear { isAnimating = true }
    }
}

struct LiquidGlassUsageCard: View {
    let data: WarpUsageData
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.cyan)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 2).repeatForever(), value: isAnimating)
                
                Text("Token Usage")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                
                Spacer()
            }
            
            VStack(spacing: 8) {
                HStack {
                    Text("Total Used:")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(data.displayText)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.cyan)
                        .contentTransition(.numericText())
                }
                
                HStack {
                    Text("Remaining:")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(data.freeTokensText)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(data.isUnlimited ? .green : colorForPercentage(data.usagePercentage))
                        .contentTransition(.numericText())
                }
            }
        }
        .padding(16)
        .background(liquidGlassBackground(color: .cyan))
        .onAppear { isAnimating = true }
    }
    
    private func colorForPercentage(_ percentage: Double) -> Color {
        if percentage > 0.9 { return .red }
        else if percentage > 0.7 { return .orange }
        else { return .green }
    }
}

struct LiquidGlassProgressCard: View {
    let data: WarpUsageData
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Usage Progress")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                Spacer()
                Text("\(Int(data.usagePercentage * 100))%")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(colorForPercentage(data.usagePercentage))
            }
            
            ProgressView(value: data.usagePercentage)
                .progressViewStyle(LinearProgressViewStyle())
                .tint(colorForPercentage(data.usagePercentage))
                .scaleEffect(y: 1.2)
        }
        .padding(16)
        .background(liquidGlassBackground(color: colorForPercentage(data.usagePercentage)))
    }
    
    private func colorForPercentage(_ percentage: Double) -> Color {
        if percentage > 0.9 { return .red }
        else if percentage > 0.7 { return .orange }
        else { return .green }
    }
}

struct LiquidGlassResetCard: View {
    let data: WarpUsageData
    @State private var isAnimating = false
    
    var body: some View {
        HStack {
            Image(systemName: "arrow.clockwise.circle.fill")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.purple)
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 2).repeatForever(), value: isAnimating)
            
            Text("Resets on:")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(data.nextRefreshTime, formatter: dateFormatter)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.purple)
        }
        .padding(16)
        .background(liquidGlassBackground(color: .purple))
        .onAppear { isAnimating = true }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
}

struct LiquidGlassErrorCard: View {
    let error: String
    @State private var isAnimating = false
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.orange)
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
            
            Text(error)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
        }
        .padding(16)
        .background(liquidGlassBackground(color: .orange))
        .onAppear { isAnimating = true }
    }
}

struct LiquidGlassLoadingCard: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack {
            ProgressView()
                .scaleEffect(0.8)
                .tint(.cyan)
            
            Text("Loading AI usage data...")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.primary)
        }
        .padding(16)
        .background(liquidGlassBackground(color: .cyan))
    }
}

struct LiquidGlassButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.8), color.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Capsule()
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: color.opacity(0.3), radius: 6, x: 0, y: 3)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

func liquidGlassBackground(color: Color) -> some View {
    RoundedRectangle(cornerRadius: 16)
        .fill(.ultraThinMaterial.opacity(0.6))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [color.opacity(0.3), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: color.opacity(0.2), radius: 8, x: 0, y: 4)
}
