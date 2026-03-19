import Foundation

enum AppConfig {
    #if DEBUG
    static let apiBaseURL = "http://localhost:8080"
    #else
    static let apiBaseURL = "https://soundscore-api.up.railway.app"
    #endif
}
