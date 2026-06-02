import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case today
    case history
    case recap

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today: "Today"
        case .history: "Log"
        case .recap: "Recap"
        }
    }

    var systemImageName: String {
        switch self {
        case .today: "checkmark.square"
        case .history: "calendar"
        case .recap: "chart.bar"
        }
    }
}

struct TabPillBar: View {
    @Binding var selectedTab: AppTab

    private let violet = Color(red: 0x7B / 255, green: 0x2F / 255, blue: 0xFF / 255)
    private let tabBarBg = Color(.systemGray5)
    private let inactiveText = Color(.secondaryLabel)

    var body: some View {
        HStack(spacing: 6) {
            ForEach(AppTab.allCases) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: tab.systemImageName)
                            .font(.system(size: 14, weight: .semibold))
                        Text(tab.title)
                            .font(.spaceGrotesk(.semibold, size: 14))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .foregroundStyle(tab == selectedTab ? violet : inactiveText)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(tab == selectedTab ? Color.white : Color.clear)
                    )
                    .shadow(
                        color: Color.black.opacity(tab == selectedTab ? 0.08 : 0),
                        radius: tab == selectedTab ? 8 : 0,
                        x: 0,
                        y: tab == selectedTab ? 2 : 0
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(tabBarBg)
        )
    }
}

#Preview {
    @Previewable @State var tab: AppTab = .today
    return VStack {
        TabPillBar(selectedTab: $tab)
            .padding()
        Spacer()
    }
}

