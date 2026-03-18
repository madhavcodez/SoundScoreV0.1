import SwiftUI

struct SettingsScreen: View {
    @StateObject private var viewModel = ProfileViewModel()
    @ObservedObject private var themeManager = ThemeManager.shared
    @EnvironmentObject private var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirm = false
    @State private var previewTheme: AccentTheme = ThemeManager.shared.current

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
        VStack(alignment: .leading, spacing: 12) {
            Text("Theme")
                .font(SSTypography.headlineSmall)
                .foregroundColor(SSColors.chromeLight)
                .fontWeight(.bold)
                .padding(.horizontal, 4)

            TabView(selection: $previewTheme) {
                ForEach(AccentTheme.allCases) { theme in
                    ThemePreviewCard(
                        theme: theme,
                        isActive: themeManager.current == theme
                    )
                    .tag(theme)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 180)
            .onChange(of: previewTheme) { _, newTheme in
                withAnimation(.easeInOut(duration: 0.35)) {
                    themeManager.current = newTheme
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            .onAppear { previewTheme = themeManager.current }

            HStack(spacing: 8) {
                ForEach(AccentTheme.allCases) { theme in
                    Circle()
                        .fill(theme == previewTheme ? theme.primary : Color.white.opacity(0.25))
                        .frame(width: 6, height: 6)
                }
            }
            .frame(maxWidth: .infinity)
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

private struct ThemePreviewCard: View {
    let theme: AccentTheme
    let isActive: Bool

    var body: some View {
        ZStack {
            // Background gradient preview
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    LinearGradient(
                        colors: [theme.colors.darkElevated, theme.colors.darkBase],
                        startPoint: .top, endPoint: .bottom
                    )
                )

            // Glow
            RadialGradient(
                colors: [theme.backdropGlow, Color.clear],
                center: .topLeading,
                startRadius: 0, endRadius: 200
            )
            .clipShape(RoundedRectangle(cornerRadius: 22))

            // Content preview
            VStack(spacing: 16) {
                Text(theme.label)
                    .font(SSTypography.headlineMedium)
                    .foregroundColor(.white.opacity(0.94))
                    .fontWeight(.bold)

                // Mini UI preview
                HStack(spacing: 10) {
                    // Mock album card
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [theme.primary.opacity(0.6), theme.secondary.opacity(0.4)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)

                    VStack(alignment: .leading, spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.7))
                            .frame(width: 90, height: 10)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.35))
                            .frame(width: 60, height: 8)
                        HStack(spacing: 3) {
                            ForEach(0..<5, id: \.self) { i in
                                Image(systemName: i < 4 ? "star.fill" : "star")
                                    .font(.system(size: 8))
                                    .foregroundColor(SSColors.accentAmber)
                            }
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.14), lineWidth: 0.5)
                        )
                )
                .padding(.horizontal, 20)

                // Mock tab bar dots
                HStack(spacing: 20) {
                    ForEach(0..<5, id: \.self) { i in
                        Circle()
                            .fill(i == 0 ? theme.primary : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(isActive ? theme.primary : Color.white.opacity(0.12), lineWidth: isActive ? 2 : 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .padding(.horizontal, 8)
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
