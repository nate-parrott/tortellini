import Foundation

extension AppStore {
    func addRecipe(fromURL url: URL) async throws {
        try await Task.sleep(seconds: 2)
        enum AddRecipeError: Error {
            case notImplemented
        }
        throw AddRecipeError.notImplemented
    }
}
