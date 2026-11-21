import Foundation
import Observation
import UIKit

/// Defines the report generation target and context.
public enum ReportType: Equatable {
    case student(User)
    case mentor(User)
    case admin(User)
    
    public var title: String {
        switch self {
        case .student(let user):
            return "\(user.name)'s Lab Record Book Report"
        case .mentor(let user):
            return "\(user.name)'s Supervisory Report"
        case .admin:
            return "Institutional Lab Audit Report"
        }
    }
    
    public var defaultFileName: String {
        switch self {
        case .student(let user):
            let clean = user.username.replacingOccurrences(of: " ", with: "_")
            return "LabRecord_\(clean).pdf"
        case .mentor(let user):
            let clean = user.username.replacingOccurrences(of: " ", with: "_")
            return "MentorReport_\(clean).pdf"
        case .admin:
            return "InstitutionalAuditReport.pdf"
        }
    }
}

/// ViewModel coordinating PDF compilation, status handling, file persistence for export, and share sheet triggers.
@Observable
public final class ReportGenerationViewModel {
    public let reportType: ReportType
    public let requestingUser: User
    public let pdfReportService: PDFReportService
    
    public var isGenerating: Bool = false
    public var pdfData: Data? = nil
    public var generatedFileURL: URL? = nil
    public var errorMessage: String? = nil
    public var showError: Bool = false
    public var showShareSheet: Bool = false
    
    public init(
        reportType: ReportType,
        requestingUser: User,
        dataStore: AppDataStore,
        pdfReportService: PDFReportService? = nil
    ) {
        self.reportType = reportType
        self.requestingUser = requestingUser
        self.pdfReportService = pdfReportService ?? PDFReportService(dataStore: dataStore)
    }
    
    /// Generates the PDF data based on the requested report type and saves it to a temporary file for native sharing.
    public func generatePDF() {
        isGenerating = true
        errorMessage = nil
        showError = false
        
        do {
            let data: Data
            switch reportType {
            case .student(let student):
                data = try pdfReportService.generateStudentReport(studentId: student.id, requestingUser: requestingUser)
            case .mentor(let mentor):
                data = try pdfReportService.generateMentorReport(mentorId: mentor.id, requestingUser: requestingUser)
            case .admin:
                data = try pdfReportService.generateAdminReport(requestingUser: requestingUser)
            }
            
            self.pdfData = data
            
            // Save to temporary file URL for ShareLink and ActivityViewController
            let tempDir = FileManager.default.temporaryDirectory
            let fileURL = tempDir.appendingPathComponent(reportType.defaultFileName)
            try data.write(to: fileURL)
            self.generatedFileURL = fileURL
            
            self.isGenerating = false
        } catch {
            self.isGenerating = false
            self.errorMessage = error.localizedDescription
            self.showError = true
        }
    }
}
