//
// 🦠 Corona-Warn-App
//

import Foundation

enum QRScannerError: Error, LocalizedError {

	case cameraPermissionDenied
	case codeNotFound
	case other
	case simulator

	var errorDescription: String? {
		switch self {
		case .cameraPermissionDenied:
			return AppStrings.ExposureSubmissionQRScanner.cameraPermissionDenied
		default:
			return AppStrings.ExposureSubmissionQRScanner.otherError
		}
	}

}
