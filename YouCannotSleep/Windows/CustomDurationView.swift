import SwiftUI

struct CustomDurationView: View {
    private enum Field: Hashable { case hours, minutes }

    let onCancel: () -> Void
    let onChoose: (SessionDuration) -> Void
    @State private var hours = 0
    @State private var minutes = 0
    @State private var validationMessage: String?
    @FocusState private var focusedField: Field?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(String(localized: "Choose a duration from 1 minute to 24 hours."))
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            HStack(alignment: .top, spacing: 12) {
                durationField(title: String(localized: "Hours"), value: $hours, field: .hours)
                durationField(title: String(localized: "Minutes"), value: $minutes, field: .minutes)
            }
            if let validationMessage { Text(validationMessage).foregroundStyle(.red).font(.caption) }
            HStack {
                Spacer()
                Button(String(localized: "Cancel"), action: onCancel)
                Button(String(localized: "Start"), action: chooseDuration)
                    .buttonStyle(.borderedProminent)
            }
        }
        .buttonStyle(.bordered)
        .controlSize(.regular)
        .padding(12)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
        .onAppear { focusedField = .hours }
    }

    private func durationField(title: String, value: Binding<Int>, field: Field) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField("0", value: value, format: .number)
                .textFieldStyle(.roundedBorder)
                .frame(width: 76)
                .focused($focusedField, equals: field)
                .accessibilityLabel(title)
                .onSubmit {
                    if field == .hours { focusedField = .minutes }
                    else { chooseDuration() }
                }
        }
    }

    private func chooseDuration() {
        let total = hours * 60 + minutes
        guard (0...24).contains(hours), (0...59).contains(minutes), (1...1440).contains(total) else {
            validationMessage = String(localized: "Enter a duration from 1 minute to 24 hours.")
            return
        }
        onChoose(.minutes(total))
    }
}
