import SwiftUI
import Combine

struct SuggestionChip: Identifiable {
    let id = UUID()
    let label: String
    let prompt: String
    let icon: String
}

@MainActor
class AIBuddyViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isThinking: Bool = false
    @Published var cadenceState: CadenceState = .idle
    @Published var errorMessage: String?
    @Published var suggestions: [SuggestionChip] = []
    @Published var actionConfirmation: String?

    init() {
        messages.append(ChatMessage(
            role: .assistant,
            content: "Hey! I'm Cadence, your music agent. I can rate albums, draft reviews in your voice, and help you discover music. Try asking me to review something or rate a few albums at once."
        ))
        loadInitialSuggestions()
    }

    // MARK: - Suggestions

    private func loadInitialSuggestions() {
        let repo = SoundScoreRepository.shared
        let topRated = repo.ratings.sorted { $0.value > $1.value }
        let topAlbum = topRated.first.flatMap { entry in repo.albums.first { $0.id == entry.key } }
        let unrated = repo.albums.filter { repo.ratings[$0.id] == nil }

        let topName = topAlbum?.title ?? "CHROMAKOPIA"
        let topArtist = topAlbum?.artist ?? "Tyler, the Creator"
        let unratedNames = unrated.prefix(3).map(\.title).joined(separator: ", ")

        suggestions = [
            SuggestionChip(label: "Draft a review for \(topName)", prompt: "Write a review for \(topName) in my voice and let me edit it", icon: "square.and.pencil"),
            SuggestionChip(label: "Rate my unrated albums", prompt: "Rate these for me: \(unratedNames)", icon: "star"),
            SuggestionChip(label: "What should I listen to next?", prompt: "Based on my taste, what should I listen to next?", icon: "headphones"),
            SuggestionChip(label: "Roast my taste", prompt: "Roast my music taste based on my ratings. Be brutally honest but funny.", icon: "flame"),
            SuggestionChip(label: "Deep cuts from \(topArtist)", prompt: "What are some deep cuts from \(topArtist)?", icon: "waveform"),
        ]
    }

    func tapSuggestion(_ chip: SuggestionChip) {
        inputText = chip.prompt
        sendMessage()
        suggestions = []
    }

    // MARK: - Send Message

    func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        guard !Secrets.geminiAPIKey.isEmpty else {
            errorMessage = "Gemini API key not configured."
            return
        }

        messages.append(ChatMessage(role: .user, content: text))
        inputText = ""
        isThinking = true
        cadenceState = .thinking
        errorMessage = nil

        Task {
            do {
                let result = try await AIBuddyService.shared.sendMessage(
                    messages: messages.filter { $0.role != .system },
                    userContext: buildUserContext(),
                    albumCatalog: buildAlbumCatalog()
                )
                let msg = ChatMessage(role: .assistant, content: result.text, actions: result.actions)
                self.messages.append(msg)
                self.isThinking = false
                self.cadenceState = .happy
                self.generateFollowUpSuggestions(hadActions: !result.actions.isEmpty)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    if self.cadenceState == .happy { self.cadenceState = .idle }
                }
            } catch {
                self.errorMessage = error.localizedDescription
                self.isThinking = false
                self.cadenceState = .idle
            }
        }
    }

    // MARK: - Execute Actions

    func executeRating(_ action: CadenceAction) {
        guard let rating = Float(action.value) else { return }
        SoundScoreRepository.shared.updateRating(albumId: action.albumId, rating: rating)
        showConfirmation("Rated \(action.albumTitle) → \(action.value)/6")
    }

    func executeBatchRatings(_ actions: [CadenceAction]) {
        for action in actions {
            if let rating = Float(action.value) {
                SoundScoreRepository.shared.updateRating(albumId: action.albumId, rating: rating)
            }
        }
        showConfirmation("\(actions.count) albums rated")
    }

    func executeReview(albumId: String, albumTitle: String, reviewText: String, rating: Float) {
        if rating > 0 {
            SoundScoreRepository.shared.updateRating(albumId: albumId, rating: rating)
        }
        SoundScoreRepository.shared.saveReview(albumId: albumId, reviewText: reviewText, rating: rating)
        showConfirmation("Review saved for \(albumTitle)")
    }

    func discardAction(messageId: String, actionId: UUID) {
        if let idx = messages.firstIndex(where: { $0.id == messageId }) {
            messages[idx].actions.removeAll { $0.id == actionId }
        }
    }

    private func showConfirmation(_ text: String) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation(.spring(response: 0.3)) { actionConfirmation = text }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation { self.actionConfirmation = nil }
        }
    }

    // MARK: - Follow-up Suggestions

    private func generateFollowUpSuggestions(hadActions: Bool) {
        let repo = SoundScoreRepository.shared
        let unrated = repo.albums.filter { repo.ratings[$0.id] == nil }
        var chips: [SuggestionChip] = []

        if hadActions {
            chips.append(SuggestionChip(label: "Do another one", prompt: "Rate and review another album from my library", icon: "arrow.clockwise"))
        }
        if let next = unrated.first {
            chips.append(SuggestionChip(label: "Review \(next.title)", prompt: "Draft a review for \(next.title) by \(next.artist)", icon: "square.and.pencil"))
        }
        chips.append(SuggestionChip(label: "Tell me more", prompt: "Tell me more about that", icon: "text.bubble"))
        chips.append(SuggestionChip(label: "Something different", prompt: "Surprise me with something completely different", icon: "shuffle"))
        suggestions = chips
    }

    // MARK: - Context Builders

    private func buildUserContext() -> String {
        let repo = SoundScoreRepository.shared
        let ratedAlbums = repo.ratings.compactMap { (albumId, rating) -> String? in
            guard let album = repo.albums.first(where: { $0.id == albumId }) else { return nil }
            return "\(album.title) by \(album.artist): \(rating)/6"
        }
        let genres = repo.profile.genres.prefix(5).joined(separator: ", ")
        let avgRating = String(format: "%.1f", repo.profile.avgRating)
        var context = "Rated \(repo.ratings.count)/\(repo.albums.count) albums. Avg: \(avgRating)/6. Genres: \(genres)."
        if !ratedAlbums.isEmpty {
            context += "\nRatings: \(ratedAlbums.joined(separator: "; "))."
        }
        return context
    }

    private func buildAlbumCatalog() -> String {
        SoundScoreRepository.shared.albums.map {
            "\($0.id): \($0.title) by \($0.artist) (\($0.year))"
        }.joined(separator: "\n")
    }
}
