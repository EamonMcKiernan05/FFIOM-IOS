import SwiftUI

/// Image cache configuration utility.
enum ImageCache {
    /// Configure shared URLCache with disk + memory caching.
    /// Call once during app launch.
    static func configure() {
        URLSession.shared.configuration.urlCache = URLCache(
            memoryCapacity: 50 * 1024 * 1024,   // 50 MB memory
            diskCapacity: 100 * 1024 * 1024      // 100 MB disk
        )
    }
}

/// Cached async image loader using URLSession with disk + memory caching.
/// Automatically caches responses to avoid re-downloading on reload.
/// Uses URLSession.shared with .reloadIgnoringLocalCacheData for first load,
/// then relies on URLCache for subsequent loads.
struct CachedAsyncImage: View {
    let url: URL?
    @State private var image: UIImage?
    @State private var isLoading = false
    @State private var loadAttempted = false

    init(url: URL?) {
        self.url = url
    }

    var body: some View {
        Group {
            if let img = image {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
            } else if isLoading {
                ProgressView()
                    .scaleEffect(0.7)
            } else {
                // Empty - fallback layer (local asset) will show underneath
                Color.clear
            }
        }
        .onAppear {
            guard let url = url, !loadAttempted else { return }
            loadImage(from: url)
        }
    }

    private func loadImage(from url: URL) {
        loadAttempted = true
        isLoading = true

        // Check cache first
        if let cachedData = URLCache.shared.cachedResponse(for: URLRequest(url: url))?.data,
           let cachedImage = UIImage(data: cachedData) {
            self.image = cachedImage
            self.isLoading = false
            return
        }

        // Create request with caching policy
        var request = URLRequest(url: url)
        request.cachePolicy = .returnCacheDataElseLoad
        request.setValue("image/svg+xml,image/png,image/jpeg,*/*", forHTTPHeaderField: "Accept")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data, let uiImage = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.image = uiImage
                    self.isLoading = false
                }
            } else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    // Silently fall back to local asset (shown in ZStack underneath)
                }
            }
        }.resume()
    }
}
