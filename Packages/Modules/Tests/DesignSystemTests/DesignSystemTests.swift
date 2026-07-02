import SwiftUI
import UIKit
import XCTest
@testable import DesignSystem

final class DesignSystemTests: XCTestCase {
    func test_colorHex_parsesChannels() {
        let color = Color(hex: 0x3B82F6)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        XCTAssertEqual(red, 0x3B / 255, accuracy: 0.01)
        XCTAssertEqual(green, 0x82 / 255, accuracy: 0.01)
        XCTAssertEqual(blue, 0xF6 / 255, accuracy: 0.01)
        XCTAssertEqual(alpha, 1, accuracy: 0.01)
    }

    func test_colorHex_appliesOpacity() {
        var alpha: CGFloat = 0
        UIColor(Color(hex: 0x000000, opacity: 0.3)).getRed(nil, green: nil, blue: nil, alpha: &alpha)
        XCTAssertEqual(alpha, 0.3, accuracy: 0.01)
    }

    func test_accessibleDuration_formatsSpokenText() {
        XCTAssertEqual(DurationBadge.accessibleDuration(seconds: 4125), "1 hour 8 minutes")
        XCTAssertEqual(DurationBadge.accessibleDuration(seconds: 3600), "1 hour")
        XCTAssertEqual(DurationBadge.accessibleDuration(seconds: 3500), "58 minutes")
        XCTAssertEqual(DurationBadge.accessibleDuration(seconds: 60), "1 minute")
        XCTAssertEqual(DurationBadge.accessibleDuration(seconds: 45), "45 seconds")
        XCTAssertEqual(DurationBadge.accessibleDuration(seconds: 1), "1 second")
        XCTAssertEqual(DurationBadge.accessibleDuration(seconds: 0), "0 seconds")
    }
}
