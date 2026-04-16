# Bus Ticket Booking App

## 1) Project Overview

**Name:** Bus Ticket Booking App  
**Platform:** iOS (SwiftUI)  
**Architecture:** MVVM  
**Backend:** Firebase Authentication + Cloud Firestore  
**Primary Domain:** Bus ticket search, booking, seat management, and admin fleet/ticket operations

This project is a role-based bus ticket booking application with two experiences:

- **User app flow:** Search routes, view buses, select seats, confirm booking, download/share PDF tickets, view/cancel bookings, manage profile and notification preferences.
- **Admin flow:** View dashboard stats, add/manage buses, monitor sold tickets, and manage admin profile.

## 2) Core Capabilities

### User-facing

- Email/password authentication with email verification
- Route search by source and destination
- Bus list and trip detail screens
- Seat selection on a 40-seat matrix (A1 to J4)
- Discount-aware pricing and dedicated offers tab
- Booking confirmation and Firestore persistence
- Ticket PDF generation and sharing
- My tickets view with booking cancellation
- Profile editing and notification preference controls
- Light/dark mode toggle via local storage

### Admin-facing

- Role-gated dashboard
- Bus creation with route, time, pricing, discount, and stop points
- Bus list management with delete support
- Sold ticket monitoring with joined user + trip details
- Dashboard summary cards (buses, users, bookings, routes)

## 3) Technical Stack

- **Language:** Swift
- **UI:** SwiftUI
- **State management:** `ObservableObject`, `@Published`, `@StateObject`, `@EnvironmentObject`
- **Concurrency:** Swift concurrency + `@MainActor`
- **Auth:** FirebaseAuth
- **Database:** FirebaseFirestore
- **Document generation:** `UIGraphicsPDFRenderer`, SwiftUI-to-image rendering
- **External API:** Bangladesh district endpoints in `DistrictService`

## 4) High-Level Architecture

```text
BusTicketBookingApp (entry)
	-> ContentView
			-> SplashScreenView
			-> SignInView / SignUpView (unauthenticated)
			-> MainTabView (user)
			-> AdminDashboardView (admin)

Data Layer: Models/
Business Layer: ViewModels/
UI Layer: Views/ + Components/
Utility Layer: Utilities/
```

### App boot flow

1. `BusTicketBookingApp` configures Firebase.
2. `ContentView` creates `AuthViewModel` and applies dark/light scheme.
3. Splash screen displays for ~2.5 seconds.
4. Auth state decides target UI:
	 - Unauthenticated -> `SignInView`
	 - Authenticated + admin -> `AdminDashboardView`
	 - Authenticated + non-admin -> `MainTabView`

## 5) Data Model Summary

- **`UserProfile` / `NotificationPreferences`:** User identity, contact fields, role, toggles.
- **`BusTrip`:** Bus metadata, source/destination, schedule, ticket price, discount, bus type, 40-seat matrix, pickup/drop points.
- **`Booking` / `BookingConfirmation`:** Booked seats, totals, trip linkage, status and dates.
- **`Route`:** Aggregated route with minimum price.
- **`District` / API wrappers:** District mapping from external endpoint.
- **`SeatHelper`:** Index/label mapping and seat-matrix utilities.

## 6) Firestore Collections and Stored Data

### `users`

- `fullName`, `email`, `phone`, `contactNo`, `address`
- `role` (`user` / `admin`)
- `notificationPreferences` object
- `createdAt`, `updatedAt`

### `busTrips`

- `busName`, `source`, `destination`
- `departureTime`, `arrivalTime`
- `ticketPrice`, `discount`
- `availableSeats`, `seatMatrix` (40-char binary string)
- `busType`, `pickupPoints`, `droppingPoints`

### `bookings`

- `userId`, `busTripId`
- `seatIndices`, `seatLabels`
- `totalPrice`
- `bookingDate`, `travelDate`
- `status` (`confirmed` / `cancelled`)

## 7) Booking and Seat Logic

- Seat map is represented as a binary string of length 40:
	- `0` = available
	- `1` = booked
- Logical seat grid: 10 rows x 4 columns, labels `A1`...`J4`
- Booking commit uses Firestore batch write:
	1. Update `busTrips.seatMatrix` and `availableSeats`
	2. Create booking document in `bookings`
	3. Commit atomically

## 8) Ticket PDF Workflow

`TicketPDFGenerator.generatePDF(...)` creates a 2-page PDF:

1. **Page 1:** Ticket details (booking id, route, bus, passenger, seats, booking date, total).
2. **Page 2:** Seat layout visualization using `SeatLayoutPDFView`.

Output is saved to temporary storage and exposed for sharing via `ShareSheet`.

## 9) External Services and Integration Points

- **FirebaseApp.configure()** at startup
- **FirebaseAuth** for sign up/sign in/sign out/password flows
- **Firestore** for users, trips, bookings
- **District API** endpoints used by `DistrictService`:
	- `https://bdapis.vercel.app/geo/v2.0/districts`
	- `https://bdapi.vercel.app/api/v.1/district` (fallback)

## 10) Local Configuration and Assets

- `GoogleService-Info.plist` contains Firebase project config for the app target
- `@AppStorage("isDarkMode")` stores appearance preference
- Assets and icons are in `Assets.xcassets`
- Entitlements are present in multiple files (main + xml variants)

## 11) Build, Run, and Test

### Prerequisites

- macOS with Xcode installed
- Apple developer signing configuration for device deployment
- Firebase project with Authentication and Firestore enabled

### Open project

Use Xcode to open:

- `BusTicketBooking.xcodeproj`

### Build and run

1. Select the `BusTicketBooking` scheme.
2. Pick simulator/device.
3. Build: Product -> Build.
4. Run: Product -> Run.

### Tests

- Unit tests target: `BusTicketBookingTests`
- UI tests target: `BusTicketBookingUITests`

Current non-placeholder unit tests validate bus discount behavior in `BusTrip`.

## 12) Security and Operational Notes

- Admin detection currently includes hardcoded email logic (`admin@gmail.com`) in auth flow.
- Email verification is required for normal users; admin path bypasses this.
- Booking is immediate confirmation (no payment gateway integration).
- District loading depends on external endpoints; fallback exists.
- Firestore missing-index scenarios are partially handled in code with fallback querying.

## 13) Known Gaps and Improvement Opportunities

- Replace hardcoded admin email logic with role-only authorization from secure backend rules.
- Add transaction-level seat locking or conflict-safe booking retries.
- Integrate payment processing and refund workflow.
- Expand automated tests for ViewModels, booking flow, and UI journeys.
- Add edit/update support for existing buses (admin currently has add/delete focus).
- Wire notification preferences to real push/email delivery pipeline.

## 14) Full Repository Structure

```text
README.md
BusTicketBooking/
	BusTicketBooking.entitlements
	BusTicketBooking.entitlements.xml
	BusTicketBooking.entitlements(1).xml
	BusTicketBookingApp.swift
	ContentView.swift
	GoogleService-Info.plist
	MainTabView.swift
	Assets.xcassets/
		Contents.json
		AccentColor.colorset/
			Contents.json
		AppIcon.appiconset/
			Contents.json
	Components/
		BannerView.swift
		BusCardView.swift
		DistrictAutocompleteField.swift
		DistrictPickerView.swift
		RouteCardView.swift
		SeatLayoutPDFView.swift
		ShareSheet.swift
		Theme.swift
	Models/
		Booking.swift
		BusTrip.swift
		District.swift
		Route.swift
		SeatHelper.swift
		UserModel.swift
	Preview Content/
		Preview Assets.xcassets/
			Contents.json
	Utilities/
		DistrictService.swift
		TicketPDFGenerator.swift
	ViewModels/
		AdminViewModel.swift
		AuthViewModel.swift
		BookingViewModel.swift
		BusTripViewModel.swift
		RouteViewModel.swift
		SeedService.swift
	Views/
		AddBusView.swift
		AdminDashboardView.swift
		AdminProfileView.swift
		BookingConfirmationView.swift
		BusListView.swift
		BusTripDetailView.swift
		ChangePasswordView.swift
		ForgotPasswordView.swift
		HomeView.swift
		ManageBusesView.swift
		MoreView.swift
		NotificationPreferencesView.swift
		OffersView.swift
		ProfileView.swift
		SeatSelectionView.swift
		SignInView.swift
		SignUpView.swift
		SoldTicketsView.swift
		SplashScreenView.swift
		TicketsView.swift
BusTicketBooking.xcodeproj/
	project.pbxproj
	project.xcworkspace/
		contents.xcworkspacedata
		contents.xcworkspacedata.xml
		contents.xcworkspacedata(1).xml
		contents.xcworkspacedata(1)(1).xml
		xcshareddata/
			IDEWorkspaceChecks.plist
			swiftpm/
				Package.resolved
		xcuserdata/
			abir49.xcuserdatad/
				UserInterfaceState.xcuserstate
			macos.xcuserdatad/
				UserInterfaceState.xcuserstate
	xcuserdata/
		abir49.xcuserdatad/
			xcdebugger/
				Breakpoints_v2.xcbkptlist
			xcschemes/
				xcschememanagement.plist
		macos.xcuserdatad/
			xcschemes/
				xcschememanagement.plist
BusTicketBookingTests/
	BusTicketBookingTests.swift
BusTicketBookingUITests/
	BusTicketBookingUITests.swift
	BusTicketBookingUITestsLaunchTests.swift
```

## 15) Complete File-by-File Reference

### Root

- `README.md`: Project documentation.

### `BusTicketBooking/` app module

- `BusTicketBooking.entitlements`: Main entitlements config.
- `BusTicketBooking.entitlements.xml`: XML-format entitlements variant.
- `BusTicketBooking.entitlements(1).xml`: Additional entitlements variant/duplicate.
- `BusTicketBookingApp.swift`: App entry point and Firebase initialization.
- `ContentView.swift`: Root routing view (splash + auth-based navigation + color scheme).
- `GoogleService-Info.plist`: Firebase app credentials/config for iOS target.
- `MainTabView.swift`: Main user tab container (Home/Offers/Tickets/Profile).

### `BusTicketBooking/Assets.xcassets`

- `Assets.xcassets/Contents.json`: Asset catalog root metadata.
- `Assets.xcassets/AccentColor.colorset/Contents.json`: Accent color metadata.
- `Assets.xcassets/AppIcon.appiconset/Contents.json`: App icon metadata.

### `BusTicketBooking/Components`

- `Components/BannerView.swift`: Home banner/promo UI component.
- `Components/BusCardView.swift`: Reusable bus card row with pricing and metadata.
- `Components/DistrictAutocompleteField.swift`: Text input with district suggestions.
- `Components/DistrictPickerView.swift`: Picker-style district selector.
- `Components/RouteCardView.swift`: Route card for popular route section.
- `Components/SeatLayoutPDFView.swift`: Seat layout visual used for ticket PDF rendering.
- `Components/ShareSheet.swift`: UIKit share sheet bridge for SwiftUI.
- `Components/Theme.swift`: Centralized colors and shared style constants.

### `BusTicketBooking/Models`

- `Models/Booking.swift`: Booking domain model + booking confirmation struct.
- `Models/BusTrip.swift`: Trip model, discount logic, seat matrix normalization, duration helpers.
- `Models/District.swift`: District and API decoding structures.
- `Models/Route.swift`: Route summary model (from, to, min price).
- `Models/SeatHelper.swift`: Seat mapping and matrix mutation/count helpers.
- `Models/UserModel.swift`: User profile + notification preference model.

### `BusTicketBooking/Preview Content`

- `Preview Content/Preview Assets.xcassets/Contents.json`: SwiftUI preview assets metadata.

### `BusTicketBooking/Utilities`

- `Utilities/DistrictService.swift`: District API fetch service with primary/fallback endpoints.
- `Utilities/TicketPDFGenerator.swift`: Two-page ticket PDF generation utility.

### `BusTicketBooking/ViewModels`

- `ViewModels/AdminViewModel.swift`: Admin CRUD/statistics/sold-ticket aggregation logic.
- `ViewModels/AuthViewModel.swift`: Authentication, profile fetch/update, password flows.
- `ViewModels/BookingViewModel.swift`: Booking creation, query fallback, cancellation.
- `ViewModels/BusTripViewModel.swift`: Trip search and offers loading.
- `ViewModels/RouteViewModel.swift`: Popular route derivation from trips.
- `ViewModels/SeedService.swift`: Reserved/no-op seed service.

### `BusTicketBooking/Views`

- `Views/AddBusView.swift`: Admin form to add buses and route points.
- `Views/AdminDashboardView.swift`: Admin tab shell + dashboard widgets.
- `Views/AdminProfileView.swift`: Admin profile and account controls.
- `Views/BookingConfirmationView.swift`: Booking preview + final commit + PDF actions.
- `Views/BusListView.swift`: Search results list.
- `Views/BusTripDetailView.swift`: Detailed trip screen.
- `Views/ChangePasswordView.swift`: Password change flow for signed-in user.
- `Views/ForgotPasswordView.swift`: Reset-password request screen.
- `Views/HomeView.swift`: Search form and popular routes UI.
- `Views/ManageBusesView.swift`: Admin bus listing and deletion.
- `Views/MoreView.swift`: Extra/support menu screen.
- `Views/NotificationPreferencesView.swift`: Notification toggle controls.
- `Views/OffersView.swift`: Discounted trips screen.
- `Views/ProfileView.swift`: User profile management and appearance toggle.
- `Views/SeatSelectionView.swift`: Interactive seat selection interface.
- `Views/SignInView.swift`: Login screen and verification resend.
- `Views/SignUpView.swift`: Registration and verification prompt flow.
- `Views/SoldTicketsView.swift`: Admin sold-ticket visibility screen.
- `Views/SplashScreenView.swift`: App intro/splash animation.
- `Views/TicketsView.swift`: User booking history and cancellation actions.

### `BusTicketBooking.xcodeproj`

- `BusTicketBooking.xcodeproj/project.pbxproj`: Xcode project definitions, targets, build settings.
- `BusTicketBooking.xcodeproj/project.xcworkspace/contents.xcworkspacedata`: Workspace metadata file.
- `BusTicketBooking.xcodeproj/project.xcworkspace/contents.xcworkspacedata.xml`: Workspace metadata variant.
- `BusTicketBooking.xcodeproj/project.xcworkspace/contents.xcworkspacedata(1).xml`: Workspace metadata duplicate variant.
- `BusTicketBooking.xcodeproj/project.xcworkspace/contents.xcworkspacedata(1)(1).xml`: Workspace metadata duplicate variant.
- `BusTicketBooking.xcodeproj/project.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist`: IDE workspace checks metadata.
- `BusTicketBooking.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`: Resolved Swift Package dependencies.
- `BusTicketBooking.xcodeproj/project.xcworkspace/xcuserdata/abir49.xcuserdatad/UserInterfaceState.xcuserstate`: User-local workspace UI state.
- `BusTicketBooking.xcodeproj/project.xcworkspace/xcuserdata/macos.xcuserdatad/UserInterfaceState.xcuserstate`: User-local workspace UI state.
- `BusTicketBooking.xcodeproj/xcuserdata/abir49.xcuserdatad/xcdebugger/Breakpoints_v2.xcbkptlist`: User breakpoint metadata.
- `BusTicketBooking.xcodeproj/xcuserdata/abir49.xcuserdatad/xcschemes/xcschememanagement.plist`: User-local scheme metadata.
- `BusTicketBooking.xcodeproj/xcuserdata/macos.xcuserdatad/xcschemes/xcschememanagement.plist`: User-local scheme metadata.

### Tests

- `BusTicketBookingTests/BusTicketBookingTests.swift`: Unit tests (including discount logic assertions).
- `BusTicketBookingUITests/BusTicketBookingUITests.swift`: Base UI test suite and launch performance test.
- `BusTicketBookingUITests/BusTicketBookingUITestsLaunchTests.swift`: Launch screenshot test.

## 16) Suggested Contribution Workflow

1. Create a feature branch.
2. Keep changes scoped by layer (Models/ViewModels/Views).
3. Add/extend tests when changing business logic.
4. Verify Firestore field compatibility before shipping.
5. Open pull request with screenshots for UI changes.

## 17) Current Status Snapshot

- App scaffolding and major functional flows are implemented.
- Firebase-backed auth and booking persistence are active.
- PDF ticket generation is integrated.
- Admin operations are available for bus management and sold-ticket oversight.
- Automated test coverage exists but is currently minimal and should be expanded.
