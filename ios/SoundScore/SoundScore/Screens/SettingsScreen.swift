import SwiftUI

struct SettingsScreen: View {
    @StateObject private var viewModel = ProfileViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                accountSection
                notificationsSection
                quietHoursSection
                dataSection
                aboutSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 120)
        }
        .background(AppBackdrop())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 36, height: 36)
                        Circle()
                            .stroke(SSColors.glassBorder, lineWidth: 0.5)
                            .frame(width: 36, height: 36)
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(SSColors.chromeLight)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var accountSection: some View {
        GlassCard(cornerRadius: 22, borderColor: SSColors.feedItemBorder, frosted: true) {
            VStack(alignment: .leading, spacing: 14) {
                Text("Account")
                    .font(SSTypography.headlineSmall)
                    .foregroundColor(SSColors.chromeLight)
                    .fontWeight(.bold)

                SettingsRow(label: "Handle", value: viewModel.profile?.handle ?? "@unknown")
                SettingsRow(label: "Bio", value: viewModel.profile?.bio ?? "")
            }
        }
    }

    private var notificationsSection: some View {
        GlassCard(cornerRadius: 22, borderColor: SSColors.feedItemBorder, frosted: true) {
            VStack(alignment: .leading, spacing: 14) {
                Text("Notifications")
                    .font(SSTypography.headlineSmall)
                    .foregroundColor(SSColors.chromeLight)
                    .fontWeight(.bold)

                ToggleRow(label: "Social activity", isOn: $viewModel.notificationPreferences.socialEnabled)
                ToggleRow(label: "Weekly recap", isOn: $viewModel.notificationPreferences.recapEnabled)
                ToggleRow(label: "Comments", isOn: $viewModel.notificationPreferences.commentEnabled)
                ToggleRow(label: "Reactions", isOn: $viewModel.notificationPreferences.reactionEnabled)
            }
        }
    }

    private var quietHoursSection: some View {
        GlassCard(cornerRadius: 22, borderColor: SSColors.feedItemBorder, frosted: true) {
            VStack(alignment: .leading, spacing: 14) {
                Text("Quiet Hours")
                    .font(SSTypography.headlineSmall)
                    .foregroundColor(SSColors.chromeLight)
                    .fontWeight(.bold)

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Start")
                            .font(SSTypography.bodySmall)
                            .foregroundColor(SSColors.textTertiary)
                        Text("\(viewModel.notificationPreferences.quietHoursStart):00")
                            .font(SSTypography.titleLarge)
                            .foregroundColor(SSColors.chromeLight)
                            .fontWeight(.semibold)
                    }
                    Spacer()
                    Image(systemName: "moon.fill")
                        .foregroundColor(SSColors.accentViolet)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("End")
                            .font(SSTypography.bodySmall)
                            .foregroundColor(SSColors.textTertiary)
                        Text("\(viewModel.notificationPreferences.quietHoursEnd):00")
                            .font(SSTypography.titleLarge)
                            .foregroundColor(SSColors.chromeLight)
                            .fontWeight(.semibold)
                    }
                }
            }
        }
    }

    private var dataSection: some View {
        GlassCard(cornerRadius: 22, borderColor: SSColors.feedItemBorder, frosted: true) {
            VStack(alignment: .leading, spacing: 14) {
                Text("Data")
                    .font(SSTypography.headlineSmall)
                    .foregroundColor(SSColors.chromeLight)
                    .fontWeight(.bold)

                SSGhostButton(text: "Export Data") {}

                Button(action: {}) {
                    Text("Delete Account")
                        .font(SSTypography.labelLarge)
                        .foregroundColor(SSColors.accentCoral)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(SSColors.accentCoral.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(SSColors.accentCoral.opacity(0.3), lineWidth: 0.5)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var aboutSection: some View {
        GlassCard(cornerRadius: 22, borderColor: SSColors.feedItemBorder, frosted: true) {
            VStack(alignment: .leading, spacing: 8) {
                Text("About")
                    .font(SSTypography.headlineSmall)
                    .foregroundColor(SSColors.chromeLight)
                    .fontWeight(.bold)

                HStack {
                    Text("SoundScore")
                        .font(SSTypography.bodyMedium)
                        .foregroundColor(SSColors.textSecondary)
                    Spacer()
                    Text("Version 0.1.0")
                        .font(SSTypography.labelMedium)
                        .foregroundColor(SSColors.textTertiary)
                }
            }
        }
    }
}

private struct SettingsRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(SSTypography.bodySmall)
                .foregroundColor(SSColors.textTertiary)
            Text(value)
                .font(SSTypography.bodyMedium)
                .foregroundColor(SSColors.chromeLight)
        }
    }
}

private struct ToggleRow: View {
    let label: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Text(label)
                .font(SSTypography.bodyMedium)
                .foregroundColor(SSColors.chromeLight)
            Spacer()
            Toggle("", isOn: $isOn)
                .tint(SSColors.accentGreen)
                .labelsHidden()
        }
    }
}
