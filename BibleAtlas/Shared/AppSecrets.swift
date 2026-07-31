import Foundation

enum AppSecrets {
    static let agentApiKey: String = {
        guard
            let value = Bundle.main.object(forInfoDictionaryKey: "AGENT_API_KEY") as? String,
            !value.isEmpty
        else {
            fatalError(
                "AGENT_API_KEY is missing. " +
                "Copy Config/Secrets.xcconfig.template to Config/Secrets.xcconfig and fill it in."
            )
        }
        return value
    }()
}
