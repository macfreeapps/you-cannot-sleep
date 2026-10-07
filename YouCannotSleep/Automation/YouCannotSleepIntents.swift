import AppIntents
import Foundation

@available(macOS 13.0, *)
struct ToggleSessionIntent: AppIntent {
    static let title: LocalizedStringResource = "Toggle You Cannot Sleep"
    static let description = IntentDescription("Toggle the awake session.")
    static let openAppWhenRun = false

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            AppRuntime.sessionController?.toggle()
            AppRuntime.intentsLogger.info("Toggle intent performed")
        }
        return .result()
    }
}

@available(macOS 13.0, *)
struct TurnOnSessionIntent: AppIntent {
    static let title: LocalizedStringResource = "Turn On You Cannot Sleep"
    static let description = IntentDescription("Keep the Mac awake, optionally for a number of minutes.")
    static let openAppWhenRun = false

    @Parameter(title: "Duration in minutes", description: "Leave empty to use the saved duration.")
    var minutes: Int?

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            guard let session = AppRuntime.sessionController else { return }
            let duration = minutes.map { SessionDuration.minutes(SessionDuration.clamped($0)) }
            session.activate(duration: duration)
            AppRuntime.intentsLogger.info("Turn-on intent performed")
        }
        return .result()
    }
}

@available(macOS 13.0, *)
struct TurnOffSessionIntent: AppIntent {
    static let title: LocalizedStringResource = "Turn Off You Cannot Sleep"
    static let description = IntentDescription("Allow the Mac to sleep again.")
    static let openAppWhenRun = false

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            AppRuntime.sessionController?.deactivate(reason: .user)
            AppRuntime.intentsLogger.info("Turn-off intent performed")
        }
        return .result()
    }
}

@available(macOS 13.0, *)
struct SessionStatusEntity: AppEntity {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Awake Session Status"
    static let defaultQuery = SessionStatusQuery()

    @Property(title: "Active") var active: Bool
    @Property(title: "Remaining minutes") var remainingMinutes: Int?
    var id: String { "status" }

    var displayRepresentation: DisplayRepresentation {
        let title = active ? String(localized: "Active") : String(localized: "Inactive")
        let subtitle = remainingMinutes.map { String(localized: "\($0) minutes remaining") } ?? String(localized: "Indefinite or inactive")
        return DisplayRepresentation(title: LocalizedStringResource(stringLiteral: title), subtitle: LocalizedStringResource(stringLiteral: subtitle))
    }

    init(active: Bool, remainingMinutes: Int?) {
        self.active = active
        self.remainingMinutes = remainingMinutes
    }
}

@available(macOS 13.0, *)
struct SessionStatusQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [SessionStatusEntity] { [] }
    func suggestedEntities() async throws -> [SessionStatusEntity] { [] }
}

@available(macOS 13.0, *)
struct GetSessionStatusIntent: AppIntent {
    static let title: LocalizedStringResource = "Get You Cannot Sleep Status"
    static let description = IntentDescription("Get whether the awake session is active and how much time remains.")
    static let openAppWhenRun = false

    func perform() async throws -> some IntentResult & ReturnsValue<SessionStatusEntity> {
        let status = await MainActor.run {
            SessionStatusEntity(
                active: AppRuntime.sessionController?.isActive ?? false,
                remainingMinutes: AppRuntime.sessionController?.remainingMinutes()
            )
        }
        return .result(value: status)
    }
}

@available(macOS 13.0, *)
struct YouCannotSleepShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ToggleSessionIntent(),
            phrases: ["Toggle \(.applicationName)", "Keep my Mac awake with \(.applicationName)"],
            shortTitle: "Toggle session",
            systemImageName: "cup.and.saucer"
        )
        AppShortcut(
            intent: TurnOnSessionIntent(),
            phrases: ["Turn on \(.applicationName)"],
            shortTitle: "Turn on",
            systemImageName: "cup.and.saucer.fill"
        )
        AppShortcut(
            intent: TurnOffSessionIntent(),
            phrases: ["Turn off \(.applicationName)"],
            shortTitle: "Turn off",
            systemImageName: "cup.and.saucer"
        )
        AppShortcut(
            intent: GetSessionStatusIntent(),
            phrases: ["Get \(.applicationName) status"],
            shortTitle: "Get status",
            systemImageName: "info.circle"
        )
    }
}
