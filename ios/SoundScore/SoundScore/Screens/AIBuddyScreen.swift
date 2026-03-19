import SwiftUI

struct AIBuddyScreen: View {
    @StateObject private var viewModel = AIBuddyViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                CadenceCharacter(state: viewModel.cadenceState, size: 80)
                    .padding(.top, 24)
                Text("Cadence")
                    .font(SSTypography.headlineSmall)
                    .foregroundColor(SSColors.chromeLight)
                    .fontWeight(.bold)
                Text("Your AI music agent")
                    .font(SSTypography.bodySmall)
                    .foregroundColor(SSColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 12)

            // Confirmation toast
            if let confirmation = viewModel.actionConfirmation {
                confirmationBanner(confirmation)
            }

            // Inline search results from Cadence
            if !viewModel.searchResults.isEmpty {
                CadenceSearchResultsCard(
                    results: viewModel.searchResults,
                    onAdd: { viewModel.addSearchResultToLibrary($0) },
                    onDismiss: { viewModel.dismissSearchResults() }
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            chatArea

            // Suggestion chips above input
            if !viewModel.suggestions.isEmpty {
                suggestionChips.padding(.bottom, 4)
            }

            inputBar
        }
        .background(AppBackdrop())
    }

    // MARK: - Confirmation Banner

    private func confirmationBanner(_ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(SSColors.accentGreen)
            Text(text)
                .font(SSTypography.labelMedium)
                .foregroundColor(SSColors.chromeLight)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(SSColors.accentGreen.opacity(0.15))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(SSColors.accentGreen.opacity(0.3), lineWidth: 1))
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(.spring(response: 0.3), value: viewModel.actionConfirmation)
        .padding(.bottom, 4)
    }

    // MARK: - Suggestion Chips

    private var suggestionChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 10) {
                ForEach(Array(viewModel.suggestions.enumerated()), id: \.element.id) { index, chip in
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        viewModel.tapSuggestion(chip)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: chip.icon)
                                .font(.system(size: 13, weight: .medium))
                            Text(chip.label)
                                .font(SSTypography.bodySmall)
                                .lineLimit(1)
                        }
                        .foregroundColor(SSColors.chromeLight)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(SSColors.glassBg)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(
                                LinearGradient(
                                    colors: [ThemeManager.shared.primary.opacity(0.5), SSColors.glassBorder],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                ), lineWidth: 1
                            )
                        )
                    }
                    .animation(.easeOut(duration: 0.35).delay(Double(index) * 0.08), value: viewModel.suggestions.count)
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 44)
    }

    // MARK: - Chat Area

    private var chatArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 10) {
                    ForEach(viewModel.messages) { message in
                        messageView(message).id(message.id)
                    }
                    if viewModel.isThinking {
                        thinkingBubble.id("thinking")
                    }
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(SSTypography.bodySmall)
                            .foregroundColor(SSColors.accentCoral)
                            .padding(.horizontal, 16)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 16)
            }
            .onChange(of: viewModel.messages.count) {
                if let lastId = viewModel.messages.last?.id {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo(lastId, anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: - Message View (text + action cards)

    @ViewBuilder
    private func messageView(_ message: ChatMessage) -> some View {
        VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 8) {
            // Text bubble
            if !message.content.isEmpty {
                chatBubble(message)
            }

            // Render rich action cards
            if message.role == .assistant && !message.actions.isEmpty {
                let reviews = message.actions.filter { $0.type == .draftReview }
                let ratings = message.actions.filter { $0.type == .rateAlbum }

                // Review draft cards
                ForEach(reviews) { action in
                    let album = SoundScoreRepository.shared.albums.first { $0.id == action.albumId }
                    CadenceReviewCard(
                        albumId: action.albumId,
                        albumTitle: action.albumTitle,
                        artworkUrl: album?.artworkUrl,
                        artColors: album?.artColors ?? AlbumColors.forest,
                        reviewText: action.value,
                        rating: Float(SoundScoreRepository.shared.ratings[action.albumId] ?? 0),
                        onSend: { text, rating in
                            viewModel.executeReview(
                                albumId: action.albumId,
                                albumTitle: action.albumTitle,
                                reviewText: text,
                                rating: rating
                            )
                        },
                        onDiscard: { viewModel.discardAction(messageId: message.id, actionId: action.id) }
                    )
                }

                // Batch ratings (3+ albums) or individual quick-rate cards
                if ratings.count >= 3 {
                    CadenceBatchRatingCard(
                        ratings: ratings,
                        onApplyAll: { viewModel.executeBatchRatings($0) },
                        onDiscard: {
                            for r in ratings {
                                viewModel.discardAction(messageId: message.id, actionId: r.id)
                            }
                        }
                    )
                } else {
                    ForEach(ratings) { action in
                        CadenceQuickRateCard(
                            action: action,
                            onConfirm: { viewModel.executeRating($0) },
                            onDiscard: { viewModel.discardAction(messageId: message.id, actionId: action.id) }
                        )
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)
    }

    // MARK: - Chat Bubbles

    @ViewBuilder
    private func chatBubble(_ message: ChatMessage) -> some View {
        if message.role == .assistant {
            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 1)
                    .fill(ThemeManager.shared.primary)
                    .frame(width: 2)
                    .padding(.vertical, 6)
                Text(message.content)
                    .font(SSTypography.bodyMedium)
                    .foregroundColor(SSColors.chromeLight)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
            }
            .background(
                RoundedRectangle(cornerRadius: 18).fill(.ultraThinMaterial)
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(SSColors.glassBorder, lineWidth: 0.5))
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))
        } else {
            Text(message.content)
                .font(SSTypography.bodyMedium)
                .foregroundColor(SSColors.chromeLight)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(LinearGradient(
                            colors: [ThemeManager.shared.primary.opacity(0.3), ThemeManager.shared.primary.opacity(0.15)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                )
        }
    }

    private var thinkingBubble: some View {
        HStack {
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(SSColors.chromeMedium)
                        .frame(width: 8, height: 8)
                        .opacity(0.6)
                        .animation(.easeInOut(duration: 0.6).repeatForever().delay(Double(i) * 0.2), value: viewModel.isThinking)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18).fill(.ultraThinMaterial)
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(SSColors.glassBorder, lineWidth: 0.5))
            )
            Spacer(minLength: 60)
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Ask about music...", text: $viewModel.inputText)
                .font(SSTypography.bodyMedium)
                .foregroundColor(SSColors.chromeLight)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(SSColors.glassBg)
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(SSColors.glassBorder, lineWidth: 0.5))
                .onSubmit { viewModel.sendMessage() }

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                viewModel.sendMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(
                        viewModel.inputText.trimmingCharacters(in: .whitespaces).isEmpty
                            ? SSColors.chromeFaint : ThemeManager.shared.primary
                    )
            }
            .disabled(viewModel.inputText.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isThinking)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .padding(.bottom, 90)
        .background(SSColors.darkElevated.opacity(0.9).ignoresSafeArea(edges: .bottom))
    }
}
