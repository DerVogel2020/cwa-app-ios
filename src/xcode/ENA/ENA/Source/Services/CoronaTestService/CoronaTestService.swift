////
// 🦠 Corona-Warn-App
//

import Foundation
import OpenCombine

enum CoronaTestServiceError: Error {
	case responseFailure(URLSession.Response.Failure)
}

protocol CoronaTestServiceProviding {

	typealias VoidResultHandler = (Result<Void, CoronaTestServiceError>) -> Void
	typealias RegistrationResultHandler = (Result<String, CoronaTestServiceError>) -> Void
	typealias SubmissionTANResultHandler = (Result<String, CoronaTestServiceError>) -> Void

	var pcrTestPublisher: OpenCombine.CurrentValueSubject<PCRTest?, Never> { get }
	var antigenTestPublisher: OpenCombine.CurrentValueSubject<AntigenTest?, Never> { get }

	func registerPCRTest(guid: String, submissionConsentGiven: Bool, completion: @escaping VoidResultHandler)
	func registerPCRTest(teleTAN: String, submissionConsentGiven: Bool, completion: @escaping VoidResultHandler)

	func registerAntigenTest(
		with guid: String,
		pointOfCareConsentTimestamp: Date,
		name: String?,
		birthday: String?,
		submissionConsentGiven: Bool,
		completion: @escaping VoidResultHandler
	)

	func updateTestResult(for coronaTest: CoronaTest, completion: @escaping VoidResultHandler)

	func getSubmissionTAN(for coronaTest: CoronaTest, completion: @escaping SubmissionTANResultHandler)

	func removeTest(_ coronaTest: CoronaTest)

}

class CoronaTestService: CoronaTestServiceProviding {

	// MARK: - Init

	init(
		client: Client,
		store: CoronaTestStoring
	) {
		self.client = client
		self.store = store

		self.fakeRequestService = FakeRequestService(client: client)
	}

	// MARK: - Protocol CoronaTestServiceProviding

	var pcrTestPublisher = OpenCombine.CurrentValueSubject<PCRTest?, Never>(nil)
	var antigenTestPublisher = OpenCombine.CurrentValueSubject<AntigenTest?, Never>(nil)

	func registerPCRTest(
		guid: String,
		submissionConsentGiven: Bool,
		completion: @escaping VoidResultHandler
	) {
		getRegistrationToken(
			forKey: ENAHasher.sha256(guid),
			withType: "GUID",
			completion: { [weak self] result in
				switch result {
				case .success(let registrationToken):
					self?.storePCRTest(withRegistrationToken: registrationToken, submissionConsentGiven: submissionConsentGiven)
					completion(.success(()))
				case .failure(let error):
					completion(.failure(error))
				}
			}
		)

		
	}

	func registerPCRTest(
		teleTAN: String,
		submissionConsentGiven: Bool,
		completion: @escaping VoidResultHandler
	) {
		getRegistrationToken(
			forKey: teleTAN,
			withType: "TELETAN",
			completion: { [weak self] result in
				switch result {
				case .success(let registrationToken):
					self?.storePCRTest(withRegistrationToken: registrationToken, submissionConsentGiven: submissionConsentGiven)
					completion(.success(()))
				case .failure(let error):
					completion(.failure(error))
				}
			}
		)
	}

	func registerAntigenTest(
		with guid: String,
		pointOfCareConsentTimestamp: Date,
		name: String?,
		birthday: String?,
		submissionConsentGiven: Bool,
		completion: @escaping VoidResultHandler
	) {
		getRegistrationToken(
			forKey: ENAHasher.sha256(guid),
			withType: "GUID", // tbd, tech spec missing
			completion: { [weak self] result in
				switch result {
				case .success(let registrationToken):
					self?.store.antigenTest = AntigenTest(
						registrationToken: registrationToken,
						testedPerson: TestedPerson(name: name, birthday: birthday),
						pointOfCareConsentTimestamp: pointOfCareConsentTimestamp,
						testResult: nil,
						submissionConsentGiven: submissionConsentGiven,
						submissionTAN: nil,
						keysSubmitted: false,
						journalEntryCreated: false
					)
					self?.updatePublishersFromStore()

					completion(.success(()))
				case .failure(let error):
					completion(.failure(error))
				}
			}
		)
	}

	func updateTestResult(for coronaTest: CoronaTest, completion: @escaping VoidResultHandler) {

	}

	func getSubmissionTAN(for coronaTest: CoronaTest, completion: @escaping SubmissionTANResultHandler) {
		if let submissionTAN = coronaTest.submissionTAN {
			completion(.success(submissionTAN))
			return
		}

		client.getTANForExposureSubmit(forDevice: coronaTest.registrationToken, isFake: false) { result in
			switch result {
			case let .failure(error):
				completion(.failure(.responseFailure(error)))
			case let .success(submissionTAN):
				switch coronaTest {
				case .pcr(let pcrTest):
					self.store.pcrTest = PCRTest(
						registrationToken: pcrTest.registrationToken,
						testRegistrationDate: pcrTest.testRegistrationDate,
						testResult: pcrTest.testResult,
						submissionConsentGiven: pcrTest.submissionConsentGiven,
						submissionTAN: submissionTAN,
						keysSubmitted: pcrTest.keysSubmitted,
						journalEntryCreated: pcrTest.journalEntryCreated
					)

				case .antigen(let antigenTest):
					self.store.antigenTest = AntigenTest(
						registrationToken: antigenTest.registrationToken,
						testedPerson: antigenTest.testedPerson,
						pointOfCareConsentTimestamp: antigenTest.pointOfCareConsentTimestamp,
						testResult: antigenTest.testResult,
						submissionConsentGiven: antigenTest.submissionConsentGiven,
						submissionTAN: submissionTAN,
						keysSubmitted: antigenTest.keysSubmitted,
						journalEntryCreated: antigenTest.journalEntryCreated
					)
				}

				self.updatePublishersFromStore()

				completion(.success(submissionTAN))
			}
		}
	}

	func removeTest(_ coronaTest: CoronaTest) {
		switch coronaTest {
		case .pcr:
			store.pcrTest = nil
		case .antigen:
			store.antigenTest = nil
		}

		updatePublishersFromStore()
	}

	// MARK: - Private

	private let client: Client
	private var store: CoronaTestStoring

	private let fakeRequestService: FakeRequestService

	private func updatePublishersFromStore() {
		if pcrTestPublisher.value != store.pcrTest {
			pcrTestPublisher.value = store.pcrTest
		}

		if antigenTestPublisher.value != store.antigenTest {
			antigenTestPublisher.value = store.antigenTest
		}
	}

	private func getRegistrationToken(
		forKey key: String,
		withType type: String,
		completion: @escaping RegistrationResultHandler
	) {
		client.getRegistrationToken(forKey: key, withType: type, isFake: false) { result in
			self.fakeRequestService.fakeVerificationAndSubmissionServerRequest()

			switch result {
			case let .failure(error):
				completion(.failure(.responseFailure(error)))
			case let .success(registrationToken):
				completion(.success(registrationToken))
			}
		}
	}

	private func storePCRTest(
		withRegistrationToken registrationToken: String,
		submissionConsentGiven: Bool
	) {
		self.store.pcrTest = PCRTest(
			registrationToken: registrationToken,
			testRegistrationDate: Date(),
			testResult: nil,
			submissionConsentGiven: submissionConsentGiven,
			submissionTAN: nil,
			keysSubmitted: false,
			journalEntryCreated: false
		)

		updatePublishersFromStore()
	}

}
