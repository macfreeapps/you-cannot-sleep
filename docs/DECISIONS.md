# Implementation decisions

- **Bundle placeholder:** `owner` is used as the repository owner placeholder in the bundle ID and URLs. Maintainers should replace it before publishing.
- **Custom duration:** Custom sessions use an hours-and-minutes stepper and persist the resulting minute count. The optional “until a specific time” mode is omitted to keep duration behavior small and predictable.
- **Assertion updates:** Existing assertion types are retained while missing types are created; obsolete types are released only after successful creation. This avoids a zero-assertion gap and does not create duplicate assertions of the same type.
- **Screen saver fallback:** The low-frequency `IOPMAssertionDeclareUserActivity` fallback is not enabled until screen saver behavior has been manually verified on each supported macOS version. The default path asks IOKit to prevent idle display sleep.
- **Performance measurements:** A macOS 27 Apple Silicon smoke run measured 20 MB physical footprint (21 MB peak), 0.0% sampled idle CPU, and a 2.6 MB universal Release bundle. Launch time and behavior across supported macOS releases still need measurement before distribution claims are made.
- **Icon:** The app uses an original, locally drawn coffee cup mark for its app/About icon. The menu bar uses Apple's template cup-and-saucer SF Symbols so it adapts to system appearance.
- **Battery policy precedence:** A manual activation while on battery is allowed and suppresses automatic battery shutoff until the next power-source transition.
- **URL launch behavior:** A URL command received during app startup suppresses the automatic first-launch welcome and activation so the URL action never opens a window and has predictable toggle behavior.
