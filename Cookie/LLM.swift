import Foundation
import ChatToys

extension AnthropicCredentials {
    static var shared: AnthropicCredentials? {
        if let key = UserDefaults.standard.string(forKey: DefaultsKeys.anthropicApiKey.rawValue)?.nilIfEmpty {
            return .init(apiKey: key)
        }
        return nil
    }

    static func getSharedCredsOrThrow() throws -> AnthropicCredentials {
        enum Errors: Error {
            case noAnthropicKey
        }
        guard let shared else {
            throw Errors.noAnthropicKey
        }
        return shared
    }
}
