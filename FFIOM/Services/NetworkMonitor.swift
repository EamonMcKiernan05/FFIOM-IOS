import Foundation
import Network

/// Monitors network path status using NWPathMonitor (Network framework).
/// Provides reactive connectivity state for graceful offline handling.
@MainActor
class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()

    @Published var isConnected = true
    @Published var interfaceType: NWPath.InterfaceType?

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor", qos: .utility)

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.isConnected = path.status == .satisfied
                self.interfaceType = path.interfaceType
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
