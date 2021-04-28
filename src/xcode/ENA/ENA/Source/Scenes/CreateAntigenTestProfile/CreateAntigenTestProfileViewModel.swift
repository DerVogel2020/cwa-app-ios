////
// 🦠 Corona-Warn-App
//

import Foundation
import OpenCombine

final class CreateAntigenTestProfileViewModel {

	// MARK: - Init
	init(
		store: AntigenTestProfileStoring
	) {
		self.store = store
		self.antigenTestProfile = AntigenTestProfile()

		// this is only for coordinator testing, remove later
		antigenTestProfile.firstName = "Sabine"
		antigenTestProfile.lastName = "Schulz"
		antigenTestProfile.dateOfBirth = Date(timeIntervalSince1970: 390047238)
		antigenTestProfile.addressLine = "Blumenstraße 2"
		antigenTestProfile.city = "Berlin"
		antigenTestProfile.zipCode = "43923"
		antigenTestProfile.phoneNumber = "0165434563"
		antigenTestProfile.email = "sabine.schulz@gmx.com"
	}

	// MARK: - Overrides

	// MARK: - Protocol <#Name#>

	// MARK: - Public

	// MARK: - Internal
	@OpenCombine.Published var antigenTestProfile: AntigenTestProfile

	let title: String = "Schnelltest-Profil anlegen"

	var isSaveButtonEnabled: Bool {
		return
			!(antigenTestProfile.firstName?.isEmpty ?? true) ||
			!(antigenTestProfile.lastName?.isEmpty ?? true) ||
			(antigenTestProfile.dateOfBirth != nil) ||
			!(antigenTestProfile.addressLine?.isEmpty ?? true) ||
			!(antigenTestProfile.zipCode?.isEmpty ?? true) ||
			!(antigenTestProfile.city?.isEmpty ?? true) ||
			!(antigenTestProfile.phoneNumber?.isEmpty ?? true) ||
			!(antigenTestProfile.email?.isEmpty ?? true)
	}

	func save() {
		store.antigenTestProfile = antigenTestProfile
	}

	// MARK: - Private

	private let store: AntigenTestProfileStoring

}
