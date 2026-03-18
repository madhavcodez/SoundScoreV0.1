import SwiftUI

struct SettingsScreen: View {
    @StateObject private var viewModel = ProfileViewModel()
    @ObservedObject private var themeManager = ThemeManager.shared
    @EnvironmentObject private var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirm = false

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                themeSection
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
        .alert("Delete Account", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    try? await SoundScoreAPI().deleteAccount()
                    await MainActor.run { authManager.logout() }
                }
            }
        } message: {
            Text("This will permanently delete your account and all your data. This cannot be undone.")
        }
    }

    private var themeSection: some View {
        GlassCard(cornerRadius: 22, borderColor: SSColors.feedItemBorder, frosted: true) {
            VStack(alignment: .leading, spacing: 14) {
                Text("Accent Theme")
                    .font(SSTypography.headlineSmall)
                    .foregroundColor(SSColors.chromeLight)
                    .fontWeight(.bold)

                HStack(spacing: 12) {
                    ForEach(AccentTheme.allCases) { theme in
                        Button {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                themeManager.current = theme
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(theme.primary)
                                    .frame(width: 36, height: 36)

                                if themeManager.current == theme {
                                    Circle()
                                        .stroke(theme.primary, lineWidth: 2.5)
                                        .frame(width: 44, height: 44)
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(SSColors.darkBase)
                                }
                            }
                            .frame(width: 44, height: 44)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: .infinity)
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
        .onChange(of: viewModel.notificationPreferences.socialEnabled) { _, _ in viewModel.saveNotificationPreferences() }
        .onChange(of: viewModel.notificationPreferences.recapEnabled) { _, _ in viewModel.saveNotificationPreferences() }
        .onChange(of: viewModel.notificationPreferences.commentEnabled) { _, _ in viewModel.saveNotificationPreferences() }
        .onChange(of: viewModel.notificationPreferences.reactionEnabled) { _, _ in viewModel.saveNotificationPreferences() }
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
                        Stepper(
                            "\(viewModel.notificationPreferences.quietHoursStart):00",
                            value: $viewModel.notificationPreferences.quietHoursStart,
                            in: 0...23
                        )
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
                        Stepper(
                            "\(viewModel.notificationPreferences.quietHoursEnd):00",
                            value: $viewModel.notificationPreferences.quietHoursEnd,
                            in: 0...23
                        )
                        .font(SSTypography.titleLarge)
                        .foregroundColor(SSColors.chromeLight)
                        .fontWeight(.semibold)
                    }
                }
            }
        }
        .onChange(of: viewModel.notificationPreferences.quietHoursStart) { _, _ in viewModel.saveNotificationPreferences() }
        .onChange(of: viewModel.notificationPreferences.quietHoursEnd) { _, _ in viewModel.saveNotificationPreferences() }
    }

    private var dataSection: some View {
        GlassCard(cornerRadius: 22, borderColor: SSColors.feedItemBorder, frosted: true) {
            VStack(alignment: .leading, spacing: 14) {
                Text("Data")
                    .font(SSTypography.headlineSmall)
                    .foregroundColor(SSColors.chromeLight)
                    .fontWeight(.bold)

                SSGhostButton(text: "Export Data") {
                    Task {
                        SoundScoreRepository.shared.outboxStore.enqueue(OutboxOperation(
                            type: .exportData,
                            payload: [:]
                        ))
                        await SoundScoreRepository.shared.syncOutbox()
                    }
                    viewModel.showExportSuccess = true
                }

                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    showDeleteConfirm = true
                } label: {
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

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    authManager.logout()
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 14))
                        Text("Sign Out")
                    }
                    .font(SSTypography.labelLarge)
                    .foregroundColor(SSColors.accentCoral)
                    .padding(.top, 8)
                }
                .buttonStyle(.plain)
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
                .tint(ThemeManager.shared.primary)
                .labelsHidden()
        }
    }
}
