//
//  AdminViewModel.swift
//  BusTicketBooking
//

import Foundation
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore

@MainActor
class AdminViewModel: ObservableObject {
    @Published var busTrips: [BusTrip] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var totalBookings: Int = 0
    @Published var totalUsers: Int = 0
    @Published var totalOperators: Int = 0
    @Published var soldTickets: [SoldTicketRecord] = []
    @Published var operatorAccounts: [OperatorAccountSummary] = []
    @Published var revenueOverview: RevenueOverview = .empty()

    private let db = Firestore.firestore()
    private let operatorCreationAppName = "BusTicketBookingOperatorCreation"

    struct SoldTicketRecord: Identifiable {
        let id: String
        let userName: String
        let userEmail: String
        let userPhone: String
        let busName: String
        let route: String
        let travelDate: Date
        let bookingDate: Date
        let seatLabels: [String]
        let totalPrice: Int
    }

    struct OperatorAccountSummary: Identifiable {
        let id: String
        let fullName: String
        let email: String
        let createdAt: Date
        let busCount: Int
        let bookingCount: Int
        let revenue: Int
    }

    struct RevenueOverview {
        let totalRevenue: Int
        let todayRevenue: Int
        let totalBookings: Int
        let totalBuses: Int
        let totalRoutes: Int
        let dailyBreakdown: [DailyRevenueRecord]
        let busBreakdown: [BusRevenueRecord]
        let recentTransactions: [RevenueTransaction]

        static func empty(totalBuses: Int = 0, totalRoutes: Int = 0) -> RevenueOverview {
            RevenueOverview(
                totalRevenue: 0,
                todayRevenue: 0,
                totalBookings: 0,
                totalBuses: totalBuses,
                totalRoutes: totalRoutes,
                dailyBreakdown: [],
                busBreakdown: [],
                recentTransactions: []
            )
        }
    }

    struct DailyRevenueRecord: Identifiable {
        let date: Date
        let revenue: Int
        let bookings: Int

        var id: String {
            Self.idFormatter.string(from: date)
        }

        private static let idFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.calendar = Calendar.current
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter
        }()
    }

    struct BusRevenueRecord: Identifiable {
        let id: String
        let busName: String
        let route: String
        let revenue: Int
        let bookings: Int
        let soldSeats: Int
        let operatorLabel: String?
    }

    struct RevenueTransaction: Identifiable {
        let id: String
        let busName: String
        let route: String
        let amount: Int
        let bookingDate: Date
        let travelDate: Date
        let seatLabels: [String]
    }

    private func decodeInt(_ value: Any?) -> Int? {
        switch value {
        case let intValue as Int:
            return intValue
        case let number as NSNumber:
            return number.intValue
        case let doubleValue as Double:
            return Int(doubleValue)
        case let stringValue as String:
            return Int(stringValue)
        default:
            return nil
        }
    }

    private func decodeTimeInterval(_ value: Any?) -> TimeInterval? {
        switch value {
        case let interval as TimeInterval:
            return interval
        case let timestamp as Timestamp:
            return timestamp.dateValue().timeIntervalSince1970
        case let number as NSNumber:
            return number.doubleValue
        case let stringValue as String:
            return TimeInterval(stringValue)
        default:
            return nil
        }
    }

    private func firestoreErrorMessage(_ error: Error, fallbackPrefix: String) -> String {
        let nsError = error as NSError
        let permissionCode = FirestoreErrorCode.permissionDenied.rawValue

        if nsError.domain == FirestoreErrorDomain, nsError.code == permissionCode {
            return "\(fallbackPrefix): Missing or insufficient permissions. Please update Firestore rules for admin and operator access."
        }

        return "\(fallbackPrefix): \(error.localizedDescription)"
    }

    private func routeCount(for trips: [BusTrip]) -> Int {
        Set(trips.map { "\($0.source)|\($0.destination)" }).count
    }

    private func formatOperatorName(from email: String) -> String {
        let localPart = email.components(separatedBy: "@").first ?? "Operator"
        let normalized = localPart
            .replacingOccurrences(of: ".", with: " ")
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return normalized.isEmpty ? "Bus Operator" : normalized.capitalized
    }

    private func operatorCreationAuth() throws -> Auth {
        if let existingApp = FirebaseApp.app(name: operatorCreationAppName) {
            return Auth.auth(app: existingApp)
        }

        guard let defaultApp = FirebaseApp.app() else {
            throw NSError(
                domain: "AdminViewModel",
                code: 1001,
                userInfo: [NSLocalizedDescriptionKey: "Firebase is not configured."]
            )
        }

        FirebaseApp.configure(name: operatorCreationAppName, options: defaultApp.options)

        guard let createdApp = FirebaseApp.app(name: operatorCreationAppName) else {
            throw NSError(
                domain: "AdminViewModel",
                code: 1002,
                userInfo: [NSLocalizedDescriptionKey: "Unable to prepare operator account manager."]
            )
        }

        return Auth.auth(app: createdApp)
    }

    private func loadTrips(for profile: UserProfile?) async throws -> [BusTrip] {
        var query: Query = db.collection("busTrips")

        if let profile, profile.isOperator {
            query = query.whereField("operatorId", isEqualTo: profile.id)
        }

        let snapshot = try await query.getDocuments()
        return snapshot.documents.compactMap {
            BusTrip(documentID: $0.documentID, data: $0.data())
        }.sorted { lhs, rhs in
            if lhs.busName == rhs.busName {
                return lhs.source < rhs.source
            }
            return lhs.busName < rhs.busName
        }
    }

    private func loadRevenueBookingDocuments(
        for trips: [BusTrip],
        profile: UserProfile?
    ) async throws -> [QueryDocumentSnapshot] {
        if let profile, profile.isOperator {
            let snapshot = try await db.collection("bookings")
                .whereField("operatorId", isEqualTo: profile.id)
                .getDocuments()
            return snapshot.documents
        }

        let snapshot = try await db.collection("bookings")
            .whereField("status", isEqualTo: "confirmed")
            .getDocuments()
        return snapshot.documents
    }

    private func buildRevenueOverview(
        for trips: [BusTrip],
        profile: UserProfile?
    ) async throws -> RevenueOverview {
        let totalRoutes = routeCount(for: trips)
        guard !trips.isEmpty else {
            return .empty(totalBuses: 0, totalRoutes: 0)
        }

        let tripMap = Dictionary(uniqueKeysWithValues: trips.map { ($0.id, $0) })
        let bookingDocuments = try await loadRevenueBookingDocuments(
            for: trips,
            profile: profile
        )

        var totalRevenue = 0
        var todayRevenue = 0
        var totalBookings = 0
        var dailyAggregation: [Date: (revenue: Int, bookings: Int)] = [:]
        var busAggregation: [String: (trip: BusTrip, revenue: Int, bookings: Int, soldSeats: Int)] = [:]
        var recentTransactions: [RevenueTransaction] = []

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        for trip in trips {
            busAggregation[trip.id] = (trip, 0, 0, 0)
        }

        for document in bookingDocuments {
            let data = document.data()
            guard
                (data["status"] as? String ?? "confirmed") == "confirmed",
                let busTripId = data["busTripId"] as? String,
                let trip = tripMap[busTripId]
            else {
                continue
            }

            let amount = decodeInt(data["totalPrice"]) ?? 0
            let bookingTimestamp = decodeTimeInterval(data["bookingDate"]) ?? Date().timeIntervalSince1970
            let travelTimestamp = decodeTimeInterval(data["travelDate"]) ?? bookingTimestamp
            let bookingDate = Date(timeIntervalSince1970: bookingTimestamp)
            let travelDate = Date(timeIntervalSince1970: travelTimestamp)
            let bookingDay = calendar.startOfDay(for: bookingDate)
            let seatLabels = data["seatLabels"] as? [String] ?? []

            totalRevenue += amount
            totalBookings += 1

            if bookingDay == today {
                todayRevenue += amount
            }

            let existingDaily = dailyAggregation[bookingDay] ?? (0, 0)
            dailyAggregation[bookingDay] = (
                revenue: existingDaily.revenue + amount,
                bookings: existingDaily.bookings + 1
            )

            let existingBus = busAggregation[trip.id] ?? (trip, 0, 0, 0)
            busAggregation[trip.id] = (
                trip: trip,
                revenue: existingBus.revenue + amount,
                bookings: existingBus.bookings + 1,
                soldSeats: existingBus.soldSeats + seatLabels.count
            )

            recentTransactions.append(
                RevenueTransaction(
                    id: document.documentID,
                    busName: trip.busName,
                    route: "\(trip.source) → \(trip.destination)",
                    amount: amount,
                    bookingDate: bookingDate,
                    travelDate: travelDate,
                    seatLabels: seatLabels
                )
            )
        }

        let dailyBreakdown = dailyAggregation.map { key, value in
            DailyRevenueRecord(date: key, revenue: value.revenue, bookings: value.bookings)
        }.sorted { $0.date > $1.date }

        let busBreakdown = busAggregation.values.map { item in
            BusRevenueRecord(
                id: item.trip.id,
                busName: item.trip.busName,
                route: "\(item.trip.source) → \(item.trip.destination)",
                revenue: item.revenue,
                bookings: item.bookings,
                soldSeats: item.soldSeats,
                operatorLabel: item.trip.operatorDisplayName
            )
        }.sorted { lhs, rhs in
            if lhs.revenue == rhs.revenue {
                return lhs.busName < rhs.busName
            }
            return lhs.revenue > rhs.revenue
        }

        recentTransactions.sort { $0.bookingDate > $1.bookingDate }

        return RevenueOverview(
            totalRevenue: totalRevenue,
            todayRevenue: todayRevenue,
            totalBookings: totalBookings,
            totalBuses: trips.count,
            totalRoutes: totalRoutes,
            dailyBreakdown: dailyBreakdown,
            busBreakdown: busBreakdown,
            recentTransactions: Array(recentTransactions.prefix(8))
        )
    }

    // MARK: - Add Bus

    func addBus(
        busName: String,
        source: String,
        destination: String,
        departureTime: String,
        arrivalTime: String,
        ticketPrice: Int,
        discount: Int = 0,
        busType: String,
        pickupPoints: [String],
        droppingPoints: [String],
        createdBy profile: UserProfile? = nil
    ) async -> Bool {
        isLoading = true
        errorMessage = nil
        successMessage = nil

        let filteredPickup = pickupPoints.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        let filteredDropping = droppingPoints.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        let safeDiscount = min(max(discount, 0), 100)
        let now = Timestamp(date: Date())

        var data: [String: Any] = [
            "busName": busName,
            "source": source,
            "destination": destination,
            "departureTime": departureTime,
            "arrivalTime": arrivalTime,
            "ticketPrice": ticketPrice,
            "discount": safeDiscount,
            "busType": busType,
            "availableSeats": 40,
            "seatMatrix": String(repeating: "0", count: 40),
            "pickupPoints": filteredPickup,
            "droppingPoints": filteredDropping,
            "createdAt": now,
            "updatedAt": now
        ]

        if let profile, profile.isOperator {
            data["operatorId"] = profile.id
            data["operatorEmail"] = profile.email
            data["operatorName"] = profile.fullName
        }

        do {
            try await db.collection("busTrips").addDocument(data: data)
            successMessage = profile?.isOperator == true
                ? "Bus added to your operator fleet successfully."
                : "Bus added successfully!"
            isLoading = false
            await fetchAllBuses(for: profile)
            return true
        } catch {
            errorMessage = "Failed to add bus: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }

    // MARK: - Fetch All Buses

    func fetchAllBuses(for profile: UserProfile? = nil) async {
        isLoading = true
        errorMessage = nil

        do {
            busTrips = try await loadTrips(for: profile)
            isLoading = false
        } catch {
            errorMessage = firestoreErrorMessage(error, fallbackPrefix: "Failed to load buses")
            isLoading = false
        }
    }

    func fetchAllBuses() async {
        await fetchAllBuses(for: nil)
    }

    // MARK: - Delete Bus

    func deleteBus(trip: BusTrip, currentUser: UserProfile?) async -> Bool {
        if currentUser?.isOperator == true, trip.operatorId != currentUser?.id {
            errorMessage = "You can only delete buses assigned to your operator account."
            return false
        }

        do {
            try await db.collection("busTrips").document(trip.id).delete()
            busTrips.removeAll { $0.id == trip.id }
            successMessage = "Bus deleted successfully."
            return true
        } catch {
            errorMessage = "Failed to delete: \(error.localizedDescription)"
            return false
        }
    }

    func deleteBus(id: String) async -> Bool {
        guard let trip = busTrips.first(where: { $0.id == id }) else {
            errorMessage = "Bus not found."
            return false
        }

        return await deleteBus(trip: trip, currentUser: nil)
    }

    // MARK: - Fetch Stats

    func fetchStats() async {
        do {
            let bookings = try await db.collection("bookings").getDocuments()
            totalBookings = bookings.documents.count

            let users = try await db.collection("users").getDocuments()
            totalUsers = users.documents.count
            totalOperators = users.documents.filter {
                ($0.data()["role"] as? String) == AppUserRole.operator.rawValue
            }.count
        } catch {
            // Stats are non-critical
        }
    }

    // MARK: - Create Operator

    func createOperatorAccount(email: String, password: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        successMessage = nil

        let normalizedEmail = email
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        let now = Date()

        do {
            let operatorAuth = try operatorCreationAuth()
            let result = try await operatorAuth.createUser(withEmail: normalizedEmail, password: password)
            let fullName = formatOperatorName(from: normalizedEmail)

            let profileData: [String: Any] = [
                "fullName": fullName,
                "email": normalizedEmail,
                "phone": "",
                "contactNo": "",
                "address": "",
                "role": AppUserRole.operator.rawValue,
                "notificationPreferences": NotificationPreferences().toDictionary(),
                "createdAt": Timestamp(date: now),
                "updatedAt": Timestamp(date: now),
                "requiresEmailVerification": false
            ]

            do {
                try await db.collection("users").document(result.user.uid).setData(profileData, merge: true)
            } catch {
                try? await result.user.delete()
                throw error
            }

            try operatorAuth.signOut()

            successMessage = "Bus operator account created successfully."
            await fetchOperatorAccounts()
            await fetchStats()
            isLoading = false
            return true
        } catch {
            errorMessage = "Failed to create operator: \(error.localizedDescription)"
            isLoading = false

            if let operatorAuth = try? operatorCreationAuth() {
                try? operatorAuth.signOut()
            }

            return false
        }
    }

    // MARK: - Operators

    func fetchOperatorAccounts() async {
        errorMessage = nil

        do {
            let operatorSnapshot = try await db.collection("users")
                .whereField("role", isEqualTo: AppUserRole.operator.rawValue)
                .getDocuments()

            let trips = try await loadTrips(for: nil)
            let tripMap = Dictionary(uniqueKeysWithValues: trips.map { ($0.id, $0) })
            let bookingSnapshot = try await db.collection("bookings")
                .whereField("status", isEqualTo: "confirmed")
                .getDocuments()

            var busesByOperator: [String: Int] = [:]
            for trip in trips {
                guard let operatorId = trip.operatorId else { continue }
                busesByOperator[operatorId, default: 0] += 1
            }

            var revenueByOperator: [String: Int] = [:]
            var bookingsByOperator: [String: Int] = [:]
            for document in bookingSnapshot.documents {
                let data = document.data()
                guard
                    let tripId = data["busTripId"] as? String,
                    let trip = tripMap[tripId],
                    let operatorId = trip.operatorId
                else {
                    continue
                }

                revenueByOperator[operatorId, default: 0] += decodeInt(data["totalPrice"]) ?? 0
                bookingsByOperator[operatorId, default: 0] += 1
            }

            operatorAccounts = operatorSnapshot.documents.map { document in
                let data = document.data()
                let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date.distantPast

                return OperatorAccountSummary(
                    id: document.documentID,
                    fullName: data["fullName"] as? String ?? formatOperatorName(from: data["email"] as? String ?? ""),
                    email: data["email"] as? String ?? "",
                    createdAt: createdAt,
                    busCount: busesByOperator[document.documentID, default: 0],
                    bookingCount: bookingsByOperator[document.documentID, default: 0],
                    revenue: revenueByOperator[document.documentID, default: 0]
                )
            }.sorted { lhs, rhs in
                if lhs.createdAt == rhs.createdAt {
                    return lhs.email < rhs.email
                }
                return lhs.createdAt > rhs.createdAt
            }

            totalOperators = operatorAccounts.count
        } catch {
            errorMessage = firestoreErrorMessage(error, fallbackPrefix: "Failed to load operators")
        }
    }

    // MARK: - Revenue

    func fetchRevenueOverview(for profile: UserProfile?) async {
        isLoading = true
        errorMessage = nil

        do {
            let trips = try await loadTrips(for: profile)
            revenueOverview = try await buildRevenueOverview(for: trips, profile: profile)
            isLoading = false
        } catch {
            errorMessage = firestoreErrorMessage(error, fallbackPrefix: "Failed to load revenue")
            revenueOverview = .empty()
            isLoading = false
        }
    }

    // MARK: - Sold Tickets

    func fetchSoldTickets() async {
        isLoading = true
        errorMessage = nil

        do {
            let bookingsSnapshot = try await db.collection("bookings")
                .whereField("status", isEqualTo: "confirmed")
                .getDocuments()

            var records: [SoldTicketRecord] = []

            for bookingDoc in bookingsSnapshot.documents {
                let data = bookingDoc.data()
                guard
                    let userId = data["userId"] as? String,
                    let busTripId = data["busTripId"] as? String
                else {
                    continue
                }

                let userSnapshot = try await db.collection("users").document(userId).getDocument()
                let tripSnapshot = try await db.collection("busTrips").document(busTripId).getDocument()

                let userData = userSnapshot.data() ?? [:]
                let tripData = tripSnapshot.data() ?? [:]

                let userName = userData["fullName"] as? String ?? "Unknown User"
                let userEmail = userData["email"] as? String ?? ""
                let userPhone = (userData["phone"] as? String).flatMap { $0.isEmpty ? nil : $0 }
                    ?? userData["contactNo"] as? String
                    ?? "Not provided"

                let busName = tripData["busName"] as? String ?? "Unknown Bus"
                let source = tripData["source"] as? String ?? ""
                let destination = tripData["destination"] as? String ?? ""

                let bookingTimestamp = decodeTimeInterval(data["bookingDate"]) ?? Date().timeIntervalSince1970
                let travelTimestamp = decodeTimeInterval(data["travelDate"]) ?? bookingTimestamp
                let seatLabels = data["seatLabels"] as? [String] ?? []
                let totalPrice = decodeInt(data["totalPrice"]) ?? 0

                records.append(
                    SoldTicketRecord(
                        id: bookingDoc.documentID,
                        userName: userName,
                        userEmail: userEmail,
                        userPhone: userPhone,
                        busName: busName,
                        route: "\(source) → \(destination)",
                        travelDate: Date(timeIntervalSince1970: travelTimestamp),
                        bookingDate: Date(timeIntervalSince1970: bookingTimestamp),
                        seatLabels: seatLabels,
                        totalPrice: totalPrice
                    )
                )
            }

            soldTickets = records.sorted { $0.bookingDate > $1.bookingDate }
            isLoading = false
        } catch {
            errorMessage = firestoreErrorMessage(error, fallbackPrefix: "Failed to load sold tickets")
            isLoading = false
        }
    }

    // MARK: - Firestore Cleanup / Reseed

    func cleanupAndReseedIfNeeded() async {
        isLoading = true
        errorMessage = nil
        successMessage = nil

        var updatedBusTrips = 0
        var updatedBookings = 0
        var seededBuses = 0

        do {
            let busTripsSnapshot = try await db.collection("busTrips").getDocuments()
            let busTripDataById = Dictionary(
                uniqueKeysWithValues: busTripsSnapshot.documents.map { ($0.documentID, $0.data()) }
            )

            for document in busTripsSnapshot.documents {
                let data = document.data()
                var patch: [String: Any] = [:]

                let rawMatrix = (data["seatMatrix"] as? String) ?? String(repeating: "0", count: 40)
                let cleanedMatrix = rawMatrix.filter { $0 == "0" || $0 == "1" }
                let normalizedMatrix = String((cleanedMatrix + String(repeating: "0", count: 40)).prefix(40))
                let normalizedAvailableSeats = SeatHelper.countAvailableSeats(in: normalizedMatrix)

                if data["seatMatrix"] as? String != normalizedMatrix {
                    patch["seatMatrix"] = normalizedMatrix
                }

                if decodeInt(data["availableSeats"]) != normalizedAvailableSeats {
                    patch["availableSeats"] = normalizedAvailableSeats
                }

                let discount = min(max(decodeInt(data["discount"]) ?? 0, 0), 100)
                if decodeInt(data["discount"]) != discount {
                    patch["discount"] = discount
                }

                if data["updatedAt"] == nil {
                    patch["updatedAt"] = Timestamp(date: Date())
                }

                if !patch.isEmpty {
                    try await db.collection("busTrips").document(document.documentID).setData(patch, merge: true)
                    updatedBusTrips += 1
                }
            }

            if busTripsSnapshot.documents.isEmpty {
                let sampleBuses: [[String: Any]] = [
                    [
                        "busName": "Green Line Express",
                        "source": "Dhaka",
                        "destination": "Chattogram",
                        "departureTime": "09:00 AM",
                        "arrivalTime": "03:00 PM",
                        "ticketPrice": 1200,
                        "discount": 10,
                        "busType": "AC",
                        "availableSeats": 40,
                        "seatMatrix": String(repeating: "0", count: 40),
                        "pickupPoints": ["Gabtoli", "Sayedabad"],
                        "droppingPoints": ["AK Khan", "GEC"],
                        "createdAt": Timestamp(date: Date()),
                        "updatedAt": Timestamp(date: Date())
                    ],
                    [
                        "busName": "Shyamoli Paribahan",
                        "source": "Dhaka",
                        "destination": "Khulna",
                        "departureTime": "08:30 AM",
                        "arrivalTime": "02:30 PM",
                        "ticketPrice": 900,
                        "discount": 0,
                        "busType": "Non-AC",
                        "availableSeats": 40,
                        "seatMatrix": String(repeating: "0", count: 40),
                        "pickupPoints": ["Gabtoli"],
                        "droppingPoints": ["Sonadanga"],
                        "createdAt": Timestamp(date: Date()),
                        "updatedAt": Timestamp(date: Date())
                    ]
                ]

                for bus in sampleBuses {
                    try await db.collection("busTrips").addDocument(data: bus)
                    seededBuses += 1
                }
            }

            let bookingsSnapshot = try await db.collection("bookings").getDocuments()

            for document in bookingsSnapshot.documents {
                let data = document.data()
                var patch: [String: Any] = [:]

                if data["status"] as? String == nil {
                    patch["status"] = "confirmed"
                }

                if decodeTimeInterval(data["travelDate"]) == nil {
                    if let bookingTime = decodeTimeInterval(data["bookingDate"]) {
                        patch["travelDate"] = bookingTime
                    }
                }

                if
                    let busTripId = data["busTripId"] as? String,
                    let tripData = busTripDataById[busTripId]
                {
                    if data["operatorId"] == nil, let operatorId = tripData["operatorId"] as? String {
                        patch["operatorId"] = operatorId
                    }

                    if data["operatorEmail"] == nil, let operatorEmail = tripData["operatorEmail"] as? String {
                        patch["operatorEmail"] = operatorEmail
                    }

                    if data["operatorName"] == nil, let operatorName = tripData["operatorName"] as? String {
                        patch["operatorName"] = operatorName
                    }
                }

                if !patch.isEmpty {
                    try await db.collection("bookings").document(document.documentID).setData(patch, merge: true)
                    updatedBookings += 1
                }
            }

            await fetchAllBuses()
            let seededMessage = seededBuses > 0 ? ", seeded \(seededBuses) sample buses" : ""
            successMessage = "Cleanup complete: updated \(updatedBusTrips) bus trips, \(updatedBookings) bookings\(seededMessage)."
            isLoading = false
        } catch {
            errorMessage = "Cleanup failed: \(error.localizedDescription)"
            isLoading = false
        }
    }
}
