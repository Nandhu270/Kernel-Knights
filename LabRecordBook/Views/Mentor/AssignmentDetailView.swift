import SwiftUI

/// Detailed view of an assignment record displaying metadata, recipient student, and student experiment status.
public struct AssignmentDetailView: View {
    public let assignmentId: UUID
    public let currentUser: User
    
    @Environment(AppDataStore.self) private var dataStore
    
    public init(assignmentId: UUID, currentUser: User) {
        self.assignmentId = assignmentId
        self.currentUser = currentUser
    }
    
    private var assignment: Assignment? {
        dataStore.assignments.first { $0.id == assignmentId }
    }
    
    private var student: User? {
        guard let a = assignment else { return nil }
        return dataStore.user(byId: a.studentId)
    }
    
    private var mentor: User? {
        guard let a = assignment else { return nil }
        return dataStore.user(byId: a.mentorId)
    }
    
    private var subject: Subject? {
        guard let a = assignment else { return nil }
        return dataStore.subject(byId: a.subjectId)
    }
    
    private var studentExperiment: Experiment? {
        guard let a = assignment else { return nil }
        if let sid = a.studentExperimentId {
            return dataStore.experiment(byId: sid)
        }
        return dataStore.experiments.first { $0.assignmentId == a.id && $0.studentId == a.studentId }
    }
    
    public var body: some View {
        ScrollView {
            if let a = assignment {
                VStack(spacing: 20) {
                    // Header Card
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            if !a.experimentNumber.isEmpty {
                                Text(a.experimentNumber)
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.tint)
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(a.isCompleted ? Color.green : Color.orange)
                                    .frame(width: 8, height: 8)
                                Text(a.status.displayName)
                                    .font(.caption)
                                    .fontWeight(.bold)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                (a.isCompleted ? Color.green : Color.orange).opacity(0.12)
                            )
                            .foregroundStyle(a.isCompleted ? Color.green : Color.orange)
                            .clipShape(Capsule())
                        }
                        
                        Text(a.title)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        if let subj = subject {
                            HStack(spacing: 6) {
                                Image(systemName: "book.closed.fill")
                                    .foregroundStyle(.secondary)
                                Text("\(subj.code) - \(subj.name)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    // Metadata Card
                    VStack(alignment: .leading, spacing: 12) {
                        if let s = student {
                            infoRow(
                                icon: "graduationcap.fill",
                                title: "Assigned Student",
                                value: "\(s.name) (@\(s.username)) • \(s.department)",
                                color: .blue
                            )
                        }
                        
                        if let m = mentor {
                            infoRow(
                                icon: "person.crop.rectangle.badge.plus",
                                title: "Supervising Mentor",
                                value: m.name,
                                color: .indigo
                            )
                        }
                        
                        infoRow(
                            icon: "calendar",
                            title: "Assigned Date",
                            value: DateFormatter.localizedString(from: a.assignedDate, dateStyle: .medium, timeStyle: .none),
                            color: .secondary
                        )
                        
                        infoRow(
                            icon: "clock.badge.exclamationmark",
                            title: "Due Date",
                            value: DateFormatter.localizedString(from: a.dueDate, dateStyle: .medium, timeStyle: .none),
                            color: .orange
                        )
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    // Student's Independent Experiment Record Status
                    if let exp = studentExperiment {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Student's Record Progress")
                                .font(.headline)
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Status: \(exp.status.displayName)")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Text("Last updated: \(DateFormatter.localizedString(from: exp.lastUpdated, dateStyle: .short, timeStyle: .short))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                NavigationLink(destination: ExperimentDetailView(experimentId: exp.id, currentUser: currentUser)) {
                                    Text("View Record")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue)
                                        .foregroundStyle(.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    
                    // Experiment Aim
                    contentCard(
                        title: "Aim / Objective",
                        icon: "target",
                        content: a.aim,
                        accentColor: .blue
                    )
                    
                    // Procedure
                    contentCard(
                        title: "Procedure / Instructions",
                        icon: "list.number",
                        content: a.procedure,
                        accentColor: .indigo
                    )
                }
                .padding()
            } else {
                EmptyStateView(
                    iconName: "questionmark.folder.fill",
                    title: "Assignment Not Found",
                    message: "This assignment could not be loaded."
                )
            }
        }
        .navigationTitle("Assignment Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    @ViewBuilder
    private func infoRow(icon: String, title: String, value: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
        }
    }
    
    @ViewBuilder
    private func contentCard(title: String, icon: String, content: String, accentColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(accentColor)
                Text(title)
                    .font(.headline)
            }
            
            Text(content.isEmpty ? "None provided." : content)
                .font(.body)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    let store = AppDataStore()
    let assign = store.assignments.first!
    let mentor = store.users.first { $0.role == .mentor }!
    return NavigationStack {
        AssignmentDetailView(assignmentId: assign.id, currentUser: mentor)
            .environment(store)
    }
}
