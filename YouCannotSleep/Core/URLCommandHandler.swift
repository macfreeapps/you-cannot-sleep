import Foundation

enum URLCommand: Equatable {
    case toggle
    case turnOn(minutes: Int?)
    case turnOff
}

enum URLCommandHandler {
    static func parse(_ url: URL) -> URLCommand? {
        guard url.scheme?.lowercased() == AppInfo.urlScheme else { return nil }
        let command = url.host?.lowercased() ?? url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/")).lowercased()
        switch command {
        case "toggle": return .toggle
        case "off": return .turnOff
        case "on":
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            guard let item = components?.queryItems?.first(where: { $0.name == "minutes" }) else { return .turnOn(minutes: nil) }
            guard let raw = item.value, let minutes = Int(raw) else { return nil }
            return .turnOn(minutes: SessionDuration.clamped(minutes))
        default: return nil
        }
    }
}
