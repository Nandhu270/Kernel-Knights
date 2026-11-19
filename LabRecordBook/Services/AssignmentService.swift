import Foundation
import Observation

public enum AssignmentServiceError: LocalizedError {
    case emptyFields
    case unauthorized
    case studentNotAssignedToMentor
    case duplicateAssignment
    case experimentNotFound
    case noStudentsSelected
    
    public var errorDescription: String? {
        switch self {
        case .emptyFields:
            return "Assignment title, aim, and procedure are required."
        case .unauthorized:
            return "You are not authorized to perform this assignment operation."
        case .studentNotAssignedToMentor:
            return "You can only assign experiments to students currently assigned to you."
        case .duplicateAssignment:
            return "This experiment has already been actively assigned to one or more selected students."
        case .experimentNotFound:
            return "The experiment to be assigned could not be found."
        case .noStudentsSelected:
            return "Please select at least one student to receive the assignment."
        }
    }
}

/// Service managing mentor experiment assignments, student tracking, and assignment records.
@Observable
public final class AssignmentService {
    public let dataStore: AppDataStore
    
    public init(dataStore: AppDataStore) {
        self.dataStore = dataStore
    }
    
    // MARK: - Queries with Role-Based Permissions
    
    /// Returns assignments for a student with permission checks:
    /// - Student: can view only their own assignments
    /// - Mentor: can view only if the student is assigned to them
    /// - Admin: can view all
    public func getAssignments(forStudentId studentId: UUID, requestingUser: User? = nil) -> [Assignment] {
        if let user = requestingUser {
            switch user.role {
            case .student:
                guard user.id == studentId else { return [] }
            case .mentor:
                guard user.assignedStudentIds.contains(studentId) else { return [] }
            case .admin:
                break
            }
        }
        
        return dataStore.assignments
            .filter { $0.studentId == studentId }
            .sorted { $0.assignedDate > $1.assignedDate }
    }
    
    /// Returns assignments for a mentor with permission checks:
    /// - Mentor: can view only their own assignments
    /// - Admin: can view all
    /// - Student: not authorized (returns empty)
    public func getAssignments(forMentorId mentorId: UUID, requestingUser: User? = nil) -> [Assignment] {
        if let user = requestingUser {
            switch user.role {
            case .mentor:
                guard user.id == mentorId else { return [] }
            case .admin:
                break
            case .student:
                return []
            }
        }
        
        return dataStore.assignments
            .filter { $0.mentorId == mentorId }
            .sorted { $0.assignedDate > $1.assignedDate }
    }
    
    /// Returns all students assigned to a specific mentor.
    public func getAssignedStudents(forMentor mentor: User) -> [User] {
        guard mentor.role == .mentor else { return [] }
        return dataStore.users.filter {
            $0.role == .student &&
            $0.assignedMentorId == mentor.id &&
            $0.isActive
        }
    }
    
    /// Returns assignment by id
    public func getAssignment(byId id: UUID) -> Assignment? {
        dataStore.assignments.first { $0.id == id }
    }
    
    // MARK: - Search and Filtering
    
    /// Filters assignments by search query (title or experiment number), student, and status.
    public func filter(
        assignments: [Assignment],
        query: String,
        studentId: UUID?,
        status: AssignmentStatus?
    ) -> [Assignment] {
        assignments.filter { assignment in
            // Search query matches title or experiment number
            let matchesQuery: Bool
            let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if trimmed.isEmpty {
                matchesQuery = true
            } else {
                matchesQuery = assignment.title.lowercased().contains(trimmed) ||
                               assignment.experimentNumber.lowercased().contains(trimmed)
            }
            
            // Student filter
            let matchesStudent: Bool
            if let sid = studentId {
                matchesStudent = assignment.studentId == sid
            } else {
                matchesStudent = true
            }
            
            // Status filter
            let matchesStatus: Bool
            if let st = status {
                matchesStatus = assignment.status == st
            } else {
                matchesStatus = true
            }
            
            return matchesQuery && matchesStudent && matchesStatus
        }
    }
    
    // MARK: - Mentor Assignment Creation
    
    /// Assigns an experiment template to one or multiple students under mentor supervision.
    /// Creates a distinct, independent Assignment record and independent Experiment record for each student.
    @discardableResult
    public func assignExperiment(
        templateId: UUID,
        toStudentIds studentIds: [UUID],
        byMentor mentor: User,
        dueDate: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    ) throws -> [Assignment] {
        guard mentor.role == .mentor else {
            throw AssignmentServiceError.unauthorized
        }
        
        guard !studentIds.isEmpty else {
            throw AssignmentServiceError.noStudentsSelected
        }
        
        guard let template = dataStore.experiment(byId: templateId) else {
            throw AssignmentServiceError.experimentNotFound
        }
        
        // Mentor must supervise this experiment template
        guard template.mentorId == mentor.id else {
            throw AssignmentServiceError.unauthorized
        }
        
        // Verify all target students are actively assigned to this mentor
        for studentId in studentIds {
            guard mentor.assignedStudentIds.contains(studentId) else {
                throw AssignmentServiceError.studentNotAssignedToMentor
            }
            guard let student = dataStore.user(byId: studentId),
                  student.assignedMentorId == mentor.id,
                  student.isActive else {
                throw AssignmentServiceError.studentNotAssignedToMentor
            }
        }
        
        // Prevent duplicate active assignments for the same experiment and student
        for studentId in studentIds {
            let hasActive = dataStore.assignments.contains {
                $0.experimentId == templateId &&
                $0.studentId == studentId &&
                !$0.isCompleted
            }
            if hasActive {
                throw AssignmentServiceError.duplicateAssignment
            }
        }
        
        var createdAssignments: [Assignment] = []
        
        for studentId in studentIds {
            // 1. Create separate assignment record for this student
            var assignment = Assignment(
                mentorId: mentor.id,
                studentId: studentId,
                subjectId: template.subjectId,
                title: template.title,
                aim: template.aim,
                procedure: template.procedure,
                experimentNumber: template.experimentNumber,
                assignedDate: Date(),
                dueDate: dueDate,
                status: .pending,
                isCompleted: false,
                experimentId: template.id
            )
            
            // 2. Create independent student experiment record with own ID
            let studentCopy = Experiment(
                experimentNumber: template.experimentNumber,
                title: template.title,
                subjectId: template.subjectId,
                studentId: studentId,
                mentorId: mentor.id,
                date: Date(),
                aim: template.aim,
                procedure: template.procedure,
                result: "",
                status: .assigned,
                isAssignedByMentor: true,
                assignmentId: assignment.id,
                lastUpdated: Date()
            )
            
            // 3. Link student's copy ID to the assignment
            assignment.studentExperimentId = studentCopy.id
            
            dataStore.assignments.append(assignment)
            dataStore.experiments.append(studentCopy)
            createdAssignments.append(assignment)
        }
        
        return createdAssignments
    }
    
    /// Legacy convenience creation for single assignment with inline text (preserves backwards compatibility)
    @discardableResult
    public func createAssignment(
        mentor: User,
        studentId: UUID,
        subjectId: UUID,
        title: String,
        aim: String,
        procedure: String,
        dueDate: Date
    ) throws -> Assignment {
        guard mentor.role == .mentor else {
            throw AssignmentServiceError.unauthorized
        }
        
        guard mentor.assignedStudentIds.contains(studentId) else {
            throw AssignmentServiceError.studentNotAssignedToMentor
        }
        
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAim = aim.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedProc = procedure.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedTitle.isEmpty, !trimmedAim.isEmpty, !trimmedProc.isEmpty else {
            throw AssignmentServiceError.emptyFields
        }
        
        let count = dataStore.experiments.count + 1
        let expNumber = String(format: "EXP-%02d", count)
        
        // Create master template
        let template = Experiment(
            experimentNumber: expNumber,
            title: trimmedTitle,
            subjectId: subjectId,
            studentId: nil,
            mentorId: mentor.id,
            date: Date(),
            aim: trimmedAim,
            procedure: trimmedProc,
            result: "",
            status: .pending,
            isAssignedByMentor: false,
            assignmentId: nil,
            lastUpdated: Date()
        )
        dataStore.experiments.append(template)
        
        // Delegate to assignExperiment
        let results = try assignExperiment(
            templateId: template.id,
            toStudentIds: [studentId],
            byMentor: mentor,
            dueDate: dueDate
        )
        
        return results.first!
    }
}
