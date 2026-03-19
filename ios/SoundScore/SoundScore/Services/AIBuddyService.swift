import Foundation

struct ChatMessage: Identifiable, Equatable {
    let id: String
    let role: ChatRole
    let content: String
    let timestamp: Date
    var actions: [CadenceAction]

    init(role: ChatRole, content: String, actions: [CadenceAction] = []) {
        self.id = UUID().uuidString
        self.role = role
        self.content = content
        self.timestamp = Date()
        self.actions = actions
    }

    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.id == rhs.id
    }
}

enum ChatRole: String {
    case user
    case assistant
    case system
}

// MARK: - Agentic Actions

enum CadenceActionType: String, Codable {
    case rateAlbum
    case draftReview
    case addToList
    case searchAlbum
}

struct CadenceAction: Identifiable, Equatable {
    let id = UUID()
    let type: CadenceActionType
    let albumId: String
    let albumTitle: String
    let label: String
    let value: String // rating value or review text

    static func == (lhs: CadenceAction, rhs: CadenceAction) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Service

actor AIBuddyService {
    static let shared = AIBuddyService()

    private let model = "gemini-2.5-flash"

    private var apiURL: URL {
        URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(Secrets.geminiAPIKey)")!
    }

    func sendMessage(
        messages: [ChatMessage],
        userContext: String,
        albumCatalog: String
    ) async throws -> (text: String, actions: [CadenceAction]) {
        let systemPrompt = buildSystemPrompt(userContext: userContext, albumCatalog: albumCatalog)

        var contents: [[String: Any]] = []
        for msg in messages {
            let role: String = msg.role == .assistant ? "model" : "user"
            contents.append([
                "role": role,
                "parts": [["text": msg.content]],
            ])
        }

        let body: [String: Any] = [
            "contents": contents,
            "systemInstruction": [
                "parts": [["text": systemPrompt]],
            ],
            "generationConfig": [
                "temperature": 0.9,
                "maxOutputTokens": 1000,
            ],
        ]

        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw AIBuddyError.networkError
        }

        guard let http = response as? HTTPURLResponse else {
            throw AIBuddyError.networkError
        }

        if http.statusCode == 400 || http.statusCode == 403 {
            throw AIBuddyError.invalidKey
        }

        guard (200...299).contains(http.statusCode) else {
            throw AIBuddyError.apiError(http.statusCode)
        }

        let decoded = try JSONDecoder().decode(GeminiResponse.self, from: data)
        guard let candidate = decoded.candidates?.first,
              let part = candidate.content?.parts?.first,
              let rawText = part.text, !rawText.isEmpty
        else {
            throw AIBuddyError.noResponse
        }

        let (cleanText, actions) = parseActions(from: rawText)
        return (cleanText, actions)
    }

    // MARK: - Action Parsing

    private func parseActions(from text: String) -> (String, [CadenceAction]) {
        var actions: [CadenceAction] = []
        var cleanText = text

        // Parse [RATE:album_id:album_title:rating]
        let ratePattern = /\[RATE:([^:]+):([^:]+):([0-9.]+)\]/
        for match in text.matches(of: ratePattern) {
            actions.append(CadenceAction(
                type: .rateAlbum,
                albumId: String(match.1),
                albumTitle: String(match.2),
                label: "Rate \(match.2) → \(match.3)/6",
                value: String(match.3)
            ))
            cleanText = cleanText.replacingOccurrences(of: String(match.0), with: "")
        }

        // Parse [REVIEW:album_id:album_title:review text here]
        let reviewPattern = /\[REVIEW:([^:]+):([^:]+):([^\]]+)\]/
        for match in text.matches(of: reviewPattern) {
            actions.append(CadenceAction(
                type: .draftReview,
                albumId: String(match.1),
                albumTitle: String(match.2),
                label: "Save review for \(match.2)",
                value: String(match.3)
            ))
            cleanText = cleanText.replacingOccurrences(of: String(match.0), with: "")
        }

        // Parse [SEARCH:query text here]
        let searchPattern = /\[SEARCH:([^\]]+)\]/
        for match in text.matches(of: searchPattern) {
            actions.append(CadenceAction(
                type: .searchAlbum,
                albumId: "",
                albumTitle: String(match.1),
                label: "Search for \(match.1)",
                value: String(match.1)
            ))
            cleanText = cleanText.replacingOccurrences(of: String(match.0), with: "")
        }

        return (cleanText.trimmingCharacters(in: .whitespacesAndNewlines), actions)
    }

    // MARK: - System Prompt

    private func buildSystemPrompt(userContext: String, albumCatalog: String) -> String {
        """
        You are Cadence, an AI music agent inside the SoundScore app.

        YOU CAN TAKE ACTIONS. When appropriate, include action tags in your response:
        - To suggest rating an album: [RATE:album_id:Album Title:4.5]
        - To draft a review: [REVIEW:album_id:Album Title:Your review text here]
        - To search for an album not in the catalog: [SEARCH:album name artist]

        IMPORTANT RULES FOR ACTIONS:
        - Only use album IDs from the catalog below for RATE and REVIEW. Never invent IDs.
        - When the user asks about an album not in their catalog, use [SEARCH:album name artist] \
        to find it. The app will show results they can add to their library.
        - Only suggest actions when the user asks you to rate, review, or when it naturally fits.
        - You can draft reviews in the user's voice — match their taste and style.
        - Ratings are on a 6-point scale (0-6). Be honest and specific with scores.
        - Place action tags at the END of your message, after your conversational text.

        PERSONALITY — You are a dorky, passionate music nerd:
        - You get unreasonably excited about production details — you'll namecheck engineers, \
        mention specific studio gear, and geek out about a hi-hat pattern.
        - You draw weird but accurate genre connections — "this has the same energy as if MF DOOM \
        produced a Cocteau Twins record."
        - You use music-nerd slang naturally: "the low end is BONKERS", "that bridge modulation \
        is chef's kiss", "the A&R who greenlit this deserves a raise."
        - You have hot takes you'll defend passionately but never rudely.
        - Occasionally drop obscure trivia mid-conversation.
        - Reference specific production details, lyrics, or musical choices when discussing albums.
        - Compare albums to other works to add context.
        - Keep responses 2-3 paragraphs max unless drafting a review.
        - When drafting reviews, write 3-5 sentences that feel personal and specific.
        - If asked about non-music topics, redirect playfully back to music.

        ALBUM CATALOG (id: title by artist):
        \(albumCatalog)

        \(userContext.isEmpty ? "" : "LISTENER PROFILE:\n\(userContext)")
        """
    }
}

enum AIBuddyError: LocalizedError, Equatable {
    case networkError
    case invalidKey
    case apiError(Int)
    case noResponse

    var errorDescription: String? {
        switch self {
        case .networkError: "Network error. Check your connection."
        case .invalidKey: "Invalid API key. Check your Gemini configuration."
        case .apiError(let code): "API error (code \(code))."
        case .noResponse: "No response from Cadence."
        }
    }
}

// MARK: - Gemini Response Types

private struct GeminiResponse: Decodable {
    let candidates: [GeminiCandidate]?
}

private struct GeminiCandidate: Decodable {
    let content: GeminiContent?
}

private struct GeminiContent: Decodable {
    let parts: [GeminiPart]?
}

private struct GeminiPart: Decodable {
    let text: String?
}
