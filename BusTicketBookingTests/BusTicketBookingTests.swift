//
//  BusTicketBookingTests.swift
//  BusTicketBookingTests
//
//  Created by macos on 26/2/26.
//

import XCTest
@testable import BusTicketBooking

final class BusTicketBookingTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }

    func testBusTripDiscountDefaultsToZero() throws {
        let data: [String: Any] = [
            "busName": "Test Coach",
            "source": "Dhaka",
            "destination": "Chattogram",
            "departureTime": "09:00 AM",
            "arrivalTime": "03:00 PM",
            "availableSeats": 40,
            "ticketPrice": 1000,
            "busType": "AC"
        ]

        let trip = try XCTUnwrap(BusTrip(documentID: "trip-1", data: data))
        XCTAssertEqual(trip.discount, 0)
        XCTAssertEqual(trip.discountedPrice, 1000)
        XCTAssertFalse(trip.hasDiscount)
    }

    func testBusTripDiscountCalculatesReducedFare() throws {
        let data: [String: Any] = [
            "busName": "Test Coach",
            "source": "Dhaka",
            "destination": "Khulna",
            "departureTime": "09:00 AM",
            "arrivalTime": "03:00 PM",
            "availableSeats": 40,
            "ticketPrice": 1000,
            "discount": 20,
            "busType": "AC"
        ]

        let trip = try XCTUnwrap(BusTrip(documentID: "trip-2", data: data))
        XCTAssertEqual(trip.discount, 20)
        XCTAssertEqual(trip.discountedPrice, 800)
        XCTAssertTrue(trip.hasDiscount)
    }

}
