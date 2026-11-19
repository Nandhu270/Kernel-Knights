import SwiftUI

/// View displaying the complete verification history and audit log with search, status, and department filtering.
public struct StudentVerificationHistoryView: View {
    public let student: User
    public let experimentId: UUID?
    
    @Environment(AppDataStore.self) private var dataStore
    @State private var viewModel: VerificationHistoryViewModel?
    
    public init(student: User, experimentId: UUID? = nil) {
        self.student = student
        self.experimentId = experimentId
    }
    
    public var body: some View {
        Group {
            if let vm = viewModel {
                VStack(spacing: 0) {
                    // Search & Filters Header
                    VStack(spacing: 8) {
                        // Search Bar
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.secondary)
                            TextField("Search by experiment, reviewer, or comments...", text: Bindable(vm).searchText)
                                .textFieldStyle(.plain)
                            if !vm.searchText.isEmpty {
                                Button(action: { vm.searchText = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(10)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        
                        // Filter Pills (Department & Status)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                // Department Filter (if multiple departments present)
                                if vm.availableDepartments.count > 2 {
                                    Menu {
                                        ForEach(vm.availableDepartments, id: \.self) { dept in
                                            Button(dept == "All" ? "All Departments" : dept) {
                                                vm.selectedDepartment = dept
                                            }
                                        }
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: "building.2.fill")
                                                .font(.caption2)
                                            Text(vm.selectedDepartment == "All" ? "All Departments" : vm.selectedDepartment)
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .lineLimit(1)
                                            Image(systemName: "chevron.down")
                                                .font(.caption2)
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(vm.selectedDepartment == "All" ? Color(.secondarySystemBackground) : Color.indigo.opacity(0.15))
                                        .foregroundStyle(vm.selectedDepartment == "All" ? Color.primary : Color.indigo)
                                        .clipShape(Capsule())
                                    }
                                }
                                
                                // Status Filter Menu
                                Menu {
                                    ForEach(VerificationHistoryViewModel.VerificationStatusFilter.allCases) { filter in
                                        Button(filter.rawValue) {
                                            vm.statusFilter = filter
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "line.3.horizontal.decrease.circle")
                                            .font(.caption2)
                                        Text(vm.statusFilter.rawValue)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                        Image(systemName: "chevron.down")
                                            .font(.caption2)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(vm.statusFilter == .all ? Color(.secondarySystemBackground) : Color.blue.opacity(0.15))
                                    .foregroundStyle(vm.statusFilter == .all ? Color.primary : Color.blue)
                                    .clipShape(Capsule())
                                }
                                
                                if vm.selectedDepartment != "All" || vm.statusFilter != .all || !vm.searchText.isEmpty {
                                    Button(action: { vm.clearFilters() }) {
                                        Text("Reset")
                                            .font(.caption)
                                            .foregroundStyle(.red)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 6)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    
                    // Verifications List
                    if vm.verifications.isEmpty {
                        EmptyStateView(
                            iconName: "clock.arrow.circlepath",
                            title: "No Verification Records",
                            message: "There are no review records logged yet."
                        )
                    } else if vm.filteredVerifications.isEmpty {
                        EmptyStateView(
                            iconName: "magnifyingglass",
                            title: "No Matching Records",
                            message: "No verification records match your search query or selected filters."
                        )
                    } else {
                        List {
                            ForEach(vm.filteredVerifications) { record in
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        if let exp = vm.experiment(for: record) {
                                            Text(exp.experimentNumber)
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundStyle(.tint)
                                            
                                            Text(exp.title)
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .lineLimit(1)
                                        }
                                        
                                        Spacer()
                                        
                                        StatusBadge(status: record.status)
                                    }
                                    
                                    if let student = vm.student(for: record) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "person.fill")
                                                .font(.caption2)
                                            Text("\(student.name) (\(student.department))")
                                                .font(.caption)
                                        }
                                        .foregroundStyle(.secondary)
                                    }
                                    
                                    Text(record.comments)
                                        .font(.body)
                                        .foregroundStyle(.primary)
                                    
                                    HStack {
                                        Text("Reviewed by \(record.mentorName)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        
                                        Spacer()
                                        
                                        Text(DateFormatter.localizedString(from: record.timestamp, dateStyle: .medium, timeStyle: .short))
                                            .font(.caption2)
                                            .foregroundStyle(.tertiary)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .listStyle(.plain)
                    }
                }
            } else {
                ProgressView()
            }
        }
        .navigationTitle(student.role == .admin ? "Audit History" : "Verification History")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if viewModel == nil {
                viewModel = VerificationHistoryViewModel(experimentId: experimentId, currentUser: student, dataStore: dataStore)
            }
        }
    }
}
