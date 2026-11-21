import Foundation
import UIKit

/// Service responsible for generating formatted, paginated academic PDF reports using native Apple UIGraphicsPDFRenderer.
public final class PDFReportService {
    public let analyticsService: AnalyticsService
    public let dataStore: AppDataStore
    
    // Standard A4 dimensions in points (72 points/inch)
    private let pageWidth: CGFloat = 595.2
    private let pageHeight: CGFloat = 841.8
    private let margin: CGFloat = 40.0
    
    public init(analyticsService: AnalyticsService, dataStore: AppDataStore) {
        self.analyticsService = analyticsService
        self.dataStore = dataStore
    }
    
    public convenience init(dataStore: AppDataStore) {
        self.init(analyticsService: AnalyticsService(dataStore: dataStore), dataStore: dataStore)
    }
    
    // MARK: - Student Lab Record Report
    
    public func generateStudentReport(studentId: UUID, requestingUser: User) throws -> Data {
        let reportData = try analyticsService.getStudentReportData(studentId: studentId, requestingUser: requestingUser)
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        
        return renderer.pdfData { context in
            var currentPage = 1
            context.beginPage()
            
            var currentY: CGFloat = margin
            
            // Header
            currentY = drawHeader(
                title: "STUDENT LAB RECORD BOOK",
                subtitle: "Academic Experiment Log & Verification Audit",
                currentY: currentY
            )
            
            // Student Profile Section
            currentY = drawSectionTitle("Student Information", currentY: currentY)
            currentY = drawKeyValueGrid([
                ("Student Name:", reportData.student.name),
                ("Username:", reportData.student.username),
                ("Department:", reportData.student.department),
                ("Assigned Mentor:", reportData.mentor?.name ?? "Not Assigned"),
                ("Report Date:", formatDate(reportData.generatedDate)),
                ("Overall Progress:", String(format: "%.1f%% Completed", reportData.completionPercentage))
            ], currentY: currentY)
            
            currentY += 10
            
            // Metrics Summary Box
            currentY = drawSectionTitle("Experiment Status Overview", currentY: currentY)
            let statsText = "Total Experiments: \(reportData.totalExperiments)   |   Verified: \(reportData.verifiedCount)   |   Under Review: \(reportData.submittedCount)   |   In Progress: \(reportData.inProgressCount)   |   Needs Revision: \(reportData.rejectedCount)"
            currentY = drawInfoBox(text: statsText, color: UIColor.systemBlue, currentY: currentY)
            
            currentY += 12
            
            // Subject Breakdown Table
            if !reportData.subjectProgress.isEmpty {
                currentY = drawSectionTitle("Subject-Wise Progress Summary", currentY: currentY)
                let headers = ["Subject Code", "Subject Name", "Total", "Verified", "Completion"]
                let rows: [[String]] = reportData.subjectProgress.map { sp in
                    [
                        sp.subject.code,
                        sp.subject.name,
                        "\(sp.totalExperiments)",
                        "\(sp.verifiedExperiments)",
                        String(format: "%.0f%%", sp.completionPercentage)
                    ]
                }
                currentY = drawTable(headers: headers, rows: rows, columnWidths: [80, 215, 60, 70, 90], currentY: currentY)
                currentY += 12
            }
            
            // Experiments List
            currentY = drawSectionTitle("Experiment Entries & Audit Trail", currentY: currentY)
            
            if reportData.experiments.isEmpty {
                currentY = drawParagraph("No experiments have been recorded or assigned yet.", currentY: currentY, color: .secondaryLabel)
            } else {
                for exp in reportData.experiments {
                    // Check if we need a new page
                    if currentY > pageHeight - 160 {
                        drawFooter(pageNumber: currentPage)
                        currentPage += 1
                        context.beginPage()
                        currentY = margin
                        currentY = drawHeader(
                            title: "STUDENT LAB RECORD BOOK (Cont.)",
                            subtitle: "Student: \(reportData.student.name) (\(reportData.student.department))",
                            currentY: currentY
                        )
                    }
                    
                    let subject = dataStore.subject(byId: exp.subjectId)
                    let verifications = dataStore.verifications(forExperimentId: exp.id)
                    let latestReview = verifications.first
                    
                    currentY = drawExperimentEntry(
                        experiment: exp,
                        subject: subject,
                        latestReview: latestReview,
                        currentY: currentY
                    )
                }
            }
            
            // Mentor Sign-off Section on final page if space allows, otherwise new page
            if currentY > pageHeight - 120 {
                drawFooter(pageNumber: currentPage)
                currentPage += 1
                context.beginPage()
                currentY = margin
            }
            
            currentY += 16
            drawSignOffBlock(mentorName: reportData.mentor?.name, currentY: currentY)
            drawFooter(pageNumber: currentPage)
        }
    }
    
    // MARK: - Mentor Cohort Report
    
    public func generateMentorReport(mentorId: UUID, requestingUser: User) throws -> Data {
        let reportData = try analyticsService.getMentorReportData(mentorId: mentorId, requestingUser: requestingUser)
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        
        return renderer.pdfData { context in
            var currentPage = 1
            context.beginPage()
            
            var currentY: CGFloat = margin
            
            // Header
            currentY = drawHeader(
                title: "MENTOR SUPERVISORY REPORT",
                subtitle: "Supervised Students Progress & Workload Tracking",
                currentY: currentY
            )
            
            // Mentor Profile
            currentY = drawSectionTitle("Mentor Profile", currentY: currentY)
            currentY = drawKeyValueGrid([
                ("Mentor Name:", reportData.mentor.name),
                ("Department:", reportData.mentor.department),
                ("Assigned Students:", "\(reportData.assignedStudents.count) Active"),
                ("Total Assigned Experiments:", "\(reportData.totalAssignedExperimentsCount)"),
                ("Submissions Awaiting Review:", "\(reportData.pendingReviewsCount)"),
                ("Total Verified Experiments:", "\(reportData.verifiedCount)")
            ], currentY: currentY)
            
            currentY += 12
            
            // Supervised Students Progress Table
            currentY = drawSectionTitle("Supervised Students Performance Summary", currentY: currentY)
            
            if reportData.studentSummaries.isEmpty {
                currentY = drawParagraph("No students are currently assigned to this mentor.", currentY: currentY, color: .secondaryLabel)
            } else {
                let headers = ["Student Name", "Department", "Assigned", "Verified", "Pending", "Progress"]
                let rows: [[String]] = reportData.studentSummaries.map { summary in
                    [
                        summary.student.name,
                        summary.student.department,
                        "\(summary.totalAssigned)",
                        "\(summary.verifiedCount)",
                        "\(summary.pendingCount)",
                        String(format: "%.0f%%", summary.completionPercentage)
                    ]
                }
                currentY = drawTable(headers: headers, rows: rows, columnWidths: [135, 150, 55, 55, 55, 65], currentY: currentY)
            }
            
            currentY += 16
            
            // Action Items Section
            let needingAttention = reportData.studentSummaries.filter { $0.requiresAttention }
            if !needingAttention.isEmpty {
                currentY = drawSectionTitle("Attention Required (Correction Follow-Up)", currentY: currentY)
                let note = "\(needingAttention.count) student(s) currently have rejected experiments requiring correction and resubmission."
                currentY = drawInfoBox(text: note, color: UIColor.systemRed, currentY: currentY)
            }
            
            drawFooter(pageNumber: currentPage)
        }
    }
    
    // MARK: - Admin Institutional Report
    
    public func generateAdminReport(requestingUser: User) throws -> Data {
        let reportData = try analyticsService.getAdminReportData(requestingUser: requestingUser)
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        
        return renderer.pdfData { context in
            var currentPage = 1
            context.beginPage()
            
            var currentY: CGFloat = margin
            
            // Header
            currentY = drawHeader(
                title: "INSTITUTIONAL LAB AUDIT REPORT",
                subtitle: "System-Wide Academic Performance & Workload Statistics",
                currentY: currentY
            )
            
            // Overview Key Values
            currentY = drawSectionTitle("Institutional Metrics Overview", currentY: currentY)
            currentY = drawKeyValueGrid([
                ("Active Students:", "\(reportData.activeStudentsCount)"),
                ("Active Mentors:", "\(reportData.activeMentorsCount)"),
                ("Total Student Experiments:", "\(reportData.totalExperimentsCount)"),
                ("Verified Experiments:", "\(reportData.verifiedCount)"),
                ("Awaiting Review:", "\(reportData.pendingReviewCount)"),
                ("Overall System Completion:", String(format: "%.1f%%", reportData.overallCompletionPercentage))
            ], currentY: currentY)
            
            currentY += 12
            
            // Subject Distribution Table
            currentY = drawSectionTitle("Subject-Wise Academic Distribution", currentY: currentY)
            if reportData.subjectStatistics.isEmpty {
                currentY = drawParagraph("No subjects available.", currentY: currentY, color: .secondaryLabel)
            } else {
                let headers = ["Code", "Subject Name", "Total", "Verified", "Pending", "Completion"]
                let rows: [[String]] = reportData.subjectStatistics.map { stat in
                    [
                        stat.subject.code,
                        stat.subject.name,
                        "\(stat.totalExperiments)",
                        "\(stat.verifiedExperiments)",
                        "\(stat.pendingExperiments)",
                        String(format: "%.0f%%", stat.completionPercentage)
                    ]
                }
                currentY = drawTable(headers: headers, rows: rows, columnWidths: [60, 205, 55, 60, 60, 75], currentY: currentY)
            }
            
            currentY += 14
            
            // Mentor Workload Table
            currentY = drawSectionTitle("Mentor Workload & Supervision Summary", currentY: currentY)
            if reportData.mentorWorkloads.isEmpty {
                currentY = drawParagraph("No active mentors found.", currentY: currentY, color: .secondaryLabel)
            } else {
                let headers = ["Mentor Name", "Department", "Students", "Assigned", "Pending", "Verified"]
                let rows: [[String]] = reportData.mentorWorkloads.map { mw in
                    [
                        mw.mentor.name,
                        mw.mentor.department,
                        "\(mw.assignedStudentsCount)",
                        "\(mw.assignedExperimentsCount)",
                        "\(mw.pendingReviewsCount)",
                        "\(mw.verifiedCount)"
                    ]
                }
                currentY = drawTable(headers: headers, rows: rows, columnWidths: [130, 160, 55, 55, 55, 60], currentY: currentY)
            }
            
            drawFooter(pageNumber: currentPage)
        }
    }
    
    // MARK: - Drawing Primitives & Helpers
    
    private func drawHeader(title: String, subtitle: String, currentY: CGFloat) -> CGFloat {
        var y = currentY
        
        let titleFont = UIFont.boldSystemFont(ofSize: 18)
        let subtitleFont = UIFont.systemFont(ofSize: 10, weight: .medium)
        
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: UIColor.label
        ]
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: subtitleFont,
            .foregroundColor: UIColor.secondaryLabel
        ]
        
        (title as NSString).draw(at: CGPoint(x: margin, y: y), withAttributes: titleAttributes)
        y += 22
        
        (subtitle as NSString).draw(at: CGPoint(x: margin, y: y), withAttributes: subtitleAttributes)
        y += 14
        
        // Horizontal rule
        let path = UIBezierPath()
        path.move(to: CGPoint(x: margin, y: y))
        path.addLine(to: CGPoint(x: pageWidth - margin, y: y))
        path.lineWidth = 1.0
        UIColor.separator.setStroke()
        path.stroke()
        
        return y + 12
    }
    
    private func drawSectionTitle(_ title: String, currentY: CGFloat) -> CGFloat {
        let font = UIFont.boldSystemFont(ofSize: 12)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.systemIndigo
        ]
        (title as NSString).draw(at: CGPoint(x: margin, y: currentY), withAttributes: attributes)
        return currentY + 18
    }
    
    private func drawParagraph(_ text: String, currentY: CGFloat, color: UIColor = .label) -> CGFloat {
        let font = UIFont.systemFont(ofSize: 10)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        let rect = CGRect(x: margin, y: currentY, width: pageWidth - 2 * margin, height: 40)
        (text as NSString).draw(in: rect, withAttributes: attributes)
        return currentY + 16
    }
    
    private func drawKeyValueGrid(_ items: [(String, String)], currentY: CGFloat) -> CGFloat {
        var y = currentY
        let colWidth = (pageWidth - 2 * margin) / 2
        let keyFont = UIFont.systemFont(ofSize: 9, weight: .semibold)
        let valFont = UIFont.systemFont(ofSize: 9, weight: .regular)
        
        for i in stride(from: 0, to: items.count, by: 2) {
            let left = items[i]
            let leftX = margin
            
            (left.0 as NSString).draw(at: CGPoint(x: leftX, y: y), withAttributes: [.font: keyFont, .foregroundColor: UIColor.secondaryLabel])
            (left.1 as NSString).draw(at: CGPoint(x: leftX + 90, y: y), withAttributes: [.font: valFont, .foregroundColor: UIColor.label])
            
            if i + 1 < items.count {
                let right = items[i + 1]
                let rightX = margin + colWidth
                (right.0 as NSString).draw(at: CGPoint(x: rightX, y: y), withAttributes: [.font: keyFont, .foregroundColor: UIColor.secondaryLabel])
                (right.1 as NSString).draw(at: CGPoint(x: rightX + 95, y: y), withAttributes: [.font: valFont, .foregroundColor: UIColor.label])
            }
            
            y += 14
        }
        
        return y
    }
    
    private func drawInfoBox(text: String, color: UIColor, currentY: CGFloat) -> CGFloat {
        let boxRect = CGRect(x: margin, y: currentY, width: pageWidth - 2 * margin, height: 26)
        
        let path = UIBezierPath(roundedRect: boxRect, cornerRadius: 4)
        color.withAlphaComponent(0.08).setFill()
        path.fill()
        color.withAlphaComponent(0.4).setStroke()
        path.lineWidth = 0.5
        path.stroke()
        
        let font = UIFont.systemFont(ofSize: 9, weight: .medium)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        
        let textRect = CGRect(x: margin + 8, y: currentY + 7, width: boxRect.width - 16, height: 16)
        (text as NSString).draw(in: textRect, withAttributes: attributes)
        
        return currentY + 32
    }
    
    private func drawTable(headers: [String], rows: [[String]], columnWidths: [CGFloat], currentY: CGFloat) -> CGFloat {
        var y = currentY
        let rowHeight: CGFloat = 16.0
        let headerFont = UIFont.boldSystemFont(ofSize: 8.5)
        let cellFont = UIFont.systemFont(ofSize: 8.5)
        
        // Draw header background
        let headerRect = CGRect(x: margin, y: y, width: pageWidth - 2 * margin, height: rowHeight)
        UIColor.systemGray5.setFill()
        UIRectFill(headerRect)
        
        // Draw header text
        var curX = margin + 4
        for (i, h) in headers.enumerated() {
            let width = columnWidths[i] - 6
            let rect = CGRect(x: curX, y: y + 3, width: width, height: rowHeight)
            (h as NSString).draw(in: rect, withAttributes: [.font: headerFont, .foregroundColor: UIColor.label])
            curX += columnWidths[i]
        }
        
        y += rowHeight
        
        // Draw rows
        for (rowIndex, row) in rows.enumerated() {
            if rowIndex % 2 == 1 {
                let bgRect = CGRect(x: margin, y: y, width: pageWidth - 2 * margin, height: rowHeight)
                UIColor.systemGray6.withAlphaComponent(0.5).setFill()
                UIRectFill(bgRect)
            }
            
            curX = margin + 4
            for (colIndex, text) in row.enumerated() {
                let width = columnWidths[colIndex] - 6
                let rect = CGRect(x: curX, y: y + 3, width: width, height: rowHeight)
                (text as NSString).draw(in: rect, withAttributes: [.font: cellFont, .foregroundColor: UIColor.label])
                curX += columnWidths[colIndex]
            }
            
            y += rowHeight
        }
        
        return y
    }
    
    private func drawExperimentEntry(
        experiment: Experiment,
        subject: Subject?,
        latestReview: Verification?,
        currentY: CGFloat
    ) -> CGFloat {
        var y = currentY
        let entryWidth = pageWidth - 2 * margin
        
        // Title line: EXP-01: Title (Status)
        let titleFont = UIFont.boldSystemFont(ofSize: 10)
        let normalFont = UIFont.systemFont(ofSize: 8.5)
        let boldFont = UIFont.boldSystemFont(ofSize: 8.5)
        
        let statusString = "[\(experiment.status.displayName.uppercased())]"
        let headerText = "\(experiment.experimentNumber) - \(experiment.title)  \(statusString)"
        
        (headerText as NSString).draw(at: CGPoint(x: margin, y: y), withAttributes: [
            .font: titleFont,
            .foregroundColor: UIColor.label
        ])
        y += 14
        
        // Subject line
        let subjText = "Subject: \(subject?.code ?? "") - \(subject?.name ?? "General") | Date: \(formatDate(experiment.date))"
        (subjText as NSString).draw(at: CGPoint(x: margin, y: y), withAttributes: [
            .font: normalFont,
            .foregroundColor: UIColor.secondaryLabel
        ])
        y += 12
        
        // Aim snippet
        let aimText = "Aim: \(experiment.aim)"
        let aimRect = CGRect(x: margin, y: y, width: entryWidth, height: 24)
        (aimText as NSString).draw(in: aimRect, withAttributes: [
            .font: normalFont,
            .foregroundColor: UIColor.label
        ])
        y += 14
        
        // Review remark if verified or rejected
        if let review = latestReview {
            let reviewText = "Verification (\(review.status.displayName)): \(review.comments) — \(review.mentorName)"
            let reviewRect = CGRect(x: margin, y: y, width: entryWidth, height: 16)
            let color: UIColor = review.status == .verified ? .systemGreen : .systemRed
            (reviewText as NSString).draw(in: reviewRect, withAttributes: [
                .font: boldFont,
                .foregroundColor: color
            ])
            y += 14
        }
        
        // Divider line
        let divider = UIBezierPath()
        divider.move(to: CGPoint(x: margin, y: y + 2))
        divider.addLine(to: CGPoint(x: pageWidth - margin, y: y + 2))
        divider.lineWidth = 0.5
        UIColor.separator.setStroke()
        divider.stroke()
        
        y += 8
        return y
    }
    
    private func drawSignOffBlock(mentorName: String?, currentY: CGFloat) {
        let blockY = currentY + 10
        let lineWidth: CGFloat = 160.0
        
        // Student Signature Line
        let studentX = margin + 20
        let path1 = UIBezierPath()
        path1.move(to: CGPoint(x: studentX, y: blockY + 30))
        path1.addLine(to: CGPoint(x: studentX + lineWidth, y: blockY + 30))
        path1.lineWidth = 0.8
        UIColor.darkGray.setStroke()
        path1.stroke()
        
        ("Student Signature" as NSString).draw(at: CGPoint(x: studentX + 25, y: blockY + 34), withAttributes: [
            .font: UIFont.systemFont(ofSize: 8, weight: .medium),
            .foregroundColor: UIColor.secondaryLabel
        ])
        
        // Mentor Signature Line
        let mentorX = pageWidth - margin - lineWidth - 20
        let path2 = UIBezierPath()
        path2.move(to: CGPoint(x: mentorX, y: blockY + 30))
        path2.addLine(to: CGPoint(x: mentorX + lineWidth, y: blockY + 30))
        path2.lineWidth = 0.8
        UIColor.darkGray.setStroke()
        path2.stroke()
        
        let mentorLabel = mentorName != nil ? "Supervising Mentor (\(mentorName!))" : "Supervising Mentor"
        (mentorLabel as NSString).draw(at: CGPoint(x: mentorX + 10, y: blockY + 34), withAttributes: [
            .font: UIFont.systemFont(ofSize: 8, weight: .medium),
            .foregroundColor: UIColor.secondaryLabel
        ])
    }
    
    private func drawFooter(pageNumber: Int) {
        let footerY = pageHeight - margin + 15
        
        let path = UIBezierPath()
        path.move(to: CGPoint(x: margin, y: footerY - 5))
        path.addLine(to: CGPoint(x: pageWidth - margin, y: footerY - 5))
        path.lineWidth = 0.5
        UIColor.separator.setStroke()
        path.stroke()
        
        let footerFont = UIFont.systemFont(ofSize: 8)
        let leftText = "Lab Record Book System - Official Academic Record"
        let rightText = "Page \(pageNumber)"
        
        (leftText as NSString).draw(at: CGPoint(x: margin, y: footerY), withAttributes: [
            .font: footerFont,
            .foregroundColor: UIColor.secondaryLabel
        ])
        
        (rightText as NSString).draw(at: CGPoint(x: pageWidth - margin - 40, y: footerY), withAttributes: [
            .font: footerFont,
            .foregroundColor: UIColor.secondaryLabel
        ])
    }
    
    private func formatDate(_ date: Date) -> String {
        DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .none)
    }
}
