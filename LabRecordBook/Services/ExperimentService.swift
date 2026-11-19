import Foundation
import Observation

public enum ExperimentServiceError: LocalizedError {
    case experimentNotFound
    case emptyFields
    case duplicateExperimentNumber
    case unauthorized
    case cannotEditLockedExperiment
    case cannotDeleteLockedExperiment
    case invalidStatusTransition
    case missingAssignedMentor
    case incompleteSubmission(String)
    case alreadySubmitted
    case alreadyVerified
    
    public var errorDescription: String? {
        switch self {
        case .experimentNotFound:
            return "Experiment could not be found."
        case .emptyFields:
            return "Experiment number, title, subject, aim, and procedure cannot be empty."
        case .duplicateExperimentNumber:
            return "An experiment with this number already exists for this subject. Please choose a unique number."
        case .unauthorized:
            return "You do not have permission to perform this action on this experiment."
        case .cannotEditLockedExperiment:
            return "This experiment is currently submitted or verified and cannot be edited."
        case .cannotDeleteLockedExperiment:
            return "Submitted or verified experiments cannot be deleted."
        case .invalidStatusTransition:
            return "This experiment cannot be submitted in its current status."
        case .missingAssignedMentor:
            return "You cannot submit an experiment without an assigned supervising mentor. Please contact your administrator."
        case .incompleteSubmission(let reason):
            return reason
        case .alreadySubmitted:
            return "This experiment is already submitted and awaiting mentor review."
        case .alreadyVerified:
            return "This experiment has already been verified and approved."
        }
    }
}

/// Service managing experiment records, lifecycle transitions, search, and permission checks.
@Observable
public final class ExperimentService {
    public let dataStore: AppDataStore
    
    public init(dataStore: AppDataStore) {
        self.dataStore = dataStore
    }
    
    // MARK: - Role-Based Authorized Queries
    
    /// Returns experiments authorized for the given user:
    /// - Admin: Views all experiments across the application.
    /// - Mentor: Views only experiments belonging to students assigned to that mentor.
    /// - Student: Views only their own experiments.
    public func getAuthorizedExperiments(for user: User) -> [Experiment] {
        switch user.role {
        case .admin:
            return getAllExperiments()
        case .mentor:
            return getExperiments(forMentorId: user.id)
        case .student:
            return getExperiments(forStudentId: user.id)
        }
    }
    
    public func getAllExperiments() -> [Experiment] {
        dataStore.experiments.sorted {
            $0.experimentNumber.localizedStandardCompare($1.experimentNumber) == .orderedAscending
        }
    }
    
    public func getExperiments(forStudentId studentId: UUID) -> [Experiment] {
        dataStore.experiments
            .filter { $0.studentId == studentId }
            .sorted {
                $0.experimentNumber.localizedStandardCompare($1.experimentNumber) == .orderedAscending
            }
    }
    
    public func getExperiments(forMentorId mentorId: UUID) -> [Experiment] {
        // Find students assigned to this mentor
        let assignedStudentIds = dataStore.users
            .filter { $0.role == .student && $0.assignedMentorId == mentorId }
            .map { $0.id }
        
        return dataStore.experiments
            .filter {
                if let sid = $0.studentId {
                    return assignedStudentIds.contains(sid) || $0.mentorId == mentorId
                } else {
                    return $0.mentorId == mentorId
                }
            }
            .sorted {
                $0.experimentNumber.localizedStandardCompare($1.experimentNumber) == .orderedAscending
            }
    }
    
    /// Returns master template experiments created by the mentor for assignment
    public func getMentorTemplates(forMentorId mentorId: UUID) -> [Experiment] {
        dataStore.experiments
            .filter { $0.mentorId == mentorId && $0.studentId == nil }
            .sorted {
                $0.experimentNumber.localizedStandardCompare($1.experimentNumber) == .orderedAscending
            }
    }
    
    public func getPendingReviews(forMentorId mentorId: UUID) -> [Experiment] {
        getExperiments(forMentorId: mentorId).filter { $0.status == .submitted }
    }
    
    public func getExperiment(byId id: UUID) -> Experiment? {
        dataStore.experiment(byId: id)
    }
    
    // MARK: - Search and Filtering
    
    /// Filters given experiments combining search query (title and experiment number),
    /// subject filter, status filter, department filter, and student filter simultaneously.
    public func filter(
        experiments: [Experiment],
        query: String,
        subjectId: UUID?,
        status: ExperimentStatus?,
        department: String? = nil,
        studentId: UUID? = nil
    ) -> [Experiment] {
        experiments.filter { exp in
            // Search text matches title, experiment number, or student name
            let matchesSearch: Bool
            let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if trimmedQuery.isEmpty {
                matchesSearch = true
            } else {
                let titleMatch = exp.title.lowercased().contains(trimmedQuery)
                let numMatch = exp.experimentNumber.lowercased().contains(trimmedQuery)
                let studentName = exp.studentId.flatMap { dataStore.user(byId: $0)?.name.lowercased() } ?? ""
                matchesSearch = titleMatch || numMatch || studentName.contains(trimmedQuery)
            }
            
            // Subject filter
            let matchesSubject: Bool
            if let subjectId = subjectId {
                matchesSubject = exp.subjectId == subjectId
            } else {
                matchesSubject = true
            }
            
            // Status filter
            let matchesStatus: Bool
            if let status = status {
                matchesStatus = exp.status == status
            } else {
                matchesStatus = true
            }
            
            // Department filter
            let matchesDepartment: Bool
            if let dept = department, !dept.isEmpty, dept != "All" {
                if let sid = exp.studentId, let student = dataStore.user(byId: sid) {
                    matchesDepartment = student.department.caseInsensitiveCompare(dept) == .orderedSame
                } else if let mid = exp.mentorId, let mentor = dataStore.user(byId: mid) {
                    matchesDepartment = mentor.department.caseInsensitiveCompare(dept) == .orderedSame
                } else {
                    matchesDepartment = false
                }
            } else {
                matchesDepartment = true
            }
            
            // Student filter
            let matchesStudent: Bool
            if let sid = studentId {
                matchesStudent = exp.studentId == sid
            } else {
                matchesStudent = true
            }
            
            return matchesSearch && matchesSubject && matchesStatus && matchesDepartment && matchesStudent
        }
    }
    
    // MARK: - Permissions & Validation
    
    public func canStudentEdit(experiment: Experiment, studentId: UUID) -> Bool {
        guard let expStudentId = experiment.studentId, expStudentId == studentId else { return false }
        // Cannot edit if submitted or verified; can edit if assigned, pending, completed, or rejected
        return experiment.status != .submitted && experiment.status != .verified
    }
    
    public func canStudentDelete(experiment: Experiment, studentId: UUID) -> Bool {
        guard let expStudentId = experiment.studentId, expStudentId == studentId else { return false }
        // Prevent deletion of experiments that are submitted for verification or verified
        return experiment.status != .submitted && experiment.status != .verified
    }
    
    // MARK: - Mutations
    
    /// Creates a new experiment after validating all fields and enforcing unique experiment number per subject for the student.
    @discardableResult
    public func createExperiment(
        experimentNumber: String,
        title: String,
        subjectId: UUID,
        studentId: UUID,
        date: Date = Date(),
        aim: String,
        procedure: String,
        result: String = "",
        isAssignedByMentor: Bool = false,
        mentorId: UUID? = nil,
        assignmentId: UUID? = nil
    ) throws -> Experiment {
        let trimmedExpNo = experimentNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAim = aim.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedProc = procedure.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedResult = result.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedExpNo.isEmpty, !trimmedTitle.isEmpty, !trimmedAim.isEmpty, !trimmedProc.isEmpty else {
            throw ExperimentServiceError.emptyFields
        }
        
        // Prevent duplicate experiment number for the same student and subject
        let duplicate = dataStore.experiments.contains {
            $0.studentId == studentId &&
            $0.subjectId == subjectId &&
            $0.experimentNumber.caseInsensitiveCompare(trimmedExpNo) == .orderedSame
        }
        if duplicate {
            throw ExperimentServiceError.duplicateExperimentNumber
        }
        
        // Look up student's mentor if not provided
        var effectiveMentorId = mentorId
        if effectiveMentorId == nil {
            effectiveMentorId = dataStore.user(byId: studentId)?.assignedMentorId
        }
        
        let newExp = Experiment(
            experimentNumber: trimmedExpNo,
            title: trimmedTitle,
            subjectId: subjectId,
            studentId: studentId,
            mentorId: effectiveMentorId,
            date: date,
            aim: trimmedAim,
            procedure: trimmedProc,
            result: trimmedResult,
            status: isAssignedByMentor ? .assigned : .pending,
            isAssignedByMentor: isAssignedByMentor,
            assignmentId: assignmentId,
            lastUpdated: Date()
        )
        
        dataStore.experiments.append(newExp)
        return newExp
    }
    
    /// Creates a master template experiment by a mentor.
    @discardableResult
    public func createMentorExperiment(
        mentor: User,
        experimentNumber: String,
        title: String,
        subjectId: UUID,
        date: Date = Date(),
        aim: String,
        procedure: String,
        result: String = ""
    ) throws -> Experiment {
        guard mentor.role == .mentor else {
            throw ExperimentServiceError.unauthorized
        }
        
        let trimmedExpNo = experimentNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAim = aim.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedProc = procedure.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedResult = result.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedExpNo.isEmpty, !trimmedTitle.isEmpty, !trimmedAim.isEmpty, !trimmedProc.isEmpty else {
            throw ExperimentServiceError.emptyFields
        }
        
        // Check for duplicate experiment number for this mentor and subject
        let duplicate = dataStore.experiments.contains {
            $0.mentorId == mentor.id &&
            $0.studentId == nil &&
            $0.subjectId == subjectId &&
            $0.experimentNumber.caseInsensitiveCompare(trimmedExpNo) == .orderedSame
        }
        if duplicate {
            throw ExperimentServiceError.duplicateExperimentNumber
        }
        
        let template = Experiment(
            experimentNumber: trimmedExpNo,
            title: trimmedTitle,
            subjectId: subjectId,
            studentId: nil,
            mentorId: mentor.id,
            date: date,
            aim: trimmedAim,
            procedure: trimmedProc,
            result: trimmedResult,
            status: .pending,
            isAssignedByMentor: false,
            assignmentId: nil,
            lastUpdated: Date()
        )
        
        dataStore.experiments.append(template)
        return template
    }
    
    /// Updates an existing experiment, validating ownership, eligibility, and unique experiment number.
    public func updateExperiment(
        id: UUID,
        studentId: UUID,
        experimentNumber: String,
        title: String,
        subjectId: UUID,
        date: Date,
        aim: String,
        procedure: String,
        result: String,
        status: ExperimentStatus? = nil
    ) throws {
        guard let index = dataStore.experiments.firstIndex(where: { $0.id == id }) else {
            throw ExperimentServiceError.experimentNotFound
        }
        
        let existing = dataStore.experiments[index]
        guard existing.studentId == studentId else {
            throw ExperimentServiceError.unauthorized
        }
        
        guard canStudentEdit(experiment: existing, studentId: studentId) else {
            throw ExperimentServiceError.cannotEditLockedExperiment
        }
        
        let trimmedExpNo = experimentNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAim = aim.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedProc = procedure.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedResult = result.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedExpNo.isEmpty, !trimmedTitle.isEmpty, !trimmedAim.isEmpty, !trimmedProc.isEmpty else {
            throw ExperimentServiceError.emptyFields
        }
        
        // Check for duplicate experiment number for same student and subject excluding self
        let duplicate = dataStore.experiments.contains {
            $0.id != id &&
            $0.studentId == studentId &&
            $0.subjectId == subjectId &&
            $0.experimentNumber.caseInsensitiveCompare(trimmedExpNo) == .orderedSame
        }
        if duplicate {
            throw ExperimentServiceError.duplicateExperimentNumber
        }
        
        var updated = existing
        updated.experimentNumber = trimmedExpNo
        updated.title = trimmedTitle
        updated.subjectId = subjectId
        updated.date = date
        updated.aim = trimmedAim
        updated.procedure = trimmedProc
        updated.result = trimmedResult
        updated.lastUpdated = Date()
        
        if let newStatus = status {
            updated.status = newStatus
        }
        
        dataStore.experiments[index] = updated
    }
    
    /// Deletes an eligible experiment, safely updating any associated assignments.
    public func deleteExperiment(id: UUID, studentId: UUID) throws {
        guard let index = dataStore.experiments.firstIndex(where: { $0.id == id }) else {
            throw ExperimentServiceError.experimentNotFound
        }
        
        let existing = dataStore.experiments[index]
        guard existing.studentId == studentId else {
            throw ExperimentServiceError.unauthorized
        }
        
        guard canStudentDelete(experiment: existing, studentId: studentId) else {
            throw ExperimentServiceError.cannotDeleteLockedExperiment
        }
        
        // If linked to an assignment, safely unlink it
        if let assignmentId = existing.assignmentId,
           let assignIndex = dataStore.assignments.firstIndex(where: { $0.id == assignmentId }) {
            dataStore.assignments[assignIndex].experimentId = nil
            dataStore.assignments[assignIndex].isCompleted = false
        }
        
        dataStore.experiments.remove(at: index)
    }
    
    public func submitExperiment(id: UUID, studentId: UUID) throws {
        guard let index = dataStore.experiments.firstIndex(where: { $0.id == id }) else {
            throw ExperimentServiceError.experimentNotFound
        }
        
        let existing = dataStore.experiments[index]
        guard existing.studentId == studentId else {
            throw ExperimentServiceError.unauthorized
        }
        
        if existing.status == .submitted {
            throw ExperimentServiceError.alreadySubmitted
        }
        
        if existing.status == .verified {
            throw ExperimentServiceError.alreadyVerified
        }
        
        guard existing.status.isEligibleForSubmission else {
            throw ExperimentServiceError.invalidStatusTransition
        }
        
        // Form validations before submission
        let trimmedTitle = existing.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAim = existing.aim.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedProc = existing.procedure.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedResult = existing.result.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedTitle.isEmpty else {
            throw ExperimentServiceError.incompleteSubmission("Experiment title cannot be empty.")
        }
        guard !trimmedAim.isEmpty else {
            throw ExperimentServiceError.incompleteSubmission("Experiment aim cannot be empty.")
        }
        guard !trimmedProc.isEmpty else {
            throw ExperimentServiceError.incompleteSubmission("Algorithm or procedure cannot be empty.")
        }
        guard !trimmedResult.isEmpty else {
            throw ExperimentServiceError.incompleteSubmission("Experiment results cannot be empty. Please record experimental results before submitting.")
        }
        
        // Verify student has an assigned active mentor
        guard let student = dataStore.user(byId: studentId),
              let mentorId = student.assignedMentorId,
              let mentor = dataStore.user(byId: mentorId),
              mentor.isActive else {
            throw ExperimentServiceError.missingAssignedMentor
        }
        
        // Verify mentor still supervises this student
        guard mentor.assignedStudentIds.contains(studentId) else {
            throw ExperimentServiceError.missingAssignedMentor
        }
        
        var updated = existing
        updated.status = .submitted
        updated.mentorId = mentorId
        updated.lastUpdated = Date()
        
        dataStore.experiments[index] = updated
    }
}
