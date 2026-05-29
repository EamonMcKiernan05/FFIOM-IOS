import SwiftUI

struct LoadingView: View {
    let message: String
    init(message: String = "Loading...") { self.message = message }
    var body: some View {
        VStack(spacing: 12) { ProgressView(); Text(message).font(.caption).foregroundColor(.secondary) }
        .frame(maxWidth: .infinity).padding(40)
    }
}
