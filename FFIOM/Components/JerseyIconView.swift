import SwiftUI

// MARK: - Jersey Icon View (SVG-style football shirt)
// Renders a football shirt silhouette with club kit colors and pattern

struct JerseyIconView: View {
    let kit: ClubKit
    let size: CGFloat
    
    init(teamId: Int? = nil, teamName: String? = nil, size: CGFloat = 40) {
        self.size = size
        self.kit = ClubKit.forTeamId(teamId) ?? ClubKit.forTeamName(teamName ?? "") ?? .default
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Jersey body
                jerseyShape(in: geo).fill(kit.primaryColor)
                
                // Pattern overlay
                if kit.pattern == .stripes {
                    stripesOverlay(in: geo)
                } else if kit.pattern == .halves {
                    halvesOverlay(in: geo)
                } else if kit.pattern == .sash {
                    sashOverlay(in: geo)
                }
                
                // V-neck collar
                Path { path in
                    let w = geo.size.width
                    let h = geo.size.height
                    path.move(to: CGPoint(x: w * 0.3, y: h * 0.02))
                    path.addQuadCurve(
                        to: CGPoint(x: w * 0.7, y: h * 0.02),
                        control: CGPoint(x: w * 0.5, y: h * 0.18)
                    )
                }
                .stroke(kit.secondaryColor, lineWidth: max(1, size / 20))
            }
        }
        .frame(width: size, height: size)
    }
    
    // MARK: - Jersey Shape
    
    private func jerseyShape(in geo: GeometryProxy) -> Path {
        let w = geo.size.width
        let h = geo.size.height
        return Path { path in
            path.move(to: CGPoint(x: w * 0.3, y: h * 0.02))
            // Left shoulder
            path.addLine(to: CGPoint(x: w * 0.18, y: h * 0.12))
            // Left sleeve
            path.addLine(to: CGPoint(x: w * 0.05, y: h * 0.42))
            path.addLine(to: CGPoint(x: w * 0.2, y: h * 0.38))
            // Left side
            path.addLine(to: CGPoint(x: w * 0.2, y: h * 0.72))
            // Bottom center
            path.addLine(to: CGPoint(x: w * 0.5, y: h * 0.82))
            // Right side
            path.addLine(to: CGPoint(x: w * 0.8, y: h * 0.72))
            path.addLine(to: CGPoint(x: w * 0.8, y: h * 0.38))
            // Right sleeve
            path.addLine(to: CGPoint(x: w * 0.95, y: h * 0.42))
            path.addLine(to: CGPoint(x: w * 0.82, y: h * 0.12))
            // Right shoulder
            path.addLine(to: CGPoint(x: w * 0.7, y: h * 0.02))
            // V-neck
            path.addLine(to: CGPoint(x: w * 0.5, y: h * 0.12))
            path.closeSubpath()
        }
    }
    
    // MARK: - Pattern Overlays
    
    @ViewBuilder
    private func stripesOverlay(in geo: GeometryProxy) -> some View {
        let w = geo.size.width
        ZStack {
            ForEach([0.33, 0.50, 0.67], id: \.self) { fraction in
                Rectangle()
                    .fill(kit.secondaryColor.opacity(0.45))
                    .frame(width: w * 0.07)
                    .offset(x: w * fraction - w * 0.035)
            }
        }
        .mask(jerseyShape(in: geo))
    }
    
    @ViewBuilder
    private func halvesOverlay(in geo: GeometryProxy) -> some View {
        let w = geo.size.width
        let h = geo.size.height
        Rectangle()
            .fill(kit.secondaryColor.opacity(0.5))
            .frame(width: w * 0.5, height: h)
            .offset(x: w * 0.5)
            .mask(jerseyShape(in: geo))
    }
    
    @ViewBuilder
    private func sashOverlay(in geo: GeometryProxy) -> some View {
        let w = geo.size.width
        let h = geo.size.height
        Path { path in
            path.move(to: CGPoint(x: 0, y: h * 0.35))
            path.addLine(to: CGPoint(x: w, y: h * 0.5))
            path.addLine(to: CGPoint(x: w, y: h * 0.65))
            path.addLine(to: CGPoint(x: 0, y: h * 0.45))
            path.closeSubpath()
        }
        .fill(kit.secondaryColor.opacity(0.45))
        .mask(jerseyShape(in: geo))
    }
}

#Preview {
    VStack(spacing: 20) {
        ForEach([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13], id: \.self) { id in
            HStack {
                if let kit = ClubKit.forTeamId(id) {
                    JerseyIconView(teamId: id, size: 50)
                        .frame(width: 60, height: 60)
                    Text(kit.name)
                        .font(.caption)
                }
                Spacer()
            }
        }
    }
    .padding()
}
