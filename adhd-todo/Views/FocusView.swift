import SwiftUI

enum FocusTimerMode: String, CaseIterable, Identifiable {
    case focus
    case breakTime = "break"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .focus: "Focus"
        case .breakTime: "Break"
        }
    }

    var presets: [Int] {
        switch self {
        case .focus: [25, 50]
        case .breakTime: [5, 10, 15]
        }
    }

    var defaultPreset: Int {
        presets[0]
    }
}

struct FocusView: View {
    private static let breakGreen = Color(red: 0x22 / 255, green: 0xC5 / 255, blue: 0x5E / 255)
    private static let compactHeightThreshold: CGFloat = 640

    @Environment(\.screenContentWidth) private var screenContentWidth
    @Environment(\.appTheme) private var theme

    @State private var mode: FocusTimerMode = .focus
    @State private var durationMinutes = 25
    @State private var remainingSeconds = 25 * 60
    @State private var isRunning = false
    @State private var showsCustomPicker = false
    @State private var customPickerMinutes = 25
    @State private var showsConfetti = false

    private var totalSeconds: Int { durationMinutes * 60 }
    private var atFull: Bool { remainingSeconds == totalSeconds }
    private var isFinished: Bool { remainingSeconds == 0 }
    private var isCustomDuration: Bool { mode.presets.contains(durationMinutes) == false }

    private var accentColor: Color {
        mode == .focus ? AppTheme.violet : Self.breakGreen
    }

    private var timeLabel: String {
        let mins = remainingSeconds / 60
        let secs = remainingSeconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    private var subtitleLabel: String {
        if isFinished { return "Done" }
        return mode.label.lowercased()
    }

    var body: some View {
        GeometryReader { geo in
            let isCompact = geo.size.height < Self.compactHeightThreshold
            let sectionSpacing: CGFloat = isCompact ? 20 : 32
            let ringSize: CGFloat = isCompact ? 200 : 240
            let timeFontSize: CGFloat = isCompact ? 44 : 52
            let titleSize = min(
                isCompact ? 26 : 30,
                ScreenLayout.headingFontSize(for: screenContentWidth)
            )

            VStack(spacing: sectionSpacing) {
                Text("Focus")
                    .font(.spaceGrotesk(.bold, size: titleSize))
                    .foregroundStyle(theme.text)
                    .frame(maxWidth: .infinity, alignment: .leading)

                FocusModeToggle(mode: $mode, onModeChange: switchMode)

                ZStack {
                    FocusTimerRing(
                        progress: totalSeconds > 0 ? CGFloat(remainingSeconds) / CGFloat(totalSeconds) : 0,
                        accentColor: accentColor,
                        trackColor: theme.progressBg,
                        timeLabel: timeLabel,
                        subtitleLabel: subtitleLabel,
                        timeColor: isFinished ? accentColor : theme.text,
                        subtitleColor: theme.textMuted,
                        ringSize: ringSize,
                        timeFontSize: timeFontSize
                    )

                    if showsConfetti {
                        ConfettiCanvas(onFinished: {
                            showsConfetti = false
                        })
                        .frame(width: ringSize, height: ringSize)
                        .clipped()
                        .allowsHitTesting(false)
                    }
                }

                FocusPresetChips(
                    mode: mode,
                    durationMinutes: durationMinutes,
                    atFull: atFull,
                    isCustomDuration: isCustomDuration,
                    accentColor: accentColor,
                    onSelectPreset: pickPreset,
                    onCustom: openCustomPicker
                )

                controlsRow
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .tabContentVerticalPadding()
        }
        .task(id: isRunning) {
            await runTimer()
        }
        .overlay {
            if showsCustomPicker {
                FocusCustomDurationSheet(
                    minutes: $customPickerMinutes,
                    accentColor: accentColor,
                    onConfirm: confirmCustomDuration,
                    onCancel: { showsCustomPicker = false }
                )
            }
        }
    }

    @ViewBuilder
    private var controlsRow: some View {
        HStack(spacing: 10) {
            Button {
                if isFinished {
                    resetTimer()
                } else {
                    isRunning.toggle()
                }
            } label: {
                Text(isFinished ? "Restart" : isRunning ? "Pause" : "Start")
                    .font(.spaceGrotesk(.bold, size: 16))
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(accentColor, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)

            if atFull == false && isFinished == false {
                Button {
                    resetTimer()
                } label: {
                    Text("Reset")
                        .font(.spaceGrotesk(.medium, size: 15))
                        .foregroundStyle(theme.textSub)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(theme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: theme.cardShadowColor, radius: 4, x: 0, y: 1)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func switchMode(_ newMode: FocusTimerMode) {
        mode = newMode
        isRunning = false
        let preset = newMode.defaultPreset
        durationMinutes = preset
        remainingSeconds = preset * 60
        showsConfetti = false
    }

    private func pickPreset(_ minutes: Int) {
        durationMinutes = minutes
        remainingSeconds = minutes * 60
        isRunning = false
        showsConfetti = false
    }

    private func openCustomPicker() {
        customPickerMinutes = isCustomDuration ? durationMinutes : 30
        showsCustomPicker = true
    }

    private func confirmCustomDuration() {
        durationMinutes = customPickerMinutes
        remainingSeconds = customPickerMinutes * 60
        isRunning = false
        showsConfetti = false
        showsCustomPicker = false
    }

    private func resetTimer() {
        remainingSeconds = durationMinutes * 60
        isRunning = false
        showsConfetti = false
    }

    @MainActor
    private func runTimer() async {
        guard isRunning else { return }

        while isRunning && remainingSeconds > 0 {
            try? await _Concurrency.Task.sleep(for: .seconds(1))
            guard isRunning else { return }

            if remainingSeconds <= 1 {
                remainingSeconds = 0
                isRunning = false
                showsConfetti = true
            } else {
                remainingSeconds -= 1
            }
        }
    }
}

private struct FocusModeToggle: View {
    @Environment(\.appTheme) private var theme

    @Binding var mode: FocusTimerMode
    let onModeChange: (FocusTimerMode) -> Void

    var body: some View {
        HStack(spacing: 0) {
            ForEach(FocusTimerMode.allCases) { item in
                let isActive = item == mode

                Button {
                    guard isActive == false else { return }
                    withAnimation(.easeOut(duration: 0.15)) {
                        onModeChange(item)
                    }
                } label: {
                    Text(item.label)
                        .font(.spaceGrotesk(.semibold, size: 14))
                        .foregroundStyle(isActive ? theme.text : theme.textSub)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(isActive ? theme.card : Color.clear)
                        )
                        .shadow(
                            color: isActive ? theme.cardShadowColor : .clear,
                            radius: 3,
                            x: 0,
                            y: 1
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(theme.tabBg, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct FocusTimerRing: View {
    let progress: CGFloat
    let accentColor: Color
    let trackColor: Color
    let timeLabel: String
    let subtitleLabel: String
    let timeColor: Color
    let subtitleColor: Color
    let ringSize: CGFloat
    let timeFontSize: CGFloat

    private let lineWidth: CGFloat = 10

    var body: some View {
        ZStack {
            Circle()
                .stroke(trackColor, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: max(0, min(1, progress)))
                .stroke(
                    accentColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 6) {
                Text(timeLabel)
                    .font(.spaceGrotesk(.bold, size: timeFontSize))
                    .foregroundStyle(timeColor)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(subtitleLabel)
                    .font(.spaceGrotesk(.medium, size: 13))
                    .foregroundStyle(subtitleColor)
                    .textCase(.lowercase)
            }
        }
        .frame(width: ringSize, height: ringSize)
    }
}

private struct FocusPresetChips: View {
    @Environment(\.appTheme) private var theme

    let mode: FocusTimerMode
    let durationMinutes: Int
    let atFull: Bool
    let isCustomDuration: Bool
    let accentColor: Color
    let onSelectPreset: (Int) -> Void
    let onCustom: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            ForEach(mode.presets, id: \.self) { minutes in
                presetChip(
                    title: "\(minutes) min",
                    isActive: durationMinutes == minutes && atFull && isCustomDuration == false
                ) {
                    onSelectPreset(minutes)
                }
            }

            presetChip(
                title: isCustomDuration && atFull ? "\(durationMinutes) min" : "Custom",
                isActive: isCustomDuration && atFull
            ) {
                onCustom()
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func presetChip(title: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.spaceGrotesk(.medium, size: 14))
                .foregroundStyle(isActive ? Color.white : theme.textSub)
                .padding(.horizontal, 20)
                .padding(.vertical, 7)
                .background(
                    isActive ? accentColor : theme.card,
                    in: Capsule()
                )
                .shadow(color: isActive ? .clear : theme.cardShadowColor, radius: 4, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    FocusView()
        .withAppTheme()
}
