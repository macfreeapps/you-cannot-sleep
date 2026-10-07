import SwiftUI

struct CustomDurationView: View {
    let onCancel: () -> Void
    let onChoose: (SessionDuration) -> Void
    @State private var hours = 1
    @State private var minutes = 0
    @State private var validationMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(String(localized: "Choose a duration from 1 minute to 24 hours."))
                .font(.callout).foregroundStyle(.secondary)
            HStack {
                Stepper(value: $hours, in: 0...24) { Text(String(localized: "Hours: \(hours)")) }
                Stepper(value: $minutes, in: 0...59) { Text(String(localized: "Minutes: \(minutes)")) }
            }
            if let validationMessage { Text(validationMessage).foregroundStyle(.red).font(.caption) }
            Spacer()
            HStack {
                Button(String(localized: "Cancel"), action: onCancel)
                Spacer()
                Button(String(localized: "Start")) {
                    let total = hours * 60 + minutes
                    guard (1...1440).contains(total) else {
                        validationMessage = String(localized: "Enter a duration from 1 minute to 24 hours.")
                        return
                    }
                    onChoose(.minutes(total))
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
    }
}
