import SwiftUI

// MARK: - Jersey Icon View
// Loads actual kit PDF images from Assets.xcassets/Shirts/
// PDFs sourced from web UI: /static/img/shirts/*.svg

struct JerseyIconView: View {
    let kit: ClubKit
    let size: CGFloat
    
    init(teamId: Int? = nil, teamName: String? = nil, size: CGFloat = 40) {
        self.size = size
        self.kit = ClubKit.forTeamId(teamId) ?? ClubKit.forTeamName(teamName ?? "") ?? .default
    }
    
    var body: some View {
        Image(kit.assetName)
            .resizable()
            .renderingMode(.original)  // Preserve actual colors from the PDF
            .scaledToFit()
            .frame(width: size, height: size)
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
