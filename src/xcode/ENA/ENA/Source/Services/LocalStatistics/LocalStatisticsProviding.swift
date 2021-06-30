//
// 🦠 Corona-Warn-App
//

import Foundation
import OpenCombine

protocol LocalStatisticsProviding {
	func latestLocalStatistics(federalStateID: String, eTag: String?) -> AnyPublisher<SAP_Internal_Stats_LocalStatistics, Error>
}

protocol LocalStatisticsFetching {
	var configuration: HTTPClient.Configuration { get }
	var session: URLSession { get }
	var signatureVerifier: SignatureVerifier { get }

	typealias LocalStatisticsCompletionHandler = (Result<LocalStatisticsResponse, Error>) -> Void

	func fetchLocalStatistics(
		federalStateID: String,
		eTag: String?,
		completion: @escaping (Result<LocalStatisticsResponse, Error>) -> Void
	)
}

struct LocalStatisticsResponse {
	let localStatistics: SAP_Internal_Stats_LocalStatistics
	let eTag: String?
	let timestamp: Date
	let federalStateID: String

	init(_ localStatistics: SAP_Internal_Stats_LocalStatistics, _ eTag: String? = nil, _ federalStateID: String) {
		self.federalStateID = federalStateID
		self.localStatistics = localStatistics
		self.eTag = eTag
		self.timestamp = Date()
	}
}
