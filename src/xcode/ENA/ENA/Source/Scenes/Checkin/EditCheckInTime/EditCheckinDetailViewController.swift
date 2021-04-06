////
// 🦠 Corona-Warn-App
//

import UIKit
import OpenCombine

class EditCheckinDetailViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, FooterViewHandling {

	// MARK: - Init

	init(
		eventStore: EventStoring,
		checkIn: Checkin,
		dismiss: @escaping () -> Void
	) {
		self.dismiss = dismiss
		self.viewModel = EditCheckinDetailViewModel(checkIn, eventStore: eventStore)

		super.init(nibName: nil, bundle: nil)
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	// MARK: - Overrides

	override func viewDidLoad() {
		super.viewDidLoad()
		setupView()
		setupTableView()
		setupCombine()
	}

	override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		super.traitCollectionDidChange(previousTraitCollection)
		didCalculateGradientHeight = false
	}

	// MARK: - Protocol FooterViewHandling

	func didTapFooterViewButton(_ type: FooterViewModel.ButtonType) {
		footerView?.setLoadingIndicator(true, disable: true, button: .primary)
		viewModel.saveIfNeeded()
		DispatchQueue.main.async { [weak self] in
			self?.dismiss()
		}
	}

	func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		guard didCalculateGradientHeight == false,
			indexPath == IndexPath(row: 0, section: EditCheckinDetailViewModel.TableViewSections.description.rawValue) else {
			return
		}

		let cellRect = tableView.rectForRow(at: indexPath)
		let result = view.convert(cellRect, from: tableView)
		backgroundView.gradientHeightConstraint.constant = result.midY
		didCalculateGradientHeight = true
	}

	// MARK: - UITableViewDataSource

	func numberOfSections(in tableView: UITableView) -> Int {
		return EditCheckinDetailViewModel.TableViewSections.allCases.count
	}

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return viewModel.numberOfRows(EditCheckinDetailViewModel.TableViewSections(rawValue: section))
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let section = EditCheckinDetailViewModel.TableViewSections(rawValue: indexPath.section) else {
			fatalError("unknown section - can't match a cell type")
		}
		switch section {
		case .header:
			let cell = tableView.dequeueReusableCell(cellType: CheckInHeaderCell.self, for: indexPath)
			cell.configure(AppStrings.Checkins.Edit.sectionHeaderTitle)
			return cell

		case .description:
			let cell = tableView.dequeueReusableCell(cellType: CheckInDescriptionCell.self, for: indexPath)
			cell.configure(cellModel: viewModel.checkInDescriptionCellModel)
			return cell

		case .topCorner:
			return tableView.dequeueReusableCell(cellType: CheckInTopCornerCell.self, for: indexPath)

		case .checkInStart:
			let cell = tableView.dequeueReusableCell(cellType: CheckInTimeCell.self, for: indexPath)
			cell.configure(viewModel.checkInStartCellModel)
			return cell

		case .startPicker:
			let cell = tableView.dequeueReusableCell(cellType: CheckInDatePickerCell.self, for: indexPath)
			cell.configure(viewModel.checkInStartCellModel)
			return cell

		case .checkInEnd:
			let cell = tableView.dequeueReusableCell(cellType: CheckInTimeCell.self, for: indexPath)
			cell.configure(viewModel.checkInEndCellModel)
			return cell

		case .endPicker:
			let cell = tableView.dequeueReusableCell(cellType: CheckInDatePickerCell.self, for: indexPath)
			cell.configure(viewModel.checkInEndCellModel)
			return cell

		case .bottomCorner:
			return tableView.dequeueReusableCell(cellType: CheckInBottomCornerCell.self, for: indexPath)

		case .notice:
			let cell = tableView.dequeueReusableCell(cellType: CheckInNoticeCell.self, for: indexPath)
			cell.configure(AppStrings.Checkins.Edit.notice)
			return cell
		}

	}

	// MARK: - UITableViewDelegate

	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		switch EditCheckinDetailViewModel.TableViewSections(rawValue: indexPath.section) {
		case .none:
			Log.debug("unknown section selected - ignoring")
			return

		case .some(let section):
			switch section {
			case .checkInStart:
				viewModel.toggleStartPicker()
			case .checkInEnd:
				viewModel.toggleEndPicker()
			default:
				Log.debug("Section doesn't support selection")
			}
		}
	}

	// MARK: - Private

	private let backgroundView = GradientBackgroundView()
	private let tableView = UITableView(frame: .zero, style: .plain)

	private let viewModel: EditCheckinDetailViewModel
	private let dismiss: () -> Void

	private var didCalculateGradientHeight: Bool = false

	private var subscriptions = Set<AnyCancellable>()
	private var selectedDuration: Int?
	private var tableContentObserver: NSKeyValueObservation!

	private func setupView() {
		parent?.view.backgroundColor = .clear
		backgroundView.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(backgroundView)

		let gradientNavigationView = GradientNavigationView(
			didTapCloseButton: { [weak self] in
				self?.dismiss()
			}
		)
		gradientNavigationView.translatesAutoresizingMaskIntoConstraints = false
		backgroundView.addSubview(gradientNavigationView)

		tableView.translatesAutoresizingMaskIntoConstraints = false
		tableView.backgroundColor = .clear
		backgroundView.addSubview(tableView)

		NSLayoutConstraint.activate(
			[
				backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
				backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
				backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
				backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

				gradientNavigationView.topAnchor.constraint(equalTo: backgroundView.topAnchor, constant: 24.0),
				gradientNavigationView.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor, constant: 16.0),
				gradientNavigationView.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor, constant: -16.0),

				tableView.topAnchor.constraint(equalTo: gradientNavigationView.bottomAnchor, constant: 20.0),
				tableView.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor),
				tableView.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor),
				tableView.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor)
		])

		tableContentObserver = tableView.observe(\UITableView.contentOffset, options: .new) { [weak self] tableView, change in
			guard let self = self,
				  let yOffset = change.newValue?.y else {
				return
			}
			let offsetLimit = tableView.frame.origin.y
			self.backgroundView.updatedTopLayout(with: yOffset, limit: offsetLimit)
		}
	}

	private func setupTableView() {
		tableView.dataSource = self
		tableView.delegate = self
		tableView.separatorStyle = .none

		tableView.contentInsetAdjustmentBehavior = .never

		tableView.register(CheckInHeaderCell.self, forCellReuseIdentifier: CheckInHeaderCell.reuseIdentifier)
		tableView.register(CheckInDescriptionCell.self, forCellReuseIdentifier: CheckInDescriptionCell.reuseIdentifier)
		tableView.register(CheckInTopCornerCell.self, forCellReuseIdentifier: CheckInTopCornerCell.reuseIdentifier)
		tableView.register(CheckInTimeCell.self, forCellReuseIdentifier: CheckInTimeCell.reuseIdentifier)
		tableView.register(CheckInDatePickerCell.self, forCellReuseIdentifier: CheckInDatePickerCell.reuseIdentifier)
		tableView.register(CheckInBottomCornerCell.self, forCellReuseIdentifier: CheckInBottomCornerCell.reuseIdentifier)
		tableView.register(CheckInNoticeCell.self, forCellReuseIdentifier: CheckInNoticeCell.reuseIdentifier)
	}

	private func setupCombine() {
		viewModel.$isStartDatePickerVisible
			.receive(on: DispatchQueue.main.ocombine)
			.sink { [weak self] _ in
				let sectionIndex = EditCheckinDetailViewModel.TableViewSections.startPicker.rawValue
				self?.tableView.reloadSections([sectionIndex], with: .automatic)
			}
			.store(in: &subscriptions)

		viewModel.$isEndDatePickerVisible
			.receive(on: DispatchQueue.main.ocombine)
			.sink { [weak self] _ in
				let sectionIndex = EditCheckinDetailViewModel.TableViewSections.endPicker.rawValue
				self?.tableView.reloadSections([sectionIndex], with: .automatic)
			}
			.store(in: &subscriptions)
	}

}
