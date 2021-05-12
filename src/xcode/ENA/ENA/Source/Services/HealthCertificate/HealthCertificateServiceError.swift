////
// 🦠 Corona-Warn-App
//

import Foundation
import HealthCertificateToolkit

enum HealthCertificateServiceError {

	enum RegistrationError: LocalizedError {
		case decodingError(CertificateDecodingError)
		case noVaccinationEntry
		case vaccinationCertificateAlreadyRegistered
		case dateOfBirthMismatch
		case nameMismatch
		case proofRequestError(ProofRequestError)
		case other(Error)
	}

	enum ProofRequestError: LocalizedError {
		case fetchingError(ProofCertificateFetchingError)
		case decodingError(CertificateDecodingError)
		case other(Error)
	}

}
