import SwiftUI
import PDFKit
import UIKit

/// UIViewRepresentable wrapper for native Apple PDFKit PDFView.
public struct PDFKitView: UIViewRepresentable {
    public let data: Data
    
    public init(data: Data) {
        self.data = data
    }
    
    public func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.document = PDFDocument(data: data)
        return pdfView
    }
    
    public func updateUIView(_ uiView: PDFView, context: Context) {
        if uiView.document == nil || uiView.document?.dataRepresentation() != data {
            uiView.document = PDFDocument(data: data)
        }
    }
}

/// UIViewControllerRepresentable wrapper for UIActivityViewController share sheet.
public struct ActivityViewController: UIViewControllerRepresentable {
    public let activityItems: [Any]
    public var applicationActivities: [UIActivity]? = nil
    
    public init(activityItems: [Any], applicationActivities: [UIActivity]? = nil) {
        self.activityItems = activityItems
        self.applicationActivities = applicationActivities
    }
    
    public func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }
    
    public func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

/// Fullscreen preview view for rendered PDF documents with native sharing.
public struct PDFPreviewView: View {
    public let title: String
    public let pdfData: Data
    public let fileURL: URL?
    
    @Environment(\.dismiss) private var dismiss
    @State private var showingShareSheet: Bool = false
    
    public init(title: String = "Report Preview", pdfData: Data, fileURL: URL? = nil) {
        self.title = title
        self.pdfData = pdfData
        self.fileURL = fileURL
    }
    
    public var body: some View {
        NavigationStack {
            PDFKitView(data: pdfData)
                .edgesIgnoringSafeArea(.bottom)
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        if let url = fileURL {
                            ShareLink(item: url) {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                        } else {
                            Button(action: { showingShareSheet = true }) {
                                Image(systemName: "square.and.arrow.up")
                            }
                        }
                    }
                }
                .sheet(isPresented: $showingShareSheet) {
                    if let url = fileURL {
                        ActivityViewController(activityItems: [url])
                    } else {
                        ActivityViewController(activityItems: [pdfData])
                    }
                }
        }
    }
}

#Preview {
    let dummyData = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 300, height: 400)).pdfData { ctx in
        ctx.beginPage()
        ("Sample PDF Preview" as NSString).draw(at: CGPoint(x: 50, y: 50), withAttributes: nil)
    }
    return PDFPreviewView(title: "Sample PDF", pdfData: dummyData)
}
