import SwiftUI

/// Unified, reusable report generation screen with summary preview, generate trigger, and export options.
public struct ReportGenerationView: View {
    public let reportType: ReportType
    public let requestingUser: User
    
    @Environment(AppDataStore.self) private var dataStore
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ReportGenerationViewModel?
    @State private var showingPreview: Bool = false
    
    public init(reportType: ReportType, requestingUser: User) {
        self.reportType = reportType
        self.requestingUser = requestingUser
    }
    
    public var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Header Banner
                            VStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color.accentColor.opacity(0.12))
                                        .frame(width: 72, height: 72)
                                    Image(systemName: "doc.text.fill")
                                        .font(.system(size: 36))
                                        .foregroundStyle(Color.accentColor)
                                }
                                .padding(.top, 16)
                                
                                VStack(spacing: 4) {
                                    Text(reportType.title)
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .multilineTextAlignment(.center)
                                    
                                    Text("Official Academic PDF Generation")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.horizontal)
                            
                            // Information Card
                            VStack(alignment: .leading, spacing: 14) {
                                Text("Report Contents")
                                    .font(.headline)
                                
                                switch reportType {
                                case .student(let student):
                                    infoBullet(icon: "person.crop.circle", text: "Student: \(student.name) (\(student.department))")
                                    infoBullet(icon: "checkmark.seal", text: "Verified & in-progress experiment logs")
                                    infoBullet(icon: "chart.bar", text: "Subject-wise completion breakdown")
                                    infoBullet(icon: "signature", text: "Mentor remarks and verification sign-off block")
                                case .mentor(let mentor):
                                    infoBullet(icon: "person.2.fill", text: "Supervised Students Roster (\(mentor.department))")
                                    infoBullet(icon: "hourglass.badge.eye", text: "Pending submission reviews and workload counts")
                                    infoBullet(icon: "percent", text: "Individual student progress rates")
                                    infoBullet(icon: "exclamationmark.triangle", text: "Attention alerts for rejected student work")
                                case .admin:
                                    infoBullet(icon: "building.2.fill", text: "Institution-wide academic metrics")
                                    infoBullet(icon: "person.3.fill", text: "Active student and mentor enrollments")
                                    infoBullet(icon: "chart.pie.fill", text: "Subject distribution & completion percentages")
                                    infoBullet(icon: "briefcase.fill", text: "Department-level mentor workload breakdown")
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal)
                            
                            // Status / Action Section
                            if vm.isGenerating {
                                VStack(spacing: 12) {
                                    ProgressView()
                                        .scaleEffect(1.3)
                                    Text("Compiling Academic PDF Document...")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 24)
                            } else if let data = vm.pdfData {
                                VStack(spacing: 16) {
                                    HStack(spacing: 10) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.title2)
                                            .foregroundStyle(.green)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("PDF Ready")
                                                .font(.headline)
                                            Text("Generated \(ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file))")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                    }
                                    .padding()
                                    .background(Color.green.opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    
                                    HStack(spacing: 12) {
                                        Button(action: {
                                            showingPreview = true
                                        }) {
                                            HStack {
                                                Image(systemName: "eye.fill")
                                                Text("Preview PDF")
                                            }
                                            .font(.headline)
                                            .foregroundStyle(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color.blue)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                        }
                                        
                                        if let url = vm.generatedFileURL {
                                            ShareLink(item: url) {
                                                HStack {
                                                    Image(systemName: "square.and.arrow.up")
                                                    Text("Share")
                                                }
                                                .font(.headline)
                                                .foregroundStyle(.blue)
                                                .frame(maxWidth: .infinity)
                                                .padding()
                                                .background(Color.blue.opacity(0.15))
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                            }
                                        }
                                    }
                                    
                                    Button("Generate Again") {
                                        vm.generatePDF()
                                    }
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 4)
                                }
                                .padding(.horizontal)
                            } else {
                                Button(action: {
                                    vm.generatePDF()
                                }) {
                                    HStack {
                                        Image(systemName: "doc.badge.plus")
                                        Text("Generate PDF Report")
                                    }
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.accentColor)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                    .fullScreenCover(isPresented: $showingPreview) {
                        if let data = vm.pdfData {
                            PDFPreviewView(
                                title: reportType.title,
                                pdfData: data,
                                fileURL: vm.generatedFileURL
                            )
                        }
                    }
                    .alert("Error", isPresented: Bindable(vm).showError) {
                        Button("OK", role: .cancel) {}
                    } message: {
                        Text(vm.errorMessage ?? "Failed to compile PDF.")
                    }
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Export Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = ReportGenerationViewModel(
                        reportType: reportType,
                        requestingUser: requestingUser,
                        dataStore: dataStore
                    )
                }
            }
        }
    }
    
    private func infoBullet(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(.tint)
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
    }
}

#Preview {
    let store = AppDataStore()
    let student = store.users.first { $0.role == .student }!
    return ReportGenerationView(reportType: .student(student), requestingUser: student)
        .environment(store)
}
