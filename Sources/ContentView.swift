import SwiftUI
import Combine

struct ContentView: View {
    @ObservedObject var warpUsageService: WarpUsageService
    var onQuit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerView

            if let data = warpUsageService.usageData {
                statsView(for: data)
            } else if let error = warpUsageService.lastError {
                errorView(error)
            } else {
                loadingView
            }

            footerView
        }
        .padding(15)
        .frame(width: 320)
        .onAppear {
            warpUsageService.loadUsageData(force: true)
        }
    }

    private var headerView: some View {
        HStack {
            Text("Warp AI Usage")
                .font(.headline)
                .fontWeight(.bold)
            Spacer()
            if warpUsageService.isLoading {
                ProgressView()
                    .scaleEffect(0.7)
            }
        }
    }

    private func statsView(for data: WarpUsageData) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Plan:")
                Spacer()
                Text(data.subscriptionDisplayName)
                    .fontWeight(.semibold)
            }
            
            HStack {
                Text("Usage:")
                Spacer()
                Text(data.displayText)
                    .fontWeight(.semibold)
            }
            
            if !data.isUnlimited {
                ProgressView(value: data.usagePercentage)
                    .progressViewStyle(LinearProgressViewStyle())
                    .accentColor(colorForPercentage(data.usagePercentage))
            }
            
            Divider()
            
            HStack {
                Text("Resets on:")
                Spacer()
                Text(data.nextRefreshTime, formatter: dateFormatter)
                    .fontWeight(.semibold)
            }
        }
    }

    private func errorView(_ error: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text(error)
                .font(.callout)
                .foregroundColor(.secondary)
        }
    }

    private var loadingView: some View {
        HStack {
            ProgressView()
                .scaleEffect(0.7)
            Text("Loading...")
                .font(.callout)
                .foregroundColor(.secondary)
        }
    }

    private var footerView: some View {
        VStack(spacing: 10) {
            Divider()

            if let lastUpdateTime = warpUsageService.lastUpdateTime {
                Text("Last updated: \(lastUpdateTime, formatter: timeFormatter)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack {
                Button("Refresh") {
                    warpUsageService.loadUsageData(force: true)
                }
                
                Spacer()

                Button("Quit") {
                    self.onQuit()
                }
            }
        }
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