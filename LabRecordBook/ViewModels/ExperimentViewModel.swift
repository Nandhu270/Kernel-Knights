import Foundation
import Observation

/// ViewModel managing experiment list filtering, searching, and selection.
@Observable
public final class ExperimentViewModel {
    public let dataStore: AppDataStore
    public let experimentService: ExperimentService
    public let subjectService: SubjectService
    
    public var searchText: String = ""
    public var selectedSubjectId: UUID? = nil
    public var selectedStatus: ExperimentStatus? = nil
    
    public init(dataStore: AppDataStore) {
        self.dataStore = dataStore
        self.experimentService = ExperimentService(dataStore: dataStore)
        self.subjectService = SubjectService(dataStore: dataStore)
    }
    
    /// Filters given experiments based on search query, subject filter, and status filter.
    public func filter(experiments: [Experiment]) -> [Experiment] {
        experiments.filter { exp in
            // Search text matches title or experiment number
            let matchesSearch: Bool
            if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                matchesSearch = true
            } else {
                let query = searchText.lowercased()
                matchesSearch = exp.title.lowercased().contains(query) ||
                               exp.experimentNumber.lowercased().contains(query)
            }
            
            // Subject filter
            let matchesSubject: Bool
            if let selectedSubjectId = selectedSubjectId {
                matchesSubject = exp.subjectId == selectedSubjectId
            } else {
                matchesSubject = true
            }
            
            // Status filter
            let matchesStatus: Bool
            if let selectedStatus = selectedStatus {
                matchesStatus = exp.status == selectedStatus
            } else {
                matchesStatus = true
            }
            
            return matchesSearch && matchesSubject && matchesStatus
        }
    }
}
