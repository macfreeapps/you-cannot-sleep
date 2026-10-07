import SwiftUI

struct WelcomeView: View {
    @ObservedObject var settings: AppSettings
    let loginItems: LoginItemService
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image("CoffeeMark")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .accessibilityHidden(true)
            Text(String(localized: "Keep your Mac awake"))
                .font(.title2.weight(.semibold))
            VStack(alignment: .leading, spacing: 8) {
                Label(String(localized: "You Cannot Sleep lives in the menu bar."), systemImage: "menubar.arrow.up.rectangle")
                Label(String(localized: "Left-click opens the menu; right-click toggles."), systemImage: "hand.tap")
                Label(String(localized: "Your Mac is now being kept awake."), systemImage: "checkmark.circle")
            }
            .font(.callout)
            Toggle(String(localized: "Launch at login"), isOn: Binding(
                get: { loginItems.isEnabled },
                set: { value in
                    do { try loginItems.setEnabled(value); settings.launchAtLogin = value }
                    catch { }
                }
            ))
            .toggleStyle(.checkbox)
            Button(String(localized: "Got it"), action: onDone)
                .keyboardShortcut(.defaultAction)
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
