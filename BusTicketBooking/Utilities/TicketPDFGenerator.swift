//
//  TicketPDFGenerator.swift
//  BusTicketBooking
//
//  Created by GitHub Copilot.
//

import UIKit
import SwiftUI

enum TicketPDFGenerator {
    @MainActor
    static func generatePDF(
        confirmation: BookingConfirmation,
        passengerName: String,
        passengerPhone: String
    ) throws -> URL {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let format = UIGraphicsPDFRendererFormat()
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let fileName = "Ticket-\(confirmation.id).pdf"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        try renderer.writePDF(to: fileURL) { context in
            context.beginPage()
            drawDetailsPage(
                in: context.cgContext,
                pageRect: pageRect,
                confirmation: confirmation,
                passengerName: passengerName,
                passengerPhone: passengerPhone
            )

            context.beginPage()
            drawSeatLayoutPage(
                in: context.cgContext,
                pageRect: pageRect,
                bookedSeatIndices: Set(confirmation.seatIndices)
            )
        }

        return fileURL
    }

    private static func drawDetailsPage(
        in context: CGContext,
        pageRect: CGRect,
        confirmation: BookingConfirmation,
        passengerName: String,
        passengerPhone: String
    ) {
        let margin: CGFloat = 36
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 22),
            .foregroundColor: UIColor.black
        ]
        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .medium),
            .foregroundColor: UIColor.darkGray
        ]
        let valueAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13, weight: .semibold),
            .foregroundColor: UIColor.black
        ]

        let titleRect = CGRect(x: margin, y: margin, width: pageRect.width - margin * 2, height: 30)
        NSString(string: "Ticket Details").draw(in: titleRect, withAttributes: titleAttributes)

        var y = titleRect.maxY + 18
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short


        y = drawDetailLine(label: "Booking ID", value: confirmation.id, y: y, pageRect: pageRect, labelAttributes: labelAttributes, valueAttributes: valueAttributes)
        y = drawDetailLine(label: "Route", value: "\(confirmation.trip.source) -> \(confirmation.trip.destination)", y: y, pageRect: pageRect, labelAttributes: labelAttributes, valueAttributes: valueAttributes)
        y = drawDetailLine(label: "Bus", value: confirmation.trip.busName, y: y, pageRect: pageRect, labelAttributes: labelAttributes, valueAttributes: valueAttributes)
        y = drawDetailLine(label: "Passenger", value: passengerName, y: y, pageRect: pageRect, labelAttributes: labelAttributes, valueAttributes: valueAttributes)
        y = drawDetailLine(label: "Phone", value: passengerPhone, y: y, pageRect: pageRect, labelAttributes: labelAttributes, valueAttributes: valueAttributes)
        y = drawDetailLine(label: "Departure", value: confirmation.trip.departureTime, y: y, pageRect: pageRect, labelAttributes: labelAttributes, valueAttributes: valueAttributes)
        y = drawDetailLine(label: "Seats", value: confirmation.seatLabels.joined(separator: ", "), y: y, pageRect: pageRect, labelAttributes: labelAttributes, valueAttributes: valueAttributes)
        y = drawDetailLine(label: "Booked", value: dateFormatter.string(from: confirmation.bookingDate), y: y, pageRect: pageRect, labelAttributes: labelAttributes, valueAttributes: valueAttributes)
        _ = drawDetailLine(label: "Total", value: "BDT \(confirmation.totalPrice)", y: y, pageRect: pageRect, labelAttributes: labelAttributes, valueAttributes: valueAttributes)
    }

    @MainActor
    private static func drawSeatLayoutPage(
        in context: CGContext,
        pageRect: CGRect,
        bookedSeatIndices: Set<Int>
    ) {
        let margin: CGFloat = 36
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 20),
            .foregroundColor: UIColor.black
        ]

        let titleRect = CGRect(x: margin, y: margin, width: pageRect.width - margin * 2, height: 26)
        NSString(string: "Seat Layout").draw(in: titleRect, withAttributes: titleAttributes)

        let availableHeight = pageRect.height - margin * 2 - 30
        let layoutWidth = pageRect.width - margin * 2
        let layoutSize = CGSize(width: layoutWidth, height: availableHeight)

        guard let layoutImage = seatLayoutImage(bookedSeatIndices: bookedSeatIndices, size: layoutSize) else {
            return
        }

        let imageRect = CGRect(
            x: margin,
            y: titleRect.maxY + 12,
            width: layoutSize.width,
            height: layoutSize.height
        )

        if let cgImage = layoutImage.cgImage {
            let flippedRect = CGRect(
                x: imageRect.minX,
                y: pageRect.height - imageRect.maxY,
                width: imageRect.width,
                height: imageRect.height
            )
            context.saveGState()
            context.draw(cgImage, in: flippedRect)
            context.restoreGState()
        } else {
            layoutImage.draw(in: imageRect)
        }
    }

    private static func drawDetailLine(
        label: String,
        value: String,
        y: CGFloat,
        pageRect: CGRect,
        labelAttributes: [NSAttributedString.Key: Any],
        valueAttributes: [NSAttributedString.Key: Any]
    ) -> CGFloat {
        let margin: CGFloat = 36
        let labelWidth: CGFloat = 120
        let maxValueWidth = pageRect.width - margin * 2 - labelWidth - 8

        let labelRect = CGRect(x: margin, y: y, width: labelWidth, height: 20)
        NSString(string: label).draw(in: labelRect, withAttributes: labelAttributes)

        let valueRect = CGRect(x: margin + labelWidth + 8, y: y, width: maxValueWidth, height: 200)
        let valueHeight = NSString(string: value).boundingRect(
            with: CGSize(width: maxValueWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: valueAttributes,
            context: nil
        ).height

        let height = max(20, ceil(valueHeight))
        let drawRect = CGRect(x: valueRect.minX, y: y, width: maxValueWidth, height: height)
        NSString(string: value).draw(in: drawRect, withAttributes: valueAttributes)

        return y + height + 10
    }

    @MainActor
    private static func seatLayoutImage(bookedSeatIndices: Set<Int>, size: CGSize) -> UIImage? {
        let view = SeatLayoutPDFView(bookedSeatIndices: bookedSeatIndices)
            .frame(width: size.width, height: size.height)

        if #available(iOS 16.0, *) {
            let renderer = ImageRenderer(content: view)
            renderer.scale = UIScreen.main.scale
            return renderer.uiImage
        }

        let host = UIHostingController(rootView: view)
        host.view.bounds = CGRect(origin: .zero, size: size)
        host.view.backgroundColor = .white

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            host.view.drawHierarchy(in: host.view.bounds, afterScreenUpdates: true)
        }
    }
}
