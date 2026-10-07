import Foundation

enum AppInfo {
    static let displayName = "You Cannot Sleep"
    static let bundleIdentifier = "io.github.tarudesu.YouCannotSleep"
    static let urlScheme = "youcannotsleep"
    static let repositoryURL = URL(string: "https://github.com/tarudesu/you-cannot-sleep") ?? URL(fileURLWithPath: "/")
    static let issuesURL = URL(string: "https://github.com/tarudesu/you-cannot-sleep/issues") ?? URL(fileURLWithPath: "/")
    static let licenseURL = URL(string: "https://github.com/tarudesu/you-cannot-sleep/blob/main/LICENSE") ?? URL(fileURLWithPath: "/")
}
