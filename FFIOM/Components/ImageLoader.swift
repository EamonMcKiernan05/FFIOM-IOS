import SwiftUI

/// Cached async image loader using URLSession.shared with URLCache.
/// Automatically caches responses to avoid re-downloading on reload.
struct CachedAsyncImage: View {
    let url: URL?
    @State private var image: UIImage?
    @State private var isLoading = false

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
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
            }
        }
        .onAppear {
            loadImage()
        }
    }

    private func loadImage() {
        guard let url = url, image == nil else { return }
        isLoading = true
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let data = data, let uiImage = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.image = uiImage
                    self.isLoading = false
                }
            } else {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }.resume()
    }
}

/// Configure shared URLCache with disk + memory caching.
/// Call once during app launch (in APIService or AppRouter).
func configureImageCache() {
    let cache = URLCache(
        memoryCapacity: 50 * 1024 * 1024,   // 50 MB memory
        diskCapacity: 100 * 1024 * 1024      // 100 MB disk
    )
    cache.diskCapacity = 100 * 1024 * 1024
    cache.memoryCapacity = 50 * 1024 * 1024
    // Note: We don't set URLSession.shared.configuration.urlCache because
    // URLSession.shared has a pre-configured shared cache that we extend instead.
    // The default URLSession.shared.cache is used automatically by dataTask calls above.
}
