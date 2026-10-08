import Foundation

enum SessionDuration: Hashable, Codable, Identifiable {
    case indefinite
    case minutes(Int)

    static let presets: [SessionDuration] = [
        .indefinite, .minutes(5), .minutes(10), .minutes(15), .minutes(30),
        .minutes(60), .minutes(120), .minutes(180), .minutes(300), .minutes(480)
    ]

    var id: String {
        switch self {
        case .indefinite: "indefinite"
        case .minutes(let value): "minutes:\(Self.clamped(value))"
        }
    }

    var minuteCount: Int? {
        guard case .minutes(let value) = self else { return nil }
        return Self.clamped(value)
    }

    var endDate: Date? {
        guard let minuteCount else { return nil }
        return Date().addingTimeInterval(TimeInterval(minuteCount * 60))
    }

    init?(id: String) {
        if id == "indefinite" {
            self = .indefinite
        } else if id.hasPrefix("minutes:"), let number = Int(id.dropFirst("minutes:".count)) {
            self = .minutes(Self.clamped(number))
        } else {
            return nil
        }
    }

    func endDate(from now: Date) -> Date? {
        guard let minuteCount else { return nil }
        return now.addingTimeInterval(TimeInterval(minuteCount * 60))
    }

    var displayName: String {
        switch self {
        case .indefinite:
            return String(localized: "Indefinitely")
        case .minutes(let raw):
            let minutes = Self.clamped(raw)
            let formatter = DateComponentsFormatter()
            formatter.allowedUnits = [.hour, .minute]
            formatter.unitsStyle = .full
            formatter.zeroFormattingBehavior = .dropAll
            return formatter.string(from: TimeInterval(minutes * 60)) ?? String(localized: "\(minutes) minutes")
        }
    }

    static func clamped(_ minutes: Int) -> Int {
        min(max(minutes, 1), 24 * 60)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        if value == "indefinite" {
            self = .indefinite
        } else if value.hasPrefix("minutes:"), let number = Int(value.dropFirst("minutes:".count)) {
            self = .minutes(Self.clamped(number))
        } else {
            self = .indefinite
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(id)
    }
}
