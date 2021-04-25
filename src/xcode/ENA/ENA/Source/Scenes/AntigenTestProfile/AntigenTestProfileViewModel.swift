////
// 🦠 Corona-Warn-App
//

import Foundation
import UIKit
import Contacts

struct AntigenTestProfileViewModel {

	// MARK: - Init
	init(
		store: AntigenTestProfileStoring
	) {
		self.store = store
		self.antigenTestProfile = store.antigenTestProfile
	}

	// MARK: - Overrides

	// MARK: - Protocol <#Name#>

	// MARK: - Public

	// MARK: - Internal

	func deleteProfile() {
		store.antigenTestProfile = nil
	}

	var numberOfSections: Int {
		TableViewSections.allCases.count
	}

	func numberOfItems(in section: TableViewSections) -> Int {
		switch section {
		default:
			return 1
		}
	}

	var headerCellViewModel: SimpelTextCellViewModel {
		SimpelTextCellViewModel(
			backgroundColor: .clear,
			textColor: .enaColor(for: .textContrast),
			textAlignment: .center,
			text: AppStrings.ExposureSubmission.AntigenTest.Profile.headerText,
			topSpace: 42.0,
			font: .enaFont(for: .headline)
		)
	}

	var profileCellViewModel: SimpelTextCellViewModel {
		SimpelTextCellViewModel(
			backgroundColor: .enaColor(for: .background),
			textColor: .enaColor(for: .textPrimary1 ),
			textAlignment: .left,
			text: [friendlyName, formattedAddress, emailAdress, dateOfBirth].compactMap({ $0 }).joined(separator: "\n"),
			topSpace: 18.0,
			font: .enaFont(for: .headline),
			boarderColor: UIColor().hexStringToUIColor(hex: "#EDEDED")
		)
	}

	var noticeCellViewModel: SimpelTextCellViewModel {
		SimpelTextCellViewModel(
			backgroundColor: .enaColor(for: .background),
			textColor: .enaColor(for: .textPrimary1 ),
			textAlignment: .left,
			text: AppStrings.ExposureSubmission.AntigenTest.Profile.noticeText,
			topSpace: 18.0,
			font: .enaFont(for: .subheadline),
			boarderColor: UIColor().hexStringToUIColor(hex: "#EDEDED")
		)
	}

	// MARK: - Private

	enum TableViewSections: Int, CaseIterable {
		case header
//		case QRCode
		case profile
		case notice

		static func map(_ section: Int) -> TableViewSections {
			guard let section = TableViewSections(rawValue: section) else {
				fatalError("unsupported tableView section")
			}
			return section
		}
	}

	private let store: AntigenTestProfileStoring
	private var antigenTestProfile: AntigenTestProfile?

	private var friendlyName: String {
		guard let antigenTestProfile = antigenTestProfile else {
			Log.error("AntigenTestProfile failed to create address - profile is missing")
			return ""
		}

		var components = PersonNameComponents()
		components.givenName = antigenTestProfile.firstName
		components.familyName = antigenTestProfile.lastName

		let formatter = PersonNameComponentsFormatter()
		formatter.style = .medium
		return formatter.string(from: components).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
	}

	private var dateOfBirth: String? {
		guard let dateOfBirth = antigenTestProfile?.dateOfBirth else {
			return nil
		}

		return String(
			format: AppStrings.ExposureSubmission.AntigenTest.Profile.dateOfBirthFormatText,
			DateFormatter.localizedString(from: dateOfBirth, dateStyle: .medium, timeStyle: .none)
		)
	}

	private var emailAdress: String? {
		guard let email = antigenTestProfile?.email else {
			return nil
		}
		return String(
			format: AppStrings.ExposureSubmission.AntigenTest.Profile.emailFormatText,
			email
		)
	}

	private var formattedAddress: String {
		guard let antigenTestProfile = antigenTestProfile else {
			Log.error("AntigenTestProfile failed to create address - profile is missing")
			return ""
		}
		let adr = CNMutablePostalAddress()
		adr.street = antigenTestProfile.addressLine ?? ""
		adr.city = antigenTestProfile.city ?? ""
		adr.postalCode = antigenTestProfile.zipCode ?? ""
		return CNPostalAddressFormatter().string(from: adr)
	}

}
