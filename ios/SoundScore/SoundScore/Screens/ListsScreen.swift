import SwiftUI

struct ListsScreen: View {
    @StateObject private var viewModel = ListsViewModel()
    @State private var showCreateSheet = false
    @State private var draftTitle = ""
    var onSelectAlbum: (Album) -> Void = { _ in }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                SyncBanner(message: viewModel.syncMessage)

                if let error = viewModel.errorMessage {
                    ErrorBanner(message: error)
                }

                ScreenHeader(
                    title: "Lists",
                    subtitle: "Curated collections worth sharing.",
                    actionLabel: "Create",
                    onAction: { showCreateSheet = true }
                )

                if let featured = viewModel.showcases.first {
                    FeaturedListHero(showcase: featured, onSelectAlbum: onSelectAlbum)
                }

                if viewModel.showcases.count > 1 {
                    SectionHeader(eyebrow: "Your lists", title: "Collections")

                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 12) {
                            ForEach(Array(viewModel.showcases.dropFirst())) { showcase in
                                CompactListCard(showcase: showcase, onSelectAlbum: onSelectAlbum)
                            }
                        }
                        .padding(.trailing, 8)
                    }
                }

                if viewModel.showcases.isEmpty {
                    EmptyState(
                        title: "Build your first collection",
                        subtitle: "Arrange records into ranked moods, eras, or arguments worth sharing.",
                        icon: "text.badge.plus",
                        actionLabel: "Create a list",
                        onAction: { showCreateSheet = true }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 120)
        }
        .refreshable { await SoundScoreRepository.shared.refresh() }
        .sheet(isPresented: $showCreateSheet) {
            CreateListSheet(
                draftTitle: $draftTitle,
                onCreate: {
                    viewModel.createList(title: draftTitle)
                    draftTitle = ""
                    showCreateSheet = false
                }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
            .presentationBackground(SSColors.darkElevated)
        }
    }
}

private struct FeaturedListHero: View {
    let showcase: ListShowcase
    var onSelectAlbum: (Album) -> Void = { _ in }

    var body: some View {
        Button {
            if let firstAlbum = showcase.coverAlbums.first {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onSelectAlbum(firstAlbum)
            }
        } label: {
            ZStack(alignment: .bottomLeading) {
                if let cover = showcase.coverAlbums.first {
                    AlbumArtwork(artworkUrl: cover.artworkUrl, colors: cover.artColors, cornerRadius: 24)
                } else {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(SSColors.glassBg)
                }

                LinearGradient(
                    colors: [.clear, SSColors.overlayDark],
                    startPoint: .init(x: 0.5, y: 0.15),
                    endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: 24))

                VStack(alignment: .leading, spacing: 4) {
                    Text("FEATURED")
                        .font(SSTypography.labelSmall)
                        .foregroundColor(ThemeManager.shared.primary)
                        .fontWeight(.bold)
                    Text(showcase.list.title)
                        .font(SSTypography.headlineMedium)
                        .foregroundColor(SSColors.chromeLight)
                        .fontWeight(.bold)
                    Text("\(showcase.list.curatorHandle) · \(showcase.list.albumIds.count) albums · \(showcase.list.saves) saves")
                        .font(SSTypography.bodySmall)
                        .foregroundColor(SSColors.textSecondary)
                }
                .padding(16)
            }
            .frame(height: 180)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(SSColors.feedItemBorder, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct CompactListCard: View {
    let showcase: ListShowcase
    var onSelectAlbum: (Album) -> Void = { _ in }

    var body: some View {
        GlassCard(cornerRadius: 20, borderColor: SSColors.feedItemBorder, contentPadding: EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10), onTap: {
            if let firstAlbum = showcase.coverAlbums.first {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onSelectAlbum(firstAlbum)
            }
        }) {
            VStack(alignment: .leading, spacing: 10) {
                MosaicCover(albums: showcase.coverAlbums, cornerRadius: 14)
                Text(showcase.list.title)
                    .font(SSTypography.titleMedium)
                    .foregroundColor(SSColors.chromeLight)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                Text("\(showcase.list.albumIds.count) albums")
                    .font(SSTypography.bodySmall)
                    .foregroundColor(SSColors.textTertiary)
            }
        }
        .frame(width: 180)
    }
}

private struct CreateListSheet: View {
    @Binding var draftTitle: String
    let onCreate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Create a list")
                .font(SSTypography.headlineSmall)
                .foregroundColor(SSColors.chromeLight)

            PillSearchBar(query: $draftTitle, placeholder: "Albums I Would Defend...")

            SSButton(text: "Create", action: onCreate)
                .opacity(draftTitle.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1.0)
                .disabled(draftTitle.trimmingCharacters(in: .whitespaces).isEmpty)

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
    }
}
