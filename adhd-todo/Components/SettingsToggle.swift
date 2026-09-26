import SwiftUI

struct SettingsToggle: View {
    @Binding var isOn: Bool

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                isOn.toggle()
            }
        } label: {
            ZStack(alignment: isOn ? .trailing : .leading) {
                Capsule()
                    .fill(isOn ? AppTheme.violet : AppTheme.toggleOff)
                    .frame(width: 44, height: 26)

                Circle()
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.2), radius: 1.5, x: 0, y: 1)
                    .frame(width: 20, height: 20)
                    .padding(3)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isButton)
        .accessibilityValue(isOn ? "On" : "Off")
    }
}

#Preview {
    SettingsToggle(isOn: .constant(true))
}
