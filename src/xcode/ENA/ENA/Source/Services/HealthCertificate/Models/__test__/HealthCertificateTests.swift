////
// 🦠 Corona-Warn-App
//

import XCTest
@testable import ENA
import HealthCertificateToolkit

// swiftlint:disable file_length
class HealthCertificateTests: XCTestCase {
			
	func testGIVEN_Base45WellformedEncoded_WHEN_InitIsCalled_THEN_HealthCertificateIsCreated() throws {
		
		// GIVEN
		let dgcCertificate = DigitalCovidCertificate.fake()
		
		let result = DigitalCovidCertificateFake.makeBase45Fake(
			from: dgcCertificate,
			and: CBORWebTokenHeader.fake()
		)
		
		guard case let .success(base45) = result else {
			XCTFail("base45 should be created from a mock. Test fails now.")
			return
		}

		// WHEN
		let healthCertificate = try HealthCertificate(base45: base45)

		// THEN
		XCTAssertNotNil(healthCertificate)
	}
	
	func testGIVEN_Base45WrongCBORHeaderEncoded_WHEN_InitIsCalled_THEN_FailureIsReturned() throws {
		
		// GIVEN
		let dgcCertificate = DigitalCovidCertificate.fake()
		
		let result = DigitalCovidCertificateFake.makeBase45CorruptFake(
			from: dgcCertificate
		)
		
		guard case let .success(base45) = result else {
			XCTFail("base45 should be created from a mock. Test fails now.")
			return
		}
		
		let expectedError = CertificateDecodingError.HC_COSE_MESSAGE_INVALID

		// WHEN
		var healthCertificate: HealthCertificate?
		var error: CertificateDecodingError?
		do {
			healthCertificate = try HealthCertificate(base45: base45)
		} catch let err as CertificateDecodingError {
			error = err
		}
		
		// THEN
		XCTAssertNil(healthCertificate)
		XCTAssertEqual(error, expectedError)
	}
	
	func testGIVEN_Base45WrongDGCEncoded_WHEN_InitIsCalled_THEN_FailureIsReturned() throws {
		
		// GIVEN
		let dgcCertificate = DigitalCovidCertificate.fake(
			// 2 VaccinationEntries are not allowed.
			vaccinationEntries: [VaccinationEntry.fake(), VaccinationEntry.fake()]
		)
		
		let result = DigitalCovidCertificateFake.makeBase45Fake(
			from: dgcCertificate,
			and: CBORWebTokenHeader.fake()
		)
		
		guard case let .success(base45) = result else {
			XCTFail("base45 should be created from a mock. Test fails now.")
			return
		}

		// WHEN
		var healthCertificate: HealthCertificate?
		var error: CertificateDecodingError?
		do {
			healthCertificate = try HealthCertificate(base45: base45)
		} catch let err as CertificateDecodingError {
			error = err
		}
		
		// THEN
		XCTAssertNil(healthCertificate)
		XCTAssertNotNil(error)
	}
	
	func testGIVEN_TwoCertificates_WHEN_Compare1_THEN_CompareIsCorrect() throws {
		// GIVEN
		let dateOfVaccination1 = "2020-01-01"
		let dgcCertificate1 = DigitalCovidCertificate.fake(
			vaccinationEntries: [VaccinationEntry.fake(
				dateOfVaccination: dateOfVaccination1
			)]
		)
		
		let result1 = DigitalCovidCertificateFake.makeBase45Fake(
			from: dgcCertificate1,
			and: CBORWebTokenHeader.fake()
		)
		
		guard case let .success(base451) = result1 else {
			XCTFail("base45 should be created from a mock. Test fails now.")
			return
		}
		
		let dateOfVaccination2 = "2019-01-01"
		let dgcCertificate2 = DigitalCovidCertificate.fake(
			vaccinationEntries: [VaccinationEntry.fake(
				dateOfVaccination: dateOfVaccination2
			)]
		)
		
		let result2 = DigitalCovidCertificateFake.makeBase45Fake(
			from: dgcCertificate2,
			and: CBORWebTokenHeader.fake()
		)
		
		guard case let .success(base452) = result2 else {
			XCTFail("base45 should be created from a mock. Test fails now.")
			return
		}
		
		let certificate1 = try HealthCertificate(base45: base451)
		let certificate2 = try HealthCertificate(base45: base452)

		var compared = false
		
		// WHEN
		if certificate2 < certificate1 {
			compared = true
		}

		// THEN
		XCTAssertTrue(compared)
	}
	
	func testGIVEN_TwoCertificates_WHEN_Compare2_THEN_CompareIsCorrect() throws {
		// GIVEN
		let dateOfVaccination1 = "2020-01-01"
		let dgcCertificate1 = DigitalCovidCertificate.fake(
			vaccinationEntries: [VaccinationEntry.fake(
				dateOfVaccination: dateOfVaccination1
			)]
		)
		
		let result1 = DigitalCovidCertificateFake.makeBase45Fake(
			from: dgcCertificate1,
			and: CBORWebTokenHeader.fake()
		)
		
		guard case let .success(base451) = result1 else {
			XCTFail("base45 should be created from a mock. Test fails now.")
			return
		}
		
		let dateTimeOfSampleCollection = "2019-01-01"
		let dgcCertificate2 = DigitalCovidCertificate.fake(
			vaccinationEntries: [VaccinationEntry.fake(
				dateOfVaccination: dateTimeOfSampleCollection
			)]
		)
		
		let result2 = DigitalCovidCertificateFake.makeBase45Fake(
			from: dgcCertificate2,
			and: CBORWebTokenHeader.fake()
		)
		
		guard case let .success(base452) = result2 else {
			XCTFail("base45 should be created from a mock. Test fails now.")
			return
		}
		
		let certificate1 = try HealthCertificate(base45: base451)
		let certificate2 = try HealthCertificate(base45: base452)

		var compared = false
		
		// WHEN
		if certificate2 < certificate1 {
			compared = true
		}

		// THEN
		XCTAssertTrue(compared)
	}

	func testGIVEN_MultipleCertificates_WHEN_Sorting_THEN_OrderIsCorrect() throws {
		// GIVEN
		let vaccinationCertificateBase45 = try base45Fake(from: DigitalCovidCertificate.fake(
			vaccinationEntries: [VaccinationEntry.fake(
				dateOfVaccination: "2020-01-03"
			)]
		))

		let testCertificateBase45 = try base45Fake(from: DigitalCovidCertificate.fake(
			testEntries: [TestEntry.fake(
				dateTimeOfSampleCollection: "2020-01-02T12:00:00.000Z"
			)]
		))

		let recoveryCertificateBase45 = try base45Fake(from: DigitalCovidCertificate.fake(
			recoveryEntries: [RecoveryEntry.fake(
				certificateValidFrom: "2020-01-01"
			)]
		))

		let vaccinationCertificate = try HealthCertificate(base45: vaccinationCertificateBase45)
		let testCertificate = try HealthCertificate(base45: testCertificateBase45)
		let recoveryCertificate = try HealthCertificate(base45: recoveryCertificateBase45)
		let healthCertificates = [vaccinationCertificate, testCertificate, recoveryCertificate]

		// WHEN
		let sortedHealthCertificates = healthCertificates.sorted()

		// THEN
		XCTAssertEqual(sortedHealthCertificates, [recoveryCertificate, testCertificate, vaccinationCertificate])
	}
	
	func testGIVEN_DGCVersion_WHEN_CreateHealthCertificate_THEN_IsEqual() throws {
		
		// GIVEN
		
		let expectedVersion = "1.1.1"
		
		let dgcCertificate = DigitalCovidCertificate.fake(
			version: expectedVersion
		)
		
		let result = DigitalCovidCertificateFake.makeBase45Fake(
			from: dgcCertificate,
			and: CBORWebTokenHeader.fake()
		)
		
		guard case let .success(base45) = result else {
			XCTFail("base45 should be created from a mock. Test fails now.")
			return
		}
		
		// WHEN
		
		let healthCertificate = try HealthCertificate(base45: base45)
		
		// THEN
		
		XCTAssertEqual(healthCertificate.version, expectedVersion)
	}
	
	func testGIVEN_DGCName_WHEN_CreateHealthCertificate_THEN_IsEqual() throws {
		
		// GIVEN
		
		let expectedName = Name.fake()
		
		let dgcCertificate = DigitalCovidCertificate.fake(
			name: expectedName
		)
		
		let result = DigitalCovidCertificateFake.makeBase45Fake(
			from: dgcCertificate,
			and: CBORWebTokenHeader.fake()
		)
		
		guard case let .success(base45) = result else {
			XCTFail("base45 should be created from a mock. Test fails now.")
			return
		}
		
		// WHEN
		
		let healthCertificate = try HealthCertificate(base45: base45)
		
		// THEN
		
		XCTAssertEqual(healthCertificate.name, expectedName)
	}
	
	func testGIVEN_DGCDateOfBirth_WHEN_CreateHealthCertificate_THEN_IsEqual() throws {
		
		// GIVEN
		
		let expectedDoB = "2021-06-10"
		
		let dgcCertificate = DigitalCovidCertificate.fake(
			dateOfBirth: expectedDoB
		)
		
		let result = DigitalCovidCertificateFake.makeBase45Fake(
			from: dgcCertificate,
			and: CBORWebTokenHeader.fake()
		)
		
		guard case let .success(base45) = result else {
			XCTFail("base45 should be created from a mock. Test fails now.")
			return
		}
		
		// WHEN
		
		let healthCertificate = try HealthCertificate(base45: base45)
		
		// THEN
		
		XCTAssertEqual(healthCertificate.dateOfBirth, expectedDoB)
	}
	
	func testGIVEN_DGCDateOfBirthDate_WHEN_CreateHealthCertificate_THEN_IsEqual() throws {
		
		// GIVEN
		
		let dateOfBirth = "2021-06-10"
		let expectedDateOfBirthDate = ISO8601DateFormatter.justLocalDateFormatter.date(from: dateOfBirth)
		
		let dgcCertificate = DigitalCovidCertificate.fake(
			dateOfBirth: dateOfBirth
		)
		
		let result = DigitalCovidCertificateFake.makeBase45Fake(
			from: dgcCertificate,
			and: CBORWebTokenHeader.fake()
		)
		
		guard case let .success(base45) = result else {
			XCTFail("base45 should be created from a mock. Test fails now.")
			return
		}
		
		// WHEN
		
		let healthCertificate = try HealthCertificate(base45: base45)
		
		// THEN
		
		XCTAssertEqual(healthCertificate.dateOfBirthDate, expectedDateOfBirthDate)
	}
	
	func testGIVEN_DGCUniqeCertificateIdentifier_WHEN_CreateHealthCertificate_THEN_IsEqual() throws {
		
		// GIVEN
		
		let expectedUniqueCertificateIdentifier = "01DE/84503/1119349007/DXSGWLWL40SU8ZFKIYIBK39A3#S"
		
		let vaccinationEntry = VaccinationEntry.fake(
			uniqueCertificateIdentifier: expectedUniqueCertificateIdentifier
		)
		
		let dgcCertificate = DigitalCovidCertificate.fake(
			vaccinationEntries: [vaccinationEntry]
		)
		
		let result = DigitalCovidCertificateFake.makeBase45Fake(
			from: dgcCertificate,
			and: CBORWebTokenHeader.fake()
		)
		
		guard case let .success(base45) = result else {
			XCTFail("base45 should be created from a mock. Test fails now.")
			return
		}
		
		// WHEN
		
		let healthCertificate = try HealthCertificate(base45: base45)
		
		// THEN
		
		XCTAssertEqual(healthCertificate.uniqueCertificateIdentifier, expectedUniqueCertificateIdentifier)
	}
	
	func testGIVEN_DGCTestEntry_WHEN_CreateHealthCertificate_THEN_IsEqual() throws {
		
		// GIVEN
			
		let testEntry = TestEntry.fake(
			testCenter: "Karben Bürgerzentrum"
		)
		
		let dgcCertificate = DigitalCovidCertificate.fake(
			testEntries: [testEntry]
		)
		
		let result = DigitalCovidCertificateFake.makeBase45Fake(
			from: dgcCertificate,
			and: CBORWebTokenHeader.fake()
		)
		
		guard case let .success(base45) = result else {
			XCTFail("base45 should be created from a mock. Test fails now.")
			return
		}
		
		// WHEN
		
		let healthCertificate = try HealthCertificate(base45: base45)
		
		// THEN
		
		XCTAssertEqual(healthCertificate.testEntry?.testCenter, "Karben Bürgerzentrum")
	}
	
	func testGIVEN_DGCTypeVaccination_WHEN_CreateHealthCertificate_THEN_IsEqual() throws {
		
		// GIVEN
			
		let expectedVaccinationEntry = VaccinationEntry.fake()
		
		let dgcCertificate = DigitalCovidCertificate.fake(
			vaccinationEntries: [expectedVaccinationEntry]
		)
		
		let result = DigitalCovidCertificateFake.makeBase45Fake(
			from: dgcCertificate,
			and: CBORWebTokenHeader.fake()
		)
		
		guard case let .success(base45) = result else {
			XCTFail("base45 should be created from a mock. Test fails now.")
			return
		}
		
		// WHEN
		
		let healthCertificate = try HealthCertificate(base45: base45)
		let entry = healthCertificate.entry
		
		// THEN
		
		guard case let .vaccination(vaccinationEntry) = entry else {
			XCTFail("This should only contain a vaccinationEntry, nothing else")
			return
		}
		
		XCTAssertEqual(vaccinationEntry, expectedVaccinationEntry)
	}
	
	func testGIVEN_DGCTypeTest_WHEN_CreateHealthCertificate_THEN_IsEqual() throws {
		
		// GIVEN
			
		let expectedTestEntry = TestEntry.fake()
		
		let dgcCertificate = DigitalCovidCertificate.fake(
			testEntries: [expectedTestEntry]
		)
		
		let result = DigitalCovidCertificateFake.makeBase45Fake(
			from: dgcCertificate,
			and: CBORWebTokenHeader.fake()
		)
		
		guard case let .success(base45) = result else {
			XCTFail("base45 should be created from a mock. Test fails now.")
			return
		}
		
		// WHEN
		
		let healthCertificate = try HealthCertificate(base45: base45)
		let entry = healthCertificate.entry
		
		// THEN
		
		guard case let .test(testEntry) = entry else {
			XCTFail("This should only contain a testEntry, nothing else")
			return
		}
		
		XCTAssertEqual(testEntry, expectedTestEntry)
	}
	
	func testGIVEN_DGCExpirationDate_WHEN_CreateHealthCertificate_THEN_IsEqual() throws {
		
		// GIVEN
			
		let expirationTime: Date = Date(timeIntervalSince1970: 0123456798)
		
		let dgcCertificate = DigitalCovidCertificate.fake()
		
		let result = DigitalCovidCertificateFake.makeBase45Fake(
			from: dgcCertificate,
			and: CBORWebTokenHeader.fake(
				expirationTime: expirationTime
			)
		)
		
		guard case let .success(base45) = result else {
			XCTFail("base45 should be created from a mock. Test fails now.")
			return
		}
		
		// WHEN
		
		let healthCertificate = try HealthCertificate(base45: base45)
		
		// THEN
	
		XCTAssertEqual(healthCertificate.expirationDate, expirationTime)
	}

	func testGIVEN_CertificatesWithOneEntry_WHEN_CheckingTooManyEntries_FalseIsReturned() throws {
		// GIVEN
		let vaccinationCertificateBase45 = try base45Fake(from: DigitalCovidCertificate.fake(
			vaccinationEntries: [VaccinationEntry.fake(
				dateOfVaccination: "2020-01-03"
			)]
		))

		let testCertificateBase45 = try base45Fake(from: DigitalCovidCertificate.fake(
			testEntries: [TestEntry.fake(
				dateTimeOfSampleCollection: "2020-01-02T12:00:00.000Z"
			)]
		))

		let recoveryCertificateBase45 = try base45Fake(from: DigitalCovidCertificate.fake(
			vaccinationEntries: [VaccinationEntry.fake(
				dateOfVaccination: "2020-01-01"
			)]
		))

		let vaccinationCertificate = try HealthCertificate(base45: vaccinationCertificateBase45)
		let testCertificate = try HealthCertificate(base45: testCertificateBase45)
		let recoveryCertificate = try HealthCertificate(base45: recoveryCertificateBase45)

		// WHEN / THEN
		XCTAssertFalse(vaccinationCertificate.hasTooManyEntries)
		XCTAssertFalse(testCertificate.hasTooManyEntries)
		XCTAssertFalse(recoveryCertificate.hasTooManyEntries)
	}

	func testGIVEN_CertificatesWithMultipleEntries_WHEN_CheckingTooManyEntries_TrueIsReturned() throws {
		// GIVEN
		let firstWrongCertificateBase45 = try base45Fake(from: DigitalCovidCertificate.fake(
			vaccinationEntries: [VaccinationEntry.fake(
				dateOfVaccination: "2020-01-01"
			)],
			testEntries: [TestEntry.fake(
				dateTimeOfSampleCollection: "2020-01-02T12:00:00.000Z"
			)],
			recoveryEntries: nil
		))

		let secondWrongCertificateBase45 = try base45Fake(from: DigitalCovidCertificate.fake(
			vaccinationEntries: [VaccinationEntry.fake(
				dateOfVaccination: "2020-01-01"
			)],
			testEntries: nil,
			recoveryEntries: [RecoveryEntry.fake(
				certificateValidFrom: "2020-01-01"
			)]
		))

		let thirdWrongCertificateBase45 = try base45Fake(from: DigitalCovidCertificate.fake(
			vaccinationEntries: nil,
			testEntries: [TestEntry.fake(
				dateTimeOfSampleCollection: "2020-01-02T12:00:00.000Z"
			)],
			recoveryEntries: [RecoveryEntry.fake(
				certificateValidFrom: "2020-01-01"
			)]
		))

		let fourthWrongCertificateBase45 = try base45Fake(from: DigitalCovidCertificate.fake(
			vaccinationEntries: [VaccinationEntry.fake(
				dateOfVaccination: "2020-01-01"
			)],
			testEntries: [TestEntry.fake(
				dateTimeOfSampleCollection: "2020-01-02T12:00:00.000Z"
			)],
			recoveryEntries: [RecoveryEntry.fake(
				certificateValidFrom: "2020-01-01"
			)]
		))

		let fifthWrongCertificateBase45 = try base45Fake(from: DigitalCovidCertificate.fake(
			vaccinationEntries: [
				VaccinationEntry.fake(
					dateOfVaccination: "2020-01-01"
				),
				VaccinationEntry.fake(
					dateOfVaccination: "2020-02-14"
				)
			],
			testEntries: nil,
			recoveryEntries: nil
		))

		let firstWrongCertificate = try HealthCertificate(base45: firstWrongCertificateBase45)
		let secondWrongCertificate = try HealthCertificate(base45: secondWrongCertificateBase45)
		let thirdWrongCertificate = try HealthCertificate(base45: thirdWrongCertificateBase45)
		let fourthWrongCertificate = try HealthCertificate(base45: fourthWrongCertificateBase45)

		// WHEN / THEN
		XCTAssertTrue(firstWrongCertificate.hasTooManyEntries)
		XCTAssertTrue(secondWrongCertificate.hasTooManyEntries)
		XCTAssertTrue(thirdWrongCertificate.hasTooManyEntries)
		XCTAssertTrue(fourthWrongCertificate.hasTooManyEntries)

		// In case of more than 1 entry for vaccinationEntries the initializer of HealthCertificate will fail due to a json schema validation error.
		let fifthWrongCertificate = try? HealthCertificate(base45: fifthWrongCertificateBase45)
		XCTAssertNil(fifthWrongCertificate)
	}

}
