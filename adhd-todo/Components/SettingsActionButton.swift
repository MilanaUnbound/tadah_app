import SwiftUI

struct SettingsActionButton: View {
    enum Style {
        case save
        case load
        case delete

        var title: String {
            switch self {
            case .save: "Save"
            case .load: "Load"
            case .delete: "Delete"
            }
        }

        func background(theme: AppTheme) -> Color {
            switch self {
            case .save: AppTheme.exportBlue
            case .load: AppTheme.importGreen
            case .delete: theme.btnBg
            }
        }

        func foreground(theme: AppTheme) -> Color {
            switch self {
            case .save, .load: .white
            case .delete: AppTheme.deleteRed
            }
        }
    }

    @Environment(\.appTheme) private var theme

    let style: Style
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(style.title)
                .font(.spaceGrotesk(.semibold, size: 13))
                .foregroundStyle(style.foreground(theme: theme))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    style.background(theme: theme),
                    in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HStack {
        SettingsActionButton(style: .save) {}
        SettingsActionButton(style: .load) {}
        SettingsActionButton(style: .delete) {}
    }
    .withAppTheme()
}
