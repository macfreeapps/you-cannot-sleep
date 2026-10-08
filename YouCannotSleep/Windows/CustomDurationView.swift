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
                Stepper(value: $hours, in: 0...24) { Text(String(localized: "Hours: \(hours)")).fixedSize() }
                    .frame(maxWidth: .infinity, alignment: .leading)
                Stepper(value: $minutes, in: 0...59) { Text(String(localized: "Minutes: \(minutes)")).fixedSize() }
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            if let validationMessage { Text(validationMessage).foregroundStyle(.red).font(.caption) }
            Spacer()
            HStack {
                Button(String(localized: "Cancel"), action: onCancel)
                    .buttonStyle(.bordered)
                Spacer()
                Button(String(localized: "Start")) {
                    let total = hours * 60 + minutes
                    guard (1...1440).contains(total) else {
                        validationMessage = String(localized: "Enter a duration from 1 minute to 24 hours.")
                        return
                    }
                    onChoose(.minutes(total))
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 400, height: 280, alignment: .topLeading)
    }
}
