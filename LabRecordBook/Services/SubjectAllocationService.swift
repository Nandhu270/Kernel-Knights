import Foundation
import Observation

public enum SubjectAllocationError: LocalizedError {
    case subjectNotFound
    case mentorNotFound
    case studentNotFound
    case mentorNotAssignedToSubject
    case duplicateMentorAllocation
    case duplicateStudentAllocation
    case studentAlreadyAllocatedWithSameMentor
    case inactiveSubject
    case inactiveUser
    case unauthorized
    
    public var errorDescription: String? {
        switch self {
        case .subjectNotFound:
            return "Course subject could not be found."
        case .mentorNotFound:
            return "Mentor account could not be found."
        case .studentNotFound:
            return "Student account could not be found."
        case .mentorNotAssignedToSubject:
            return "This mentor is not assigned to teach or supervise this course subject. Please assign the mentor to the subject first."
        case .duplicateMentorAllocation:
            return "This mentor is already actively assigned to this course subject."
        case .duplicateStudentAllocation:
            return "This student is already actively allocated to this course subject. Use reassign to change the supervising mentor."
        case .studentAlreadyAllocatedWithSameMentor:
            return "The student is already allocated to this mentor for this subject."
        case .inactiveSubject:
            return "Cannot allocate to an inactive or archived course subject."
        case .inactiveUser:
            return "Cannot allocate an inactive user account."
        case .unauthorized:
            return "You do not have permission to perform subject allocation."
        }
    }
}

/// Service managing academic allocations:
/// - Admin allocation of Mentors to Subjects
/// - Admin allocation of Students to Subjects under specific Mentors
/// - Uniqueness enforcement and non-destructive historical reassignment tracking
@Observable
public final class SubjectAllocationService {
    public let dataStore: AppDataStore
    
    public init(dataStore: AppDataStore) {
        self.dataStore = dataStore
    }
    
    // MARK: - Mentor-to-Subject Management
    
    /// Assigns a mentor to teach/supervise a course subject.
    @discardableResult
    public func assignMentorToSubject(mentorId: UUID, subjectId: UUID) throws -> MentorSubjectAssignment {
        guard let subject = dataStore.subject(byId: subjectId) else {
            throw SubjectAllocationError.subjectNotFound
        }
        guard subject.isActive else {
            throw SubjectAllocationError.inactiveSubject
        }
        guard let mentor = dataStore.user(byId: mentorId), mentor.role == .mentor else {
            throw SubjectAllocationError.mentorNotFound
        }
        guard mentor.isActive else {
            throw SubjectAllocationError.inactiveUser
        }
        
        // Prevent duplicate active mentor allocation
        let hasActive = dataStore.mentorSubjectAssignments.contains {
            $0.mentorId == mentorId && $0.subjectId == subjectId && $0.isActive
        }
        if hasActive {
            throw SubjectAllocationError.duplicateMentorAllocation
        }
        
        let assignment = MentorSubjectAssignment(
            mentorId: mentorId,
            subjectId: subjectId,
            assignedDate: Date(),
            isActive: true
        )
        dataStore.mentorSubjectAssignments.append(assignment)
        return assignment
    }
    
    /// Deactivates a mentor's teaching allocation for a subject (preserves history non-destructively).
    public func removeMentorFromSubject(mentorId: UUID, subjectId: UUID) throws {
        var found = false
        for i in 0..<dataStore.mentorSubjectAssignments.count {
            if dataStore.mentorSubjectAssignments[i].mentorId == mentorId &&
                dataStore.mentorSubjectAssignments[i].subjectId == subjectId &&
                dataStore.mentorSubjectAssignments[i].isActive {
                dataStore.mentorSubjectAssignments[i].isActive = false
                found = true
            }
        }
        
        if !found {
            throw SubjectAllocationError.mentorNotAssignedToSubject
        }
    }
    
    /// Returns all mentors actively assigned to teach a subject.
    public func getMentors(forSubjectId subjectId: UUID) -> [User] {
        let activeMentorIds = Set(dataStore.mentorSubjectAssignments
            .filter { $0.subjectId == subjectId && $0.isActive }
            .map { $0.mentorId })
        return dataStore.users.filter { activeMentorIds.contains($0.id) && $0.isActive }
    }
    
    /// Returns all active subjects taught by a mentor.
    public func getSubjects(forMentorId mentorId: UUID) -> [Subject] {
        let activeSubjectIds = Set(dataStore.mentorSubjectAssignments
            .filter { $0.mentorId == mentorId && $0.isActive }
            .map { $0.subjectId })
        return dataStore.subjects.filter { activeSubjectIds.contains($0.id) && $0.isActive }
    }
    
    /// Checks whether a mentor is actively assigned to teach a subject.
    public func isMentorAssigned(mentorId: UUID, subjectId: UUID) -> Bool {
        dataStore.mentorSubjectAssignments.contains {
            $0.mentorId == mentorId && $0.subjectId == subjectId && $0.isActive
        }
    }
    
    // MARK: - Student-Subject-Mentor Allocation
    
    /// Allocates a student to a course subject under a specific supervising mentor.
    /// Enforces:
    /// - Subject must be active
    /// - Student must be active
    /// - Mentor must be active and assigned to the subject
    /// - Exactly one active allocation per student per subject
    @discardableResult
    public func allocateStudentToSubject(
        studentId: UUID,
        subjectId: UUID,
        mentorId: UUID
    ) throws -> StudentSubjectAssignment {
        guard let subject = dataStore.subject(byId: subjectId) else {
            throw SubjectAllocationError.subjectNotFound
        }
        guard subject.isActive else {
            throw SubjectAllocationError.inactiveSubject
        }
        guard let student = dataStore.user(byId: studentId), student.role == .student else {
            throw SubjectAllocationError.studentNotFound
        }
        guard student.isActive else {
            throw SubjectAllocationError.inactiveUser
        }
        guard let mentor = dataStore.user(byId: mentorId), mentor.role == .mentor else {
            throw SubjectAllocationError.mentorNotFound
        }
        guard mentor.isActive else {
            throw SubjectAllocationError.inactiveUser
        }
        
        // Mentor must be assigned to teach this subject
        guard isMentorAssigned(mentorId: mentorId, subjectId: subjectId) else {
            throw SubjectAllocationError.mentorNotAssignedToSubject
        }
        
        // Ensure student does not already have an active allocation for this subject
        if dataStore.activeStudentSubjectAssignment(studentId: studentId, subjectId: subjectId) != nil {
            throw SubjectAllocationError.duplicateStudentAllocation
        }
        
        let assignment = StudentSubjectAssignment(
            studentId: studentId,
            subjectId: subjectId,
            mentorId: mentorId,
            assignedDate: Date(),
            isActive: true
        )
        dataStore.studentSubjectAssignments.append(assignment)
        
        // Maintain legacy properties non-destructively for backward compatibility
        syncLegacyUserRelationships(studentId: studentId, mentorId: mentorId)
        
        return assignment
    }
    
    /// Reassigns a student's supervising mentor within a subject:
    /// 1. Deactivates previous allocation (isActive = false)
    /// 2. Preserves historical allocation records
    /// 3. Creates a new active allocation
    /// 4. Historical experiments & verifications remain untouched
    /// 5. Future submissions will resolve to the new mentor
    @discardableResult
    public func reassignStudentMentor(
        studentId: UUID,
        subjectId: UUID,
        newMentorId: UUID
    ) throws -> StudentSubjectAssignment {
        guard let subject = dataStore.subject(byId: subjectId) else {
            throw SubjectAllocationError.subjectNotFound
        }
        guard subject.isActive else {
            throw SubjectAllocationError.inactiveSubject
        }
        guard let student = dataStore.user(byId: studentId), student.role == .student else {
            throw SubjectAllocationError.studentNotFound
        }
        guard student.isActive else {
            throw SubjectAllocationError.inactiveUser
        }
        guard let newMentor = dataStore.user(byId: newMentorId), newMentor.role == .mentor else {
            throw SubjectAllocationError.mentorNotFound
        }
        guard newMentor.isActive else {
            throw SubjectAllocationError.inactiveUser
        }
        
        // New mentor must be assigned to teach this subject
        guard isMentorAssigned(mentorId: newMentorId, subjectId: subjectId) else {
            throw SubjectAllocationError.mentorNotAssignedToSubject
        }
        
        // Check current active allocation
        if let current = dataStore.activeStudentSubjectAssignment(studentId: studentId, subjectId: subjectId) {
            if current.mentorId == newMentorId {
                throw SubjectAllocationError.studentAlreadyAllocatedWithSameMentor
            }
            // Deactivate previous active allocation
            for i in 0..<dataStore.studentSubjectAssignments.count {
                if dataStore.studentSubjectAssignments[i].studentId == studentId &&
                    dataStore.studentSubjectAssignments[i].subjectId == subjectId &&
                    dataStore.studentSubjectAssignments[i].isActive {
                    dataStore.studentSubjectAssignments[i].isActive = false
                }
            }
        }
        
        // Create new active allocation
        let newAssignment = StudentSubjectAssignment(
            studentId: studentId,
            subjectId: subjectId,
            mentorId: newMentorId,
            assignedDate: Date(),
            isActive: true
        )
        dataStore.studentSubjectAssignments.append(newAssignment)
        
        // Maintain legacy properties non-destructively
        syncLegacyUserRelationships(studentId: studentId, mentorId: newMentorId)
        
        return newAssignment
    }
    
    /// Deactivates a student's allocation to a subject (preserves record history).
    public func removeStudentFromSubject(studentId: UUID, subjectId: UUID) throws {
        var found = false
        for i in 0..<dataStore.studentSubjectAssignments.count {
            if dataStore.studentSubjectAssignments[i].studentId == studentId &&
                dataStore.studentSubjectAssignments[i].subjectId == subjectId &&
                dataStore.studentSubjectAssignments[i].isActive {
                dataStore.studentSubjectAssignments[i].isActive = false
                found = true
            }
        }
        if !found {
            throw SubjectAllocationError.studentNotFound
        }
    }
    
    // MARK: - Query Helpers
    
    /// Returns the active allocation record for a student in a subject.
    public func getActiveAllocation(studentId: UUID, subjectId: UUID) -> StudentSubjectAssignment? {
        dataStore.activeStudentSubjectAssignment(studentId: studentId, subjectId: subjectId)
    }
    
    /// Returns the supervising mentor for a student in a specific subject.
    public func getAllocatedMentor(studentId: UUID, subjectId: UUID) -> User? {
        guard let allocation = getActiveAllocation(studentId: studentId, subjectId: subjectId) else {
            return nil
        }
        return dataStore.user(byId: allocation.mentorId)
    }
    
    /// Returns all students actively allocated to a subject, optionally filtered by mentor.
    public func getStudents(forSubjectId subjectId: UUID, mentorId: UUID? = nil) -> [User] {
        let activeStudentIds: Set<UUID>
        if let mid = mentorId {
            activeStudentIds = Set(dataStore.studentSubjectAssignments
                .filter { $0.subjectId == subjectId && $0.mentorId == mid && $0.isActive }
                .map { $0.studentId })
        } else {
            activeStudentIds = Set(dataStore.studentSubjectAssignments
                .filter { $0.subjectId == subjectId && $0.isActive }
                .map { $0.studentId })
        }
        return dataStore.users.filter { activeStudentIds.contains($0.id) && $0.isActive }
    }
    
    /// Returns all active subjects in which a student is enrolled under a mentor.
    public func getSubjects(forStudentId studentId: UUID) -> [Subject] {
        let activeSubjectIds = Set(dataStore.studentSubjectAssignments
            .filter { $0.studentId == studentId && $0.isActive }
            .map { $0.subjectId })
        return dataStore.subjects.filter { activeSubjectIds.contains($0.id) && $0.isActive }
    }
    
    /// Returns complete historical allocation records for auditing.
    public func getAllocationsHistory(studentId: UUID, subjectId: UUID) -> [StudentSubjectAssignment] {
        dataStore.studentSubjectAssignments
            .filter { $0.studentId == studentId && $0.subjectId == subjectId }
            .sorted { $0.assignedDate > $1.assignedDate }
    }
    
    // MARK: - Legacy Synchronization
    
    private func syncLegacyUserRelationships(studentId: UUID, mentorId: UUID) {
        if let sIndex = dataStore.users.firstIndex(where: { $0.id == studentId }) {
            if dataStore.users[sIndex].assignedMentorId == nil {
                dataStore.users[sIndex].assignedMentorId = mentorId
            }
        }
        if let mIndex = dataStore.users.firstIndex(where: { $0.id == mentorId }) {
            if !dataStore.users[mIndex].assignedStudentIds.contains(studentId) {
                dataStore.users[mIndex].assignedStudentIds.append(studentId)
            }
        }
    }
}
