import Foundation

final class ChatUsageCounter {
    private let defaults: UserDefaults
    private let key = "chat.usage.count"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var currentCount: Int {
        defaults.integer(forKey: key)
    }

    func increment() {
        defaults.set(currentCount + 1, forKey: key)
    }

    func reset() {
        defaults.removeObject(forKey: key)
    }
}
