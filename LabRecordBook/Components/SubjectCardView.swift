import SwiftUI

/// Reusable card component for displaying subject info, department, active badge, and progress or student counts.
public struct SubjectCardView: View {
    public let subject: Subject
    public let studentCount: Int?
    public let mentorCount: Int?
    public let completionPercentage: Double?
    public let verifiedCount: Int?
    public let totalCount: Int?
    
    public init(
        subject: Subject,
        studentCount: Int? = nil,
        mentorCount: Int? = nil,
        completionPercentage: Double? = nil,
        verifiedCount: Int? = nil,
        totalCount: Int? = nil
    ) {
        self.subject = subject
        self.studentCount = studentCount
        self.mentorCount = mentorCount
        self.completionPercentage = completionPercentage
        self.verifiedCount = verifiedCount
        self.totalCount = totalCount
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(subject.code)
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.blue.opacity(0.12))
                            .foregroundStyle(.blue)
                            .clipShape(Capsule())
                        
                        if !subject.isActive {
                            Text("Archived")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.2))
                                .foregroundStyle(.secondary)
                                .clipShape(Capsule())
                        }
                    }
                    
                    Text(subject.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                    
                    Text(subject.department)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 4)
            }
            
            if !subject.description.isEmpty {
                Text(subject.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            // Metrics or Progress Bar
            if let pct = completionPercentage {
                VStack(spacing: 4) {
                    HStack {
                        if let v = verifiedCount, let t = totalCount {
                            Text("\(v)/\(t) Verified")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(String(format: "%.0f%%", pct))
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(pct >= 100 ? .green : .blue)
                    }
                    ProgressBarView(
                        value: pct,
                        tintColor: pct >= 100 ? .green : .blue,
                        height: 5
                    )
                }
            } else {
                HStack(spacing: 12) {
                    if let sCount = studentCount {
                        HStack(spacing: 4) {
                            Image(systemName: "graduationcap.fill")
                                .font(.caption2)
                            Text("\(sCount) Student\(sCount == 1 ? "" : "s")")
                                .font(.caption2)
                        }
                        .foregroundStyle(.secondary)
                    }
                    if let mCount = mentorCount {
                        HStack(spacing: 4) {
                            Image(systemName: "person.crop.rectangle.badge.plus")
                                .font(.caption2)
                            Text("\(mCount) Mentor\(mCount == 1 ? "" : "s")")
                                .font(.caption2)
                        }
                        .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    let sub = Subject(
        name: "Data Structures & Algorithms",
        code: "CS201",
        description: "Fundamental data structures and sorting algorithms.",
        department: "Computer Science & Engineering",
        isActive: true
    )
    return SubjectCardView(
        subject: sub,
        studentCount: 3,
        mentorCount: 1,
        completionPercentage: 75,
        verifiedCount: 3,
        totalCount: 4
    )
    .padding()
}
