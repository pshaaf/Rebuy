## Codebase Overview

This is a dental patient-facing iOS application for treatment plan presentation, acceptance, and payment management. It's built with native iOS technologies and integrates with dental practice management systems.

## Tech Stack

- **Core:** Swift 6.0+ with SwiftUI
- **Architecture:** MVVM (Model-View-ViewModel) with Combine
- **UI Framework:** SwiftUI with custom components
- **Networking:** URLSession with async/await
- **Data Persistence:** SwiftData / Core Data
- **Forms & Validation:** Custom form validation with property wrappers
- **Charts:** Swift Charts (iOS 16+)
- **Dependencies:** Swift Package Manager (SPM)

### Key Frameworks & Libraries

- **SwiftUI** - Declarative UI framework
- **Combine** - Reactive programming for data flow
- **Foundation** - Core utilities and date formatting
- **PDFKit** - PDF generation and viewing
- **PencilKit** - Digital signature capture
- **PassKit** - Apple Pay integration
- **LocalAuthentication** - Face ID / Touch ID
- **CryptoKit** - Secure data encryption

## Key Features

1. **Treatment Plan Presentation** - Display dental procedures with costs, insurance coverage, and patient responsibility
2. **Payment & Financing** - Payment plan calculator with multiple financing options (in-house, CareCredit, Planet DDS Pay)
3. **Insurance Management** - Card capture via camera, manual entry, and coverage verification
4. **Digital Signatures** - PencilKit-based signature pad for consent forms with Apple Pencil support
5. **Practice Integration** - Integration with Denticon and Cloud9 dental software APIs
6. **Multi-channel Delivery** - Deep links via SMS, email, universal links, and QR codes
7. **Patient Financials** - Account balance, payment history, and payment method management
8. **Apple Pay** - Native Apple Pay integration for quick payments
9. **Biometric Auth** - Face ID / Touch ID for secure access

## Project Structure

```
DentalPatient/
├── App/
│   ├── DentalPatientApp.swift          # App entry point
│   └── AppDelegate.swift               # App lifecycle & notifications
│
├── Core/
│   ├── Networking/
│   │   ├── APIClient.swift             # Base networking layer
│   │   ├── APIEndpoint.swift           # Endpoint definitions
│   │   └── NetworkError.swift          # Error handling
│   ├── Extensions/
│   │   ├── View+Extensions.swift
│   │   ├── Color+Theme.swift
│   │   └── Date+Formatting.swift
│   └── Utilities/
│       ├── KeychainManager.swift       # Secure storage
│       ├── DeepLinkHandler.swift       # URL scheme handling
│       └── BiometricAuth.swift         # Face/Touch ID
│
├── Models/
│   ├── Patient.swift                   # Patient data model
│   ├── TreatmentPlan.swift            # Treatment plan structure
│   ├── Procedure.swift                 # Individual procedures
│   ├── Insurance.swift                 # Insurance coverage
│   ├── Payment.swift                   # Payment models
│   └── ConsentForm.swift              # Consent form data
│
├── ViewModels/
│   ├── TreatmentPlanViewModel.swift
│   ├── PaymentViewModel.swift
│   ├── InsuranceViewModel.swift
│   ├── SignatureViewModel.swift
│   └── PatientFinancialsViewModel.swift
│
├── Views/
│   ├── TreatmentAcceptance/
│   │   ├── TreatmentPlanView.swift
│   │   ├── ProcedureListView.swift
│   │   └── CostBreakdownView.swift
│   ├── Payment/
│   │   ├── PaymentPlanView.swift
│   │   ├── FinancingOptionsView.swift
│   │   └── ApplePayView.swift
│   ├── Insurance/
│   │   ├── InsuranceCardScanView.swift
│   │   ├── InsuranceEntryView.swift
│   │   └── CoverageDetailView.swift
│   ├── Signature/
│   │   ├── SignaturePadView.swift
│   │   └── ConsentFormView.swift
│   ├── PatientFinancials/
│   │   ├── AccountBalanceView.swift
│   │   ├── PaymentHistoryView.swift
│   │   └── PaymentMethodsView.swift
│   └── Components/
│       ├── CustomButton.swift
│       ├── LoadingView.swift
│       ├── ErrorView.swift
│       └── CardView.swift
│
├── Services/
│   ├── TreatmentService.swift          # Treatment plan API
│   ├── PaymentService.swift            # Payment processing
│   ├── InsuranceService.swift          # Insurance verification
│   ├── DenticonService.swift           # Denticon integration
│   ├── Cloud9Service.swift             # Cloud9 integration
│   └── NotificationService.swift       # Push notifications
│
├── Resources/
│   ├── Assets.xcassets/                # Images, colors, icons
│   ├── Fonts/                          # Custom fonts
│   └── Localizable.strings             # Localization
│
└── Supporting Files/
    ├── Info.plist
    ├── Entitlements.plist              # Capabilities
    └── Config/
        ├── Development.xcconfig
        ├── Staging.xcconfig
        └── Production.xcconfig
```

## Architecture Highlights

- **SwiftUI + MVVM** - Reactive, declarative UI with clear separation of concerns
- **Type-safe** - Comprehensive Swift type system with Codable models
- **Protocol-oriented** - Heavy use of protocols for dependency injection and testing
- **Async/await** - Modern concurrency for network calls and async operations
- **Keychain storage** - Secure storage for sensitive data (tokens, credentials)
- **Deep linking** - Universal links and custom URL schemes for SMS/email integration
- **Multi-environment** - Configuration files for dev, staging, and production
- **Accessibility** - VoiceOver support, Dynamic Type, and reduced motion

## Development Guidelines

### Code Organization

- **One type per file** - Each struct, class, or enum in its own file
- **Group by feature** - Related views, view models, and services together
- **Protocols first** - Define interfaces before implementations
- **Extensions** - Use extensions to organize code by conformance

### Naming Conventions

- **Views:** Suffix with `View` (e.g., `TreatmentPlanView`)
- **ViewModels:** Suffix with `ViewModel` (e.g., `PaymentViewModel`)
- **Services:** Suffix with `Service` (e.g., `TreatmentService`)
- **Protocols:** Descriptive names without prefixes (e.g., `PaymentProcessing`)
- **Properties:** camelCase, descriptive names
- **Methods:** camelCase, verb-based names

### SwiftUI Best Practices

- **Prefer `@StateObject`** for view model ownership
- **Use `@ObservedObject`** for passed-in view models
- **Extract subviews** when body gets complex (>10 lines)
- **ViewBuilders** for conditional rendering
- **PreferenceKeys** for child-to-parent communication
- **Environment** for dependency injection

---

## Agent Delegation Rules

When working on coding tasks in this project, **proactively delegate to specialized agents** located in `.claude/agents/`:

### Automatic Delegation Triggers

1. **After writing significant code** → Immediately use the `code-review-specialist` agent
   - Trigger: Any time you create or modify 10+ lines of Swift code
   - Trigger: When implementing authentication, security, Keychain, or data handling logic
   - Trigger: After refactoring existing functionality
   - Trigger: When adding new network calls or API integrations

2. **When implementing new features** → Start with the `code-writer` agent
   - Trigger: User asks to "implement", "create", "add", or "build" functionality
   - Trigger: When fixing bugs that require code changes
   - Trigger: When refactoring existing code
   - Trigger: When adding new views, view models, or services

### Coordination Pattern

For complex tasks, use this sequence:

1. **Planning Phase**: Use TodoWrite to break down the task into Swift-specific components
2. **Implementation Phase**: Delegate to `code-writer` agent for SwiftUI/Swift implementation 
3. **Review Phase**: Delegate to `code-review-specialist` for security, memory management, and iOS best practices review
4. **Completion**: Mark todos as complete and summarize results

### Example Delegation Prompts

When delegating, use clear, specific prompts:
- "Use the code-writer agent to implement [specific feature] in SwiftUI"
- "Use the code-review-specialist to review the changes in [files] for memory leaks, retain cycles, and iOS security best practices"

### Important Notes

- These agents are defined in `.claude/agents/` with specialized instructions
- Always wait for agent completion before proceeding to the next step
- If an agent identifies issues (retain cycles, force unwraps, etc.), address them before moving forward
- Ensure code follows Swift API Design Guidelines

---

## MCP Servers

### Figma Dev Mode MCP Rules

- The Figma Dev Mode MCP Server provides an assets endpoint which can serve image and SVG assets
- **IMPORTANT:** If the Figma Dev Mode MCP Server returns a localhost source for an image, download it and add to Assets.xcassets
- **IMPORTANT:** For SVG assets, convert to PDF vectors or use SwiftUI shapes
- **IMPORTANT:** DO NOT use external icon packages - all assets should be in Assets.xcassets from Figma
- **IMPORTANT:** Use SF Symbols where appropriate for system icons

---

## iOS-Specific Requirements

### Security & Privacy

- **Keychain** for storing sensitive data (auth tokens, payment info)
- **Biometric authentication** for app access and payment confirmation
- **Certificate pinning** for API security
- **Data encryption** at rest using CryptoKit
- **Privacy manifest** (PrivacyInfo.xcprivacy) documenting data collection
- **App Transport Security** enforced (HTTPS only)

### Performance

- **Lazy loading** for large lists using `LazyVStack`/`LazyHStack`
- **Image caching** with custom caching layer or SDWebImageSwiftUI
- **Background refresh** for updating treatment plans and notifications
- **Memory management** - avoid retain cycles, use `weak` and `unowned` appropriately
- **Instruments profiling** for identifying performance bottlenecks

### Accessibility

- **VoiceOver** labels for all interactive elements
- **Dynamic Type** support for text scaling
- **Reduced Motion** respect for animations
- **Color contrast** meeting WCAG AA standards
- **Haptic feedback** for important actions

### Device Support

- **iOS 16.0+** minimum deployment target
- **iPhone only** (or Universal if iPad support added)
- **Portrait and landscape** orientation support
- **Dark mode** full support
- **Safe area** respect for notched devices
- **iPad optimization** (if Universal) with split view support

### Testing Requirements

- **Unit tests** for ViewModels and Services
- **UI tests** for critical user flows
- **Snapshot tests** for visual regression
- **Integration tests** for API interactions
- **Accessibility audits** using Xcode Accessibility Inspector
- **Performance testing** with XCTest performance metrics

### App Store Requirements

- **App icons** in all required sizes (Assets.xcassets)
- **Launch screen** using LaunchScreen.storyboard or Info.plist config
- **Privacy policy** URL in App Store Connect
- **Terms of service** for payment processing
- **HIPAA compliance** documentation for healthcare data
- **PCI compliance** for payment card data handling

---

## Project-Specific Context

- Follow Apple's Human Interface Guidelines for iOS
- Use SF Symbols for system icons where applicable
- Implement proper error handling with user-friendly messages
- Ensure HIPAA compliance for patient data handling
- Test on multiple device sizes (iPhone SE, standard, Plus/Max)
- Support both light and dark mode
- Handle offline scenarios gracefully

## Build Configurations

- **Debug** - Development with verbose logging
- **Staging** - QA environment with test APIs
- **Release** - Production with analytics and crash reporting

## Third-Party Dependencies (SPM)

Consider these if needed:
- **Alamofire** - Advanced networking (if URLSession isn't sufficient)
- **Kingfisher** - Image downloading and caching
- **Sentry** - Crash reporting and error tracking
- **Firebase** - Push notifications and analytics
- **StripeSDK** - Payment processing integration

Keep dependencies minimal and prefer native solutions when possible.
