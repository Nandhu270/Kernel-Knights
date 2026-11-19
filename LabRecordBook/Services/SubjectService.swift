import Foundation
import Observation

/// Service for querying and filtering course subjects.
@Observable
public final class SubjectService {
    public let dataStore: AppDataStore
    
    public init(dataStore: AppDataStore) {
        self.dataStore = dataStore
    }
    
    public func getAllSubjects() -> [Subject] {
        dataStore.subjects
    }
    
    public func getSubject(byId id: UUID) -> Subject? {
        dataStore.subject(byId: id)
    }
}
