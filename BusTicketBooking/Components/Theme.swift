//
//  Theme.swift
//  BusTicketBooking
//
//  Created by macos on 26/2/26.
//

import SwiftUI

struct Theme {
    static let primaryMaroon = Color(red: 128/255, green: 0/255, blue: 32/255)
    static let lightMaroon = Color(red: 160/255, green: 20/255, blue: 60/255)
    
    // Dark mode adaptive background
    static var background: Color {
        #if os(iOS)
        return Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 30/255, green: 30/255, blue: 30/255, alpha: 1.0)
                : UIColor(red: 245/255, green: 245/255, blue: 247/255, alpha: 1.0)
        })
        #else
        return Color(NSColor(name: nil, dynamicProvider: { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                ? NSColor(red: 30/255, green: 30/255, blue: 30/255, alpha: 1.0)
                : NSColor(red: 245/255, green: 245/255, blue: 247/255, alpha: 1.0)
        }))
        #endif
    }
    
    // Alias for clarity
    static var adaptiveBackground: Color { background }
    
    // Card / surface background
    static var cardBackground: Color {
        #if os(iOS)
        return Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor.secondarySystemBackground
                : UIColor.white
        })
        #else
        return Color(NSColor(name: nil, dynamicProvider: { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                ? NSColor(red: 44/255, green: 44/255, blue: 46/255, alpha: 1.0)
                : NSColor.white
        }))
        #endif
    }
}
