import SwiftUI

struct NotificationsView: View {
    @ObservedObject var appState: AppStateManager
    var body: some View {
        NavigationStack {
            List {
                ForEach(appState.notifications) { n in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(n.message).fontWeight(n.isRead ? .regular : .bold)
                            Text(n.timestamp).font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        if !n.isRead { Circle().fill(Color.blue).frame(width: 8, height: 8) }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Notifications")
            .toolbar { ToolbarItem(placement: .topBarTrailing) {
                Button("Mark All Read") { Task { try? await APIService.shared.markAllNotificationsRead(); await appState.loadAllData() } }
            }}
        }
    }
}
