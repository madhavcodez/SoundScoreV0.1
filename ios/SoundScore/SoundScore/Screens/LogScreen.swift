import SwiftUI

struct LogScreen: View {
    @StateObject private var viewModel = LogViewModel()

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    SyncBanner(message: viewModel.syncMessage)

                    ScreenHeader(title: "Diary", subtitle: "Your listening journal. Rate, log, repeat.")

                    GlassCard(cornerRadius: 22, borderColor: SSColors.feedItemBorder, frosted: true) {
                        HStack {
                            ForEach(Array(viewModel.summaryStats.enumerated()), id: \.offset) { _, stat in
                                VStack(spacing: 2) {
                                    Text(stat.value)
                                        .font(SSTypography.headlineMedium)
                                        .foregroundColor(stat.label == "This week" ? SSColors.accentGreen : SSColors.chromeLight)
                                        .fontWeight(.black)
                                    Text(stat.label.uppercased())
                                        .font(SSTypography.labelSmall)
                                        .foregroundColor(SSColors.textTertiary)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }

                    SectionHeader(eyebrow: "Quick rate", title: "Tap to rate")

                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 12) {
                            ForEach(viewModel.quickLogAlbums) { album in
                                QuickRateCard(
                                    album: album,
                                    rating: viewModel.ratings[album.id] ?? 0,
                                    onRate: { viewModel.updateRating(albumId: album.id, rating: $0) }
                                )
                            }
                        }
                        .padding(.trailing, 8)
                    }

                    if !viewModel.recentLogs.isEmpty {
                        SectionHeader(eyebrow: "Recent", title: "Your diary entries")

                        ForEach(viewModel.recentLogs) { entry in
                            TimelineEntry(dateLabel: entry.dateLabel, timeLabel: entry.timeLabel) {
                                DiaryEntryCard(entry: entry)
                            }
                        }
                    }

                    GlassCard(cornerRadius: 20, borderColor: SSColors.feedItemBorder) {
                        VStack(spacing: 4) {
                            Text("Write Later")
                                .font(SSTypography.titleMedium)
                                .foregroundColor(SSColors.chromeLight)
                            Text("Queue albums for later review — coming soon")
                                .font(SSTypography.bodySmall)
                                .foregroundColor(SSColors.textTertiary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 120)
            }

            Button(action: {}) {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(SSColors.darkBase)
                    .frame(width: 56, height: 56)
                    .background(SSColors.accentGreen)
                    .clipShape(Circle())
                    .shadow(color: SSColors.accentGreen.opacity(0.3), radius: 10, y: 4)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 100)
        }
    }
}

private struct QuickRateCard: View {
    let album: Album
    let rating: Float
    let onRate: (Float) -> Void

    var body: some View {
        GlassCard(cornerRadius: 20, borderColor: SSColors.feedItemBorder, contentPadding: EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    AlbumArtwork(artworkUrl: album.artworkUrl, colors: album.artColors, cornerRadius: 14)
                        .frame(width: 124, height: 130)
                    if rating > 0 {
                        Text(String(format: "%.1f", rating))
                            .font(SSTypography.labelSmall)
                            .fontWeight(.bold)
                            .foregroundColor(SSColors.accentAmber)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(SSColors.darkBase.opacity(0.7))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding(6)
                    }
                }
                Text(album.title)
                    .font(SSTypography.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(SSColors.chromeLight)
                    .lineLimit(1)
                Text(album.artist)
                    .font(SSTypography.bodySmall)
                    .foregroundColor(SSColors.textSecondary)
                    .lineLimit(1)
                StarRating(rating: rating, onRate: onRate, starSize: 14)
            }
        }
        .frame(width: 140)
    }
}

private struct DiaryEntryCard: View {
    let entry: RecentLogEntry

    var body: some View {
        GlassCard(cornerRadius: 18, borderColor: SSColors.feedItemBorder, contentPadding: EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)) {
            HStack(spacing: 10) {
                AlbumArtwork(artworkUrl: entry.album.artworkUrl, colors: entry.album.artColors, cornerRadius: 14)
                    .frame(width: 56, height: 56)
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.album.title)
                        .font(SSTypography.titleMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(SSColors.chromeLight)
                    Text(entry.album.artist)
                        .font(SSTypography.bodySmall)
                        .foregroundColor(SSColors.textSecondary)
                    if !entry.caption.isEmpty {
                        Text(entry.caption)
                            .font(SSTypography.bodySmall)
                            .foregroundColor(SSColors.textTertiary)
                            .lineLimit(1)
                    }
                }
                Spacer()
                StarRating(rating: entry.rating, starSize: 12)
            }
        }
    }
}
