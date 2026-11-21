import SwiftUI

/// Reusable card displaying an overall circular progress ring and status breakdown.
public struct ProgressSummaryCard: View {
    public let title: String
    public let percentage: Double
    public let totalCount: Int
    public let verifiedCount: Int
    public let pendingCount: Int
    public let rejectedCount: Int
    public let tintColor: Color
    
    public init(
        title: String = "Overall Completion",
        percentage: Double,
        totalCount: Int,
        verifiedCount: Int,
        pendingCount: Int,
        rejectedCount: Int = 0,
        tintColor: Color = .blue
    ) {
        self.title = title
        self.percentage = max(0.0, min(100.0, percentage))
        self.totalCount = totalCount
        self.verifiedCount = verifiedCount
        self.pendingCount = pendingCount
        self.rejectedCount = rejectedCount
        self.tintColor = tintColor
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
            
            HStack(spacing: 20) {
                // Circular Progress Ring
                ZStack {
                    Circle()
                        .stroke(tintColor.opacity(0.18), lineWidth: 10)
                        .frame(width: 86, height: 86)
                    
                    Circle()
                        .trim(from: 0.0, to: CGFloat(percentage / 100.0))
                        .stroke(
                            tintColor,
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .frame(width: 86, height: 86)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.4), value: percentage)
                    
                    VStack(spacing: 1) {
                        Text(String(format: "%.0f%%", percentage))
                            .font(.system(.title3, design: .rounded, weight: .bold))
                            .foregroundStyle(.primary)
                        Text("done")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.leading, 4)
                
                // Status breakdown metrics
                VStack(alignment: .leading, spacing: 8) {
                    metricRow(title: "Verified", count: verifiedCount, color: .green, icon: "checkmark.seal.fill")
                    metricRow(title: "Pending", count: pendingCount, color: .orange, icon: "hourglass.circle.fill")
                    if rejectedCount > 0 {
                        metricRow(title: "Needs Revision", count: rejectedCount, color: .red, icon: "exclamationmark.triangle.fill")
                    }
                    metricRow(title: "Total", count: totalCount, color: .primary, icon: "doc.text.fill")
                }
                
                Spacer()
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func metricRow(title: String, count: Int, color: Color, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
                .frame(width: 16)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text("\(count)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
        }
    }
}

#Preview {
    ProgressSummaryCard(
        percentage: 66.7,
        totalCount: 6,
        verifiedCount: 4,
        pendingCount: 1,
        rejectedCount: 1,
        tintColor: .blue
    )
    .padding()
}
