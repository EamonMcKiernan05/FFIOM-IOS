import SwiftUI

/// Banner shown when network connectivity is lost.
/// Integrates with NetworkMonitor to display/hide automatically.
struct OfflineBanner: View {
    @ObservedObject var networkMonitor = NetworkMonitor.shared

    var body: some View {
        if !networkMonitor.isConnected {
            HStack(spacing: 8) {
                Image(systemName: "wifi.slash")
                    .foregroundColor(.white)
                    .accessibilityLabel("No connection")
                Text("You are offline. Some features may be unavailable.")
                    .foregroundColor(.white)
                    .font(.caption)
                    .accessibilityLabel("Offline message")
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.orange.opacity(0.9))
            .cornerRadius(8)
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .transition(.move(edge: .top).combined(with: .opacity))
            .animation(.easeInOut(duration: 0.3), value: networkMonitor.isConnected)
        }
    }
}
