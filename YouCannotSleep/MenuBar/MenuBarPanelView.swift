import AppKit
import ServiceManagement
import SwiftUI
import UserNotifications

struct MenuBarPanelView: View {
    @ObservedObject var session: SessionController
    @ObservedObject var settings: AppSettings
    let loginItems: LoginItemService
    let notifications: NotificationService
    let height: CGFloat
    let onSettings: () -> Void
    let onAbout: () -> Void
    let onClose: () -> Void

    @State private var optionsExpanded = false
    @State private var customEditorExpanded = false
    @State private var loginError: String?
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @FocusState private var primaryFocused: Bool

    private let quickMinutes = [15, 20, 30, 50, 60, 120]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    statusHeader
                    Button {
                        session.toggle()
                    } label: {
                        Label(session.isActive ? String(localized: "Turn Off") : String(localized: "Keep your Mac awake"),
                              systemImage: session.isActive ? "stop.fill" : "play.fill")
                            .frame(maxWidth: .infinity, minHeight: 24)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .keyboardShortcut(.defaultAction)
                    .focused($primaryFocused)
                    .help(settings.hotKey?.displayString ?? String(localized: "Toggle the awake session."))

                    Divider()
                    durationChoices
                    Divider()
                    options
                }
                .padding(18)
            }
            Divider()
            HStack(spacing: 16) {
                Button(action: onSettings) {
                    Label(String(localized: "Settings…"), systemImage: "gearshape")
                }
                .keyboardShortcut(",", modifiers: .command)
                Spacer(minLength: 0)
                Button(String(localized: "About"), action: onAbout)
                Button(String(localized: "Quit")) { NSApp.terminate(nil) }
                    .keyboardShortcut("q", modifiers: .command)
            }
            .buttonStyle(.borderless)
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
        }
        .frame(width: 344, height: height)
        .background(.regularMaterial)
        .onExitCommand(perform: onClose)
        .onAppear {
            primaryFocused = true
            notifications.authorizationStatus { notificationStatus = $0 }
        }
    }

    private var statusHeader: some View {
        HStack(spacing: 12) {
            Image(nsImage: BeaconMenuIcon.image(active: session.isActive))
                .resizable()
                .scaledToFit()
                .frame(width: 25, height: 25)
                .padding(10)
                .background(session.isActive ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "Awake session")).font(.headline)
                TimelineView(.periodic(from: .now, by: 60)) { context in
                    Text(statusText(at: context.date))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                if session.isActive, let endDate = session.endDate {
                    HStack(spacing: 4) {
                        Text(String(localized: "Ends at"))
                        Text(endDate, style: .time)
                    }
                    .font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }

    private var durationChoices: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(String(localized: "Duration")).font(.subheadline.weight(.semibold))
            Button {
                session.choose(.indefinite)
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "infinity").font(.title3)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(String(localized: "Indefinitely")).fontWeight(.medium)
                        Text(String(localized: "Until you turn it off"))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: settings.defaultDuration == .indefinite ? "checkmark.circle.fill" : "circle")
                }
                .frame(maxWidth: .infinity, minHeight: 40)
                .foregroundStyle(.primary)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .tint(settings.defaultDuration == .indefinite ? .accentColor : .secondary)
            .accessibilityLabel(String(localized: "Indefinitely"))
            .accessibilityValue(selectionText(for: .indefinite))
            .accessibilityAddTraits(settings.defaultDuration == .indefinite ? .isSelected : [])

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(quickMinutes, id: \.self) { minutes in
                    let duration = SessionDuration.minutes(minutes)
                    let selected = settings.defaultDuration == duration
                    Button {
                        session.choose(duration)
                    } label: {
                        HStack(spacing: 4) {
                            Text(compactDuration(minutes)).fontWeight(selected ? .semibold : .regular)
                            if selected {
                                Image(systemName: "checkmark").font(.caption.weight(.bold))
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 24)
                        .foregroundStyle(.primary)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .tint(selected ? .accentColor : .secondary)
                    .accessibilityLabel(duration.displayName)
                    .accessibilityValue(selectionText(for: duration))
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
            }
            HStack(spacing: 8) {
                Menu {
                    ForEach(SessionDuration.presets.filter { $0 != .indefinite && !quickMinutes.contains($0.minuteCount ?? 0) }, id: \.self) { duration in
                        Button {
                            session.choose(duration)
                        } label: {
                            if settings.defaultDuration == duration {
                                Label(duration.displayName, systemImage: "checkmark")
                            } else {
                                Text(duration.displayName)
                            }
                        }
                    }
                } label: {
                    Text(String(localized: "More durations"))
                }
                .menuStyle(.borderlessButton)
                .frame(maxWidth: .infinity)
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        customEditorExpanded.toggle()
                    }
                } label: {
                    Label(
                        String(localized: customEditorExpanded ? "Hide" : "Custom…"),
                        systemImage: customEditorExpanded ? "chevron.up" : "slider.horizontal.3"
                    )
                }
                .buttonStyle(.bordered)
            }
            if customEditorExpanded {
                CustomDurationView(
                    onCancel: { customEditorExpanded = false },
                    onChoose: { duration in
                        session.choose(duration)
                        customEditorExpanded = false
                    }
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            if let minutes = settings.defaultDuration.minuteCount,
               !quickMinutes.contains(minutes) {
                Label(settings.defaultDuration.displayName, systemImage: "checkmark.circle")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Text(String(localized: "Choosing a duration starts or restarts the session."))
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var options: some View {
        DisclosureGroup(isExpanded: $optionsExpanded) {
            VStack(alignment: .leading, spacing: 12) {
                Toggle(String(localized: "Activate on launch"), isOn: $settings.activateOnLaunch)
                Toggle(String(localized: "Launch at login"), isOn: Binding(
                    get: { loginItems.isEnabled },
                    set: { value in
                        do {
                            try loginItems.setEnabled(value)
                            settings.launchAtLogin = value
                            loginError = nil
                        } catch { loginError = error.localizedDescription }
                    }
                ))
                if let loginError { Text(loginError).font(.caption).foregroundStyle(.red) }
                if loginItems.status == .requiresApproval {
                    Button(String(localized: "Open Login Items")) { loginItems.openLoginItemsSettings() }
                }
                Divider()
                Toggle(String(localized: "Allow display to sleep"), isOn: $settings.allowDisplaySleep)
                Toggle(String(localized: "Allow screen saver"), isOn: $settings.allowScreenSaver)
                if session.powerState.hasBattery {
                    Divider()
                    Toggle(String(localized: "Turn off on battery power"), isOn: $settings.turnOffOnBattery)
                    Toggle(String(localized: "Turn off below \(settings.batteryThreshold)%"), isOn: $settings.batteryThresholdEnabled)
                    Toggle(String(localized: "Turn on when charger connected"), isOn: $settings.turnOnWhenChargerConnected)
                }
                Divider()
                Toggle(String(localized: "Notifications"), isOn: Binding(
                    get: { settings.notifications },
                    set: { value in
                        settings.notifications = value
                        if value { notifications.requestAuthorization { notificationStatus = $0 } }
                    }
                ))
                if notificationStatus == .denied {
                    Text(String(localized: "Notifications are disabled in System Settings."))
                        .font(.caption).foregroundStyle(.secondary)
                }
                Toggle(String(localized: "Toggle with left click"), isOn: $settings.toggleWithLeftClick)
                Toggle(String(localized: "Show remaining time in menu bar"), isOn: $settings.showRemainingTime)
            }
            .toggleStyle(.checkbox)
            .font(.subheadline)
            .padding(.top, 12)
        } label: {
            Text(String(localized: "Options")).font(.subheadline.weight(.semibold))
        }
    }

    private func statusText(at date: Date) -> String {
        guard session.isActive else { return String(localized: "Inactive") }
        guard let remaining = session.remainingMinutes(at: date) else { return String(localized: "Active indefinitely") }
        return String(localized: "Active · \(remaining) min left")
    }

    private func compactDuration(_ minutes: Int) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = minutes < 60 ? .minute : [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = .dropAll
        return formatter.string(from: TimeInterval(minutes * 60)) ?? SessionDuration.minutes(minutes).displayName
    }

    private func selectionText(for duration: SessionDuration) -> String {
        settings.defaultDuration == duration ? String(localized: "Selected") : String(localized: "Not selected")
    }
}
