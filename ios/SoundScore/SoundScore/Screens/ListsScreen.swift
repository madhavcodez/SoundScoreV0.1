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
