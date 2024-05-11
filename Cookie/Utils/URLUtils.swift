import Foundation

private func stringHasURLScheme(_ str: String) -> Bool {
    if let comps = URLComponents(string: str) {
        return comps.scheme?.count ?? 0 > 0
    }
    return false
}

extension URL {
    public static func withNaturalString(_ string: String) -> URL? {
        if !(string.contains(":") || string.contains(".")) {
            return nil
        }
        if stringHasURLScheme(string) {
            return URL(string: string)
        }
        return URL(string: "https://" + string)
    }
    public static func withSearchQuery(_ searchQuery: String) -> URL {
        return withNaturalString(searchQuery) ?? googleSearch(searchQuery)
    }
    public static func googleSearch(_ query: String) -> URL {
        var comps = URLComponents(string: "https://google.com/search")!
        comps.queryItems = [URLQueryItem(name: "q", value: query)]
        return comps.url!
    }
}
