import Foundation

struct WeeklyRecap: Identifiable {
    let id: String
    let weekStart: String
    let weekEnd: String
    let totalLogs: Int
    let averageRating: Float
    let shareText: String
    let deepLink: String
}
