//
//  Theme.swift
//  MyWes
//

import SwiftUI

enum Theme {
    // MARK: - Colors (OKLCH → approximate sRGB)

    static let background = Color.white
    static let ink = Color(red: 0.18, green: 0.16, blue: 0.15)
    static let secondaryText = Color(red: 0.42, green: 0.40, blue: 0.38)
    static let border = Color(red: 0.88, green: 0.87, blue: 0.86)
    static let cardinal = Color(red: 0.72, green: 0.22, blue: 0.20)
    static let cardinalPressed = Color(red: 0.55, green: 0.16, blue: 0.14)
    static let blueAccent = Color(red: 0.28, green: 0.42, blue: 0.72)
    static let success = Color(red: 0.22, green: 0.55, blue: 0.35)
    static let splashDark = Color(red: 0.12, green: 0.11, blue: 0.10)
    static let splashMuted = Color(red: 0.55, green: 0.53, blue: 0.51)
    static let splashTagline = Color(red: 0.70, green: 0.68, blue: 0.66)
    static let savedBannerBackground = Color(red: 0.96, green: 0.91, blue: 0.90)
    static let discoverCardMuted = Color(red: 0.78, green: 0.76, blue: 0.74)

    // MARK: - Spacing

    static let screenPadding: CGFloat = 20
    static let listGap: CGFloat = 8
    static let sectionGap: CGFloat = 16
    static let cardPadding: CGFloat = 12

    // MARK: - Radii

    static let buttonRadius: CGFloat = 14
    static let fieldRadius: CGFloat = 12
    static let cardRadius: CGFloat = 14
    static let chipRadius: CGFloat = 14
    static let logoRadiusLarge: CGFloat = 22
    static let logoRadiusMedium: CGFloat = 16
}

enum Typography {
    static let displayLarge = Font.system(size: 38, weight: .heavy)
    static let headlineLarge = Font.system(size: 28, weight: .heavy)
    static let headlineMedium = Font.system(size: 24, weight: .heavy)
    static let sectionTitle = Font.system(size: 18, weight: .heavy)
    static let body = Font.system(size: 15, weight: .regular)
    static let bodyEmphasized = Font.system(size: 15, weight: .semibold)
    static let bodySmall = Font.system(size: 13.5, weight: .regular)
    static let caption = Font.system(size: 12, weight: .regular)
    static let captionEmphasized = Font.system(size: 11.5, weight: .regular)
    static let label = Font.system(size: 13, weight: .semibold)
    static let eyebrow = Font.system(size: 12, weight: .bold)
    static let button = Font.system(size: 16, weight: .bold)
}
