////
// 🦠 Corona-Warn-App
//

import XCTest

/// Indicator for CI-triggered tests. If `false` you are running it most likely locally.
var isCI: Bool {
	return ProcessInfo.processInfo.environment["CI"] == "YES"
}

class CWATestCase: XCTestCase {

	override func setUpWithError() throws {
		try super.setUpWithError()

		continueAfterFailure = false

		// swiftlint:disable:next force_unwrapping
		try XCTSkipIf(testRun!.totalFailureCount > 0, "Fast fail ☠️")
	}

	override func tearDownWithError() throws {
		try super.tearDownWithError()

		// swiftlint:disable:next force_unwrapping
		if /*isCI,*/ testRun!.totalFailureCount > 0 {
			let pid = ProcessInfo.processInfo.processIdentifier
			try "\(pid)".write(toFile: "/Users/distiller/project/.fail", atomically: true, encoding: .utf8)
		}
	}

}
