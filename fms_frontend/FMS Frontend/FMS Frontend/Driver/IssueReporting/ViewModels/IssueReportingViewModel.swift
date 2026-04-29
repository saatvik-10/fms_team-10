import Foundation
import Combine
internal import UIKit

@MainActor
final class IssueReportingViewModel: ObservableObject {
	@Published var isSubmitting = false
	@Published var errorMessage: String?
	@Published var lastSubmittedIssue: IssueReportItem?
	@Published var myIssues: [IssueReportItem] = []

	private let driverAPI: DriverAPI

	init(driverAPI: DriverAPI = .shared) {
		self.driverAPI = driverAPI
	}

	func submitIssue(
		tripId: String?,
		transcript: String,
		incidentLocation: String,
		vehicleUnit: String,
		images: [UIImage]
	) async -> Bool {
		let trimmedTranscript = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
		guard !trimmedTranscript.isEmpty else {
			errorMessage = "Issue description cannot be empty."
			return false
		}

		isSubmitting = true
		errorMessage = nil

		let imagePayload = images
			.prefix(6)
			.compactMap { $0.jpegData(compressionQuality: 0.8) }

		do {
			let response = try await driverAPI.createIssueReport(
				CreateIssueReportRequest(
					tripId: tripId,
					transcript: trimmedTranscript,
					incidentLocation: incidentLocation,
					vehicleUnit: vehicleUnit,
					images: imagePayload
				)
			)

			lastSubmittedIssue = response.issue
			isSubmitting = false
			return true
		} catch {
			errorMessage = error.localizedDescription
			isSubmitting = false
			return false
		}
	}

	func fetchMyIssues(limit: Int = 20) async {
		do {
			let response = try await driverAPI.getMyIssueReports(limit: limit)
			myIssues = response.issues
		} catch {
			errorMessage = error.localizedDescription
		}
	}
}
