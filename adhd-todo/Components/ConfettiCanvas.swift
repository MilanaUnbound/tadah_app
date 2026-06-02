import SwiftUI

struct ConfettiCanvas: View {
    let onFinished: (() -> Void)?

    private struct Particle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var vx: CGFloat
        var vy: CGFloat
        var angle: CGFloat
        var rotationSpeed: CGFloat
        var size: CGFloat
        var isRect: Bool
        var opacity: CGFloat
        var frame: Int
        var color: Color
    }

    @State private var particles: [Particle] = []
    @State private var isRunning = true

    private let particleCount = 180
    private let palette: [Color] = [
        Color(red: 0x7B / 255, green: 0x2F / 255, blue: 0xFF / 255), // violet
        Color(red: 0xE0 / 255, green: 0x40 / 255, blue: 0xFB / 255), // fuchsia
        Color(red: 0xFF / 255, green: 0x33 / 255, blue: 0x99 / 255), // pink
        Color(red: 0xFF / 255, green: 0xCC / 255, blue: 0x00 / 255), // yellow
        Color(red: 0xFF / 255, green: 0x6B / 255, blue: 0x00 / 255), // orange
        Color(red: 0x00 / 255, green: 0xC8 / 255, blue: 0x75 / 255), // green
        Color(red: 0x11 / 255, green: 0x11 / 255, blue: 0x11 / 255), // near-black
        Color(red: 0xCC / 255, green: 0x00 / 255, blue: 0xFF / 255), // purple
    ]

    var body: some View {
        TimelineView(.animation) { _ in
            Canvas { context, size in
                if particles.isEmpty {
                    DispatchQueue.main.async {
                        seedParticlesIfNeeded(in: size)
                    }
                } else if isRunning {
                    DispatchQueue.main.async {
                        tickIfRunning()
                    }
                }

                for p in particles {
                    context.opacity = p.opacity

                    let rect = CGRect(
                        x: p.x,
                        y: p.y,
                        width: p.size,
                        height: p.isRect ? (p.size * 0.7) : p.size
                    )

                    if p.isRect {
                        var path = Path(rect)
                        let t = CGAffineTransform(translationX: rect.midX, y: rect.midY)
                            .rotated(by: p.angle)
                            .translatedBy(x: -rect.midX, y: -rect.midY)
                        path = path.applying(t)
                        context.fill(path, with: .color(p.color))
                    } else {
                        context.fill(Path(ellipseIn: rect), with: .color(p.color))
                    }
                }
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .zIndex(999)
            .onChange(of: isRunning) { _, newValue in
                if newValue == false {
                    particles.removeAll()
                    onFinished?()
                }
            }
        }
    }

    private func seedParticlesIfNeeded(in size: CGSize) {
        guard particles.isEmpty else { return }
        particles = (0..<particleCount).map { _ in
            Particle(
                x: .random(in: 0...max(1, size.width)),
                y: .random(in: -170 ... -30),
                vx: .random(in: -2.2 ... 2.2),
                vy: .random(in: 0.2 ... 2.0),
                angle: .random(in: 0...(2 * .pi)),
                rotationSpeed: .random(in: -0.12 ... 0.12),
                size: .random(in: 5 ... 10),
                isRect: .random(in: 0...1) < 0.6,
                opacity: 1,
                frame: 0,
                color: palette.randomElement() ?? .white
            )
        }
        isRunning = true
    }

    private func tickIfRunning() {
        guard isRunning, particles.isEmpty == false else { return }

        var anyAlive = false
        for idx in particles.indices {
            particles[idx].frame += 1
            particles[idx].vy += 0.1
            particles[idx].vx *= 0.993
            particles[idx].x += particles[idx].vx
            particles[idx].y += particles[idx].vy
            particles[idx].angle += particles[idx].rotationSpeed

            if particles[idx].frame > 100 {
                particles[idx].opacity = max(0, particles[idx].opacity - 0.016)
            }

            if particles[idx].opacity > 0 {
                anyAlive = true
            }
        }

        if anyAlive == false {
            isRunning = false
        }
    }
}

#Preview {
    ConfettiCanvas(onFinished: nil)
        .frame(width: 390, height: 844)
}

