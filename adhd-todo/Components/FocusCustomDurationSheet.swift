import SwiftUI

struct FocusCustomDurationSheet: View {
    @Environment(\.appTheme) private var theme

    @Binding var minutes: Int
    let accentColor: Color
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture(perform: onCancel)

            VStack(spacing: 0) {
                Capsule()
                    .fill(theme.border)
                    .frame(width: 36, height: 4)
                    .padding(.top, 12)
                    .padding(.bottom, 4)

                HStack {
                    Text("Custom duration")
                        .font(.spaceGrotesk(.bold, size: 18))
                        .foregroundStyle(theme.text)

                    Spacer()

                    Button(action: onCancel) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(theme.textSub)
                            .frame(width: 30, height: 30)
                            .background(theme.btnBg, in: Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 8)

                HStack(alignment: .center, spacing: 8) {
                    Picker("Minutes", selection: $minutes) {
                        ForEach(1...180, id: \.self) { value in
                            Text("\(value)").tag(value)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 180)

                    Text("min")
                        .font(.spaceGrotesk(.medium, size: 18))
                        .foregroundStyle(theme.textSub)
                }
                .padding(.horizontal, 20)

                Button(action: onConfirm) {
                    Text("Set \(minutes) min")
                        .font(.spaceGrotesk(.semibold, size: 15))
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(accentColor, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
            .frame(maxWidth: 390)
            .frame(maxWidth: .infinity)
            .background(theme.sheet)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 24,
                    topTrailingRadius: 24
                )
            )
        }
    }
}

#Preview {
    @Previewable @State var minutes = 30

    FocusCustomDurationSheet(
        minutes: $minutes,
        accentColor: AppTheme.violet,
        onConfirm: {},
        onCancel: {}
    )
    .withAppTheme()
}
