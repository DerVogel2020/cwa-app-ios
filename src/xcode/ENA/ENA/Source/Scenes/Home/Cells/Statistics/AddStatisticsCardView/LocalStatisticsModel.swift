////
// 🦠 Corona-Warn-App
//

import Foundation

struct LocalStatisticsModel {

	// MARK: - Init

	init(
		store: Store,
		jsonFileURL: URL
	) {
		self.store = store

		do {
			let jsonData = try Data(contentsOf: jsonFileURL)
			self.allDistricts = try JSONDecoder().decode([DistrictElement].self, from: jsonData)
		} catch {
			Log.debug("Failed to read / parse district json", log: .ppac)
			self.allDistricts = []
		}
	}

	// MARK: - Internal

	var allFederalStateNames: [String] {
		FederalStateName.allCases.map { $0.rawValue }
	}

	func allRegions(by federalStateName: String) -> [String] {
		allDistricts.filter { district -> Bool in
			district.federalStateName.rawValue == federalStateName
		}
		.map { $0.districtName }
	}
	func regionId(by region: String) -> DistrictElement? {
		allDistricts.first(where: { district -> Bool in
			district.districtName == region
		})
	}

//	mutating func saveLocalStatistics() {
		// save the returned LocalStatistics From the API to the store
//	}

	// MARK: - Private

	private let store: Store
	private let allDistricts: [DistrictElement]
}
