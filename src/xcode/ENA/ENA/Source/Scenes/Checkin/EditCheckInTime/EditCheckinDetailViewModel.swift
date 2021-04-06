////
// 🦠 Corona-Warn-App
//

import UIKit
import OpenCombine

final class EditCheckinDetailViewModel {

	// MARK: - Init
	
	init(
		_ checkIn: Checkin,
		eventStore: EventStoring
	) {
		self.checkIn = checkIn
		self.eventStore = eventStore

		self.startDate = checkIn.checkinStartDate
		self.endDate = checkIn.checkinEndDate
		self.checkInDescriptionCellModel = CheckInDescriptionCellModel(checkIn: checkIn)

		// update viewModel on change of cellModels
		checkInStartCellModel.$date
			.sink(receiveValue: { startDate in
				self.startDate = startDate
				self.checkInEndCellModel.minDate = startDate
			})
			.store(in: &subscriptions)

		$isStartDatePickerVisible
			.assign(to: \CheckInTimeModel.isPickerVisible, on: checkInStartCellModel)
			.store(in: &subscriptions)

		checkInEndCellModel.$date
			.sink(receiveValue: { endDate in
				self.endDate = endDate
				self.checkInStartCellModel.maxDate = endDate
			})
			.store(in: &subscriptions)

		$isEndDatePickerVisible
			.assign(to: \CheckInTimeModel.isPickerVisible, on: checkInEndCellModel)
			.store(in: &subscriptions)
	}

	enum TableViewSections: Int, CaseIterable {
		case header
		case description
		case topCorner
		case checkInStart
		case startPicker
		case checkInEnd
		case endPicker
		case bottomCorner
		case notice
	}

	// MARK: - Internal

	let checkInDescriptionCellModel: CheckInDescriptionCellModel
	lazy var checkInStartCellModel: CheckInTimeModel = {
		CheckInTimeModel(
			AppStrings.Checkins.Edit.checkedIn,
			maxDate: checkIn.checkinEndDate,
			date: checkIn.checkinStartDate,
			hasTopSeparator: false,
			isPickerVisible: self.isStartDatePickerVisible
		)
	}()

	lazy var  checkInEndCellModel: CheckInTimeModel = {
		CheckInTimeModel(
			AppStrings.Checkins.Edit.checkedOut,
			minDate: checkIn.checkinStartDate,
			date: checkIn.checkinEndDate,
			hasTopSeparator: true,
			isPickerVisible: self.isEndDatePickerVisible
		)
	}()

	private (set) var startDate: Date
	private (set) var endDate: Date

	@OpenCombine.Published private(set) var isStartDatePickerVisible: Bool = false
	@OpenCombine.Published private(set) var isEndDatePickerVisible: Bool = false

	func numberOfRows(_ section: TableViewSections?) -> Int {
		guard let section = section else {
			Log.debug("unknown section -> better return 0 rows")
			return 0
		}
		switch section {
		case .startPicker:
			return isStartDatePickerVisible ? 1 : 0
		case .endPicker:
			return isEndDatePickerVisible ? 1 : 0
		default:
			return 1
		}
	}

	func toggleStartPicker() {
		isStartDatePickerVisible.toggle()
	}

	func toggleEndPicker() {
		isEndDatePickerVisible.toggle()
	}

	func saveIfNeeded() {
		guard isDirty else {
			Log.debug("nothing to save here")
			return
		}
		let updateCheckIn = Checkin(
			id: checkIn.id,
			traceLocationId: checkIn.traceLocationId,
			traceLocationIdHash: checkIn.traceLocationIdHash,
			traceLocationVersion: checkIn.traceLocationVersion,
			traceLocationType: checkIn.traceLocationType,
			traceLocationDescription: checkIn.traceLocationDescription,
			traceLocationAddress: checkIn.traceLocationAddress,
			traceLocationStartDate: checkIn.traceLocationStartDate,
			traceLocationEndDate: checkIn.traceLocationEndDate,
			traceLocationDefaultCheckInLengthInMinutes: checkIn.traceLocationDefaultCheckInLengthInMinutes,
			cryptographicSeed: checkIn.cryptographicSeed,
			cnPublicKey: checkIn.cnPublicKey,
			checkinStartDate: startDate,
			checkinEndDate: endDate,
			checkinCompleted: checkIn.checkinCompleted,
			createJournalEntry: checkIn.createJournalEntry
		)
		eventStore.updateCheckin(updateCheckIn)
	}

	// MARK: - Private
	
	private let checkIn: Checkin
	private let eventStore: EventStoring
	private var subscriptions = Set<AnyCancellable>()

	private var isDirty: Bool {
		return checkIn.checkinStartDate != startDate || checkIn.checkinEndDate != endDate
	}

}
