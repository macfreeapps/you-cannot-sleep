import SwiftUI

struct AboutView: View {
    let onWelcome: () -> Void

    private var version: String {
        let short = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return String(localized: "Version \(short) (\(build))")
    }

    var body: some View {
        VStack(spacing: 12) {
            Image("CoffeeMark")
                .resizable()
                .scaledToFit()
                .frame(width: 70, height: 70)
                .accessibilityLabel(String(localized: "Coffee cup app icon"))
            Text(AppInfo.displayName).font(.title2.weight(.semibold))
            Text(version).font(.caption).foregroundStyle(.secondary)
            Text(String(localized: "A small menu bar utility that keeps your Mac awake."))
                .multilineTextAlignment(.center)
            HStack {
                Link(String(localized: "GitHub"), destination: AppInfo.repositoryURL)
                Link(String(localized: "Report an issue"), destination: AppInfo.issuesURL)
                Link(String(localized: "License"), destination: AppInfo.licenseURL)
            }
            Button(String(localized: "Show welcome again"), action: onWelcome)
                .buttonStyle(.link)
            Divider()
            VStack(alignment: .leading, spacing: 7) {
                Text(String(localized: "Frequently asked questions")).font(.headline)
                faq("Can it keep the Mac awake with the lid closed?", answer: "No. Closing the MacBook lid triggers clamshell sleep, which power assertions cannot prevent.")
                faq("How do I open the menu if left-click toggling is on?", answer: "Control-click the cup to open the menu at any time.")
                faq("Does my Mac need to be plugged in?", answer: "No. The app can keep your Mac awake on battery; battery options let you control that behavior.")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Spacer(minLength: 0)
        }
        .padding(22)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func faq(_ question: LocalizedStringKey, answer: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(question).font(.subheadline.weight(.medium))
            Text(answer).font(.caption).foregroundStyle(.secondary)
        }
    }
}
