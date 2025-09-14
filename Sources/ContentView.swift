import SwiftUI

struct ContentView: View {
    @StateObject private var warpUsageService = WarpUsageService()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "terminal.fill")
                    .foregroundColor(.blue)
                    .font(.largeTitle)
                
                VStack(alignment: .leading) {
                    Text("Warp Status")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Monitor your Warp AI usage")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Divider()
            
            if let data = warpUsageService.usageData {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Current Usage:")
                            .fontWeight(.medium)
                        Spacer()
                        Text(data.displayText)
                            .fontWeight(.semibold)
                            .foregroundColor(data.isUnlimited ? .green : 
                                           data.usagePercentage < 0.7 ? .green :
                                           data.usagePercentage < 0.9 ? .orange : .red)
                    }
                    
                    HStack {
                        Text("Plan:")
                            .fontWeight(.medium)
                        Spacer()
                        Text(data.subscriptionDisplayName)
                            .fontWeight(.semibold)
                    }
                    
                    if !data.isUnlimited {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Progress:")
                                    .fontWeight(.medium)
                                Spacer()
                                Text("\(Int(data.usagePercentage * 100))%")
                                    .fontWeight(.semibold)
                            }
                            
                            ProgressView(value: data.usagePercentage)
                                .progressViewStyle(LinearProgressViewStyle())
                                .accentColor(data.usagePercentage < 0.7 ? .green :
                                           data.usagePercentage < 0.9 ? .orange : .red)
                        }
                    }
                    
                    HStack {
                        Text("Resets:")
                            .fontWeight(.medium)
                        Spacer()
                        Text(data.nextRefreshTime, style: .date)
                            .fontWeight(.semibold)
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                
            } else if warpUsageService.isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading usage data...")
                        .foregroundColor(.secondary)
                }
                .padding()
                
            } else if let error = warpUsageService.lastError {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                        Text("Error")
                            .fontWeight(.medium)
                    }
                    Text(error)
                        .foregroundColor(.secondary)
                        .font(.caption)
                    
                    Button("Retry") {
                        warpUsageService.loadUsageData()
                    }
                    .buttonStyle(BorderedProminentButtonStyle())
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("About")
                    .font(.headline)
                
                Text("This app monitors your Warp terminal AI usage by reading from Warp's preferences. The status is displayed in your menu bar and updates automatically every 5 minutes.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button("Refresh Now") {
                    warpUsageService.loadUsageData()
                }
                .buttonStyle(BorderedButtonStyle())
            }
            
            Spacer()
        }
        .padding(20)
        .frame(width: 400, height: 350)
        .onAppear {
            warpUsageService.loadUsageData()
        }
    }
}