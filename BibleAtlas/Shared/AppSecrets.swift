import Foundation

enum AppSecrets {
    static let agentApiKey: String = {
        guard
            let value = Bundle.main.object(forInfoDictionaryKey: "AGENT_API_KEY") as? String,
            !value.isEmpty
        else {
            fatalError(
                "AGENT_API_KEY is missing. " +
                "Create Config/Secrets.xcconfig with `AGENT_API_KEY = <your_key>` and rebuild."
            )
        }
        return value
    }()
}
