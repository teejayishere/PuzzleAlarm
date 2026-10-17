import SwiftUI
import UIKit
import XCTest
@testable import PuzzleAlarm

@MainActor
final class NativeAlarmSwitchTests: XCTestCase {
    func testRealNativeControlWiringRebindingReconciliationDisabledEventsAndTeardown() {
        var first = false, second = false, firstInputs = 0, secondInputs = 0
        let initial = Binding(get: { first }, set: { first = $0; firstInputs += 1 })
        let replacement = Binding(get: { second }, set: { second = $0; secondInputs += 1 })
        let coordinator = NativeAlarmSwitch.Coordinator(binding: initial)
        let control = NativeAlarmSwitch.makeControl(coordinator: coordinator)
        NativeAlarmSwitch.update(control, coordinator: coordinator, binding: initial,
            enabled: true, identifier: "test.native")
        XCTAssertFalse(control.isOn)
        XCTAssertTrue(control.isEnabled)
        XCTAssertEqual(control.accessibilityIdentifier, "test.native")
        XCTAssertEqual(control.accessibilityLabel, "Alarm enabled")
        control.setOn(true, animated: false)
        XCTAssertEqual(firstInputs, 0, "Reconciliation is not user input")
        control.sendActions(for: .valueChanged)
        XCTAssertTrue(first); XCTAssertEqual(firstInputs, 1)

        NativeAlarmSwitch.update(control, coordinator: coordinator, binding: replacement,
            enabled: true, identifier: "test.native")
        XCTAssertFalse(control.isOn)
        XCTAssertEqual(firstInputs, 1); XCTAssertEqual(secondInputs, 0)
        control.setOn(true, animated: false); control.sendActions(for: .valueChanged)
        XCTAssertTrue(second); XCTAssertEqual(secondInputs, 1)
        XCTAssertEqual(firstInputs, 1, "Reused control must use the current binding")

        NativeAlarmSwitch.update(control, coordinator: coordinator, binding: replacement,
            enabled: false, identifier: "test.native")
        XCTAssertFalse(control.isEnabled)
        control.setOn(false, animated: false); control.sendActions(for: .valueChanged)
        XCTAssertTrue(second); XCTAssertEqual(secondInputs, 1, "Late disabled events cannot change input")
        NativeAlarmSwitch.update(control, coordinator: coordinator, binding: replacement,
            enabled: true, identifier: "test.native")
        XCTAssertTrue(control.isOn)
        NativeAlarmSwitch.dismantleUIView(control, coordinator: coordinator)
        control.setOn(false, animated: false); control.sendActions(for: .valueChanged)
        XCTAssertTrue(second); XCTAssertEqual(secondInputs, 1)
    }
}
