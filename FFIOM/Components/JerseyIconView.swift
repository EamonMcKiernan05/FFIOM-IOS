import SwiftUI

// MARK: - Jersey Icon View
// Loads kit images with remote URL support and disk caching.
// Tries remote URL first (via CachedAsyncImage), falls back to local PDF asset.
// Remote images are cached via URLSession.shared + URLCache (50MB memory, 100MB disk).

struct JerseyIconView: View {
    let kit: ClubKit
    let size: CGFloat
    let remoteURL: URL?
    
    init(teamId: Int? = nil, teamName: String? = nil, size: CGFloat = 40, remoteURL: URL? = nil) {
        self.size = size
        self.kit = ClubKit.forTeamId(teamId) ?? ClubKit.forTeamName(teamName ?? "") ?? .default
        self.remoteURL = remoteURL
    }
    
    init(kit: ClubKit, size: CGFloat = 40, remoteURL: URL? = nil) {
        self.kit = kit
        self.size = size
        self.remoteURL = remoteURL
    }
    
    var body: some View {
        ZStack {
            // Local asset fallback (always present as base layer)
            Image(kit.assetName)
                .resizable()
                .renderingMode(.original)
                .scaledToFit()
                .frame(width: size, height: size)
            
            // Remote image overlay (only shown if successfully loaded)
            if let url = remoteURL {
                CachedAsyncImage(url: url)
                    .frame(width: size, height: size)
                    .clipped()
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Convenience: JerseyIconView with auto-generated remote URL
extension JerseyIconView {
    /// Creates a JerseyIconView that attempts to load from the FFIOM web API.
    /// Falls back to local PDF asset if remote load fails or network is unavailable.
    static func forTeam(teamId: Int?, teamName: String? = nil, size: CGFloat = 40) -> JerseyIconView {
        let kitURL = APIConfig.baseURL
        let kit = ClubKit.forTeamId(teamId) ?? ClubKit.forTeamName(teamName ?? "") ?? .default
        let remoteURL = URL(string: "\(kitURL)/static/img/shirts/\(kit.assetName).svg")
        
        return JerseyIconView(kit: kit, size: size, remoteURL: remoteURL)
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            Text("Kit Preview")
                .font(.headline)
                .foregroundColor(.white)
            
            // Grid of all kits
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(ClubKit.all.values.sorted(by: { $0.name < $1.name }), id: \.id) { kit in
                    VStack(spacing: 4) {
                        JerseyIconView(teamId: kit.teamId, size: 50)
                        Text(kit.shortName)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .padding()
        }
        .background(Color.black)
    }
}
