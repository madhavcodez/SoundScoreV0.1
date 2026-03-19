import SwiftUI

@main
struct SoundScoreApp: App {
    init() {
        URLCache.shared = URLCache(
            memoryCapacityInBytes: 50_000_000,
            diskCapacityInBytes: 100_000_000
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
}

private extension URLCache {
    convenience init(memoryCapacityInBytes memory: Int, diskCapacityInBytes disk: Int) {
        self.init(memoryCapacity: memory, diskCapacity: disk)
    }
}
