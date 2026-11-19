import Foundation

/// Provides initial realistic sample data for the single-device academic demonstration.
public enum SampleData {
    // MARK: - Predefined Users
    public static let adminId = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    public static let mentor1Id = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
    public static let mentor2Id = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
    public static let student1Id = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!
    public static let student2Id = UUID(uuidString: "55555555-5555-5555-5555-555555555555")!
    public static let student3Id = UUID(uuidString: "66666666-6666-6666-6666-666666666666")!
    public static let inactiveStudentId = UUID(uuidString: "77777777-7777-7777-7777-777777777777")!
    
    // MARK: - Predefined Departments
    public static var departments: [Department] {
        [
            Department(name: "Computer Science & Engineering", code: "CSE"),
            Department(name: "Information Technology", code: "IT"),
            Department(name: "Electrical & Electronics Engineering", code: "EEE"),
            Department(name: "Electronics & Communication Engineering", code: "ECE"),
            Department(name: "Mechanical Engineering", code: "MECH"),
            Department(name: "Civil Engineering", code: "CIVIL"),
            Department(name: "Artificial Intelligence & Data Science", code: "AI&DS")
        ]
    }
    
    // MARK: - Predefined Subjects
    public static let subjectDSAId = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!
    public static let subjectDBMSId = UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!
    public static let subjectOSId = UUID(uuidString: "cccccccc-cccc-cccc-cccc-cccccccccccc")!
    public static let subjectCNId = UUID(uuidString: "dddddddd-dddd-dddd-dddd-dddddddddddd")!
    
    public static var users: [User] {
        [
            // Predefined Administrator Account
            User(
                id: adminId,
                name: "System Administrator",
                username: "admin",
                password: "admin123",
                role: .admin,
                department: "Academic Office",
                isActive: true
            ),
            
            // Mentors
            User(
                id: mentor1Id,
                name: "Dr. Robert Smith",
                username: "dr.smith",
                password: "mentor123",
                role: .mentor,
                department: "Computer Science & Engineering",
                isActive: true,
                assignedStudentIds: [student1Id, student2Id]
            ),
            User(
                id: mentor2Id,
                name: "Prof. Alan Turing",
                username: "prof.alan",
                password: "mentor123",
                role: .mentor,
                department: "Information Technology",
                isActive: true,
                assignedStudentIds: [student3Id]
            ),
            
            // Students
            User(
                id: student1Id,
                name: "John Doe",
                username: "john.doe",
                password: "student123",
                role: .student,
                department: "Computer Science & Engineering",
                isActive: true,
                assignedMentorId: mentor1Id
            ),
            User(
                id: student2Id,
                name: "Jane Smith",
                username: "jane.smith",
                password: "student123",
                role: .student,
                department: "Computer Science & Engineering",
                isActive: true,
                assignedMentorId: mentor1Id
            ),
            User(
                id: student3Id,
                name: "Alex Jones",
                username: "alex.jones",
                password: "student123",
                role: .student,
                department: "Information Technology",
                isActive: true,
                assignedMentorId: mentor2Id
            ),
            
            // Inactive Account (Demonstrates deactivated login prevention)
            User(
                id: inactiveStudentId,
                name: "Inactive Student",
                username: "inactive.user",
                password: "pass123",
                role: .student,
                department: "Computer Science & Engineering",
                isActive: false,
                assignedMentorId: nil
            )
        ]
    }
    
    public static var subjects: [Subject] {
        [
            Subject(
                id: subjectDSAId,
                name: "Data Structures & Algorithms",
                code: "CS201",
                description: "Fundamental data structures, stacks, queues, trees, sorting, and graph algorithms."
            ),
            Subject(
                id: subjectDBMSId,
                name: "Database Management Systems",
                code: "CS301",
                description: "Relational database modeling, SQL queries, normalization, indexing, and transactions."
            ),
            Subject(
                id: subjectOSId,
                name: "Operating Systems",
                code: "CS302",
                description: "Process scheduling, thread synchronization, deadlocks, and virtual memory management."
            ),
            Subject(
                id: subjectCNId,
                name: "Computer Networks",
                code: "CS303",
                description: "OSI stack, TCP/IP protocol suite, routing protocols, and socket programming."
            )
        ]
    }
    
    public static var experiments: [Experiment] {
        let calendar = Calendar.current
        let today = Date()
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today) ?? today
        let fiveDaysAgo = calendar.date(byAdding: .day, value: -5, to: today) ?? today
        let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: today) ?? today
        
        let exp1Id = UUID(uuidString: "e1111111-1111-1111-1111-111111111111")!
        let exp2Id = UUID(uuidString: "e2222222-2222-2222-2222-222222222222")!
        let exp3Id = UUID(uuidString: "e3333333-3333-3333-3333-333333333333")!
        let exp4Id = UUID(uuidString: "e4444444-4444-4444-4444-444444444444")!
        
        return [
            Experiment(
                id: exp1Id,
                experimentNumber: "EXP-01",
                title: "Binary Search Tree Implementation",
                subjectId: subjectDSAId,
                studentId: student1Id,
                mentorId: mentor1Id,
                date: oneWeekAgo,
                aim: "To implement a Binary Search Tree with insertion, deletion, and in-order traversal in Swift.",
                procedure: "1. Define TreeNode class with left and right child pointers.\n2. Implement insert() maintaining BST property (left < root < right).\n3. Implement inOrderTraversal() using recursive calls.\n4. Verify ordered output with sample input [50, 30, 20, 40, 70, 60, 80].",
                result: "The BST was successfully constructed and in-order traversal yielded strictly sorted values: 20, 30, 40, 50, 60, 70, 80.",
                status: .verified,
                isAssignedByMentor: true,
                lastUpdated: oneWeekAgo
            ),
            Experiment(
                id: exp2Id,
                experimentNumber: "EXP-02",
                title: "Round Robin CPU Scheduling",
                subjectId: subjectOSId,
                studentId: student1Id,
                mentorId: mentor1Id,
                date: fiveDaysAgo,
                aim: "To simulate Round Robin CPU Scheduling with a time quantum of 2 units.",
                procedure: "1. Maintain ready queue for arrived processes.\n2. Allocate CPU to head process for min(burst_remaining, quantum).\n3. Context switch and push preempted process to tail if burst remaining > 0.\n4. Calculate average turnaround time and waiting time.",
                result: "Calculated average waiting time of 5.66ms and average turnaround time of 10.33ms for 3 test processes.",
                status: .submitted,
                isAssignedByMentor: true,
                lastUpdated: fiveDaysAgo
            ),
            Experiment(
                id: exp3Id,
                experimentNumber: "EXP-03",
                title: "SQL Schema Design & 3NF Normalization",
                subjectId: subjectDBMSId,
                studentId: student1Id,
                mentorId: mentor1Id,
                date: twoDaysAgo,
                aim: "To design an university enrollment database schema and decompose tables to 3NF.",
                procedure: "1. Identify functional dependencies.\n2. Decompose Student_Course_Faculty relation to eliminate partial dependencies (2NF).\n3. Eliminate transitive dependencies by creating separate Department table (3NF).",
                result: "Need to fix Department foreign key constraints and verify lossless join decomposition.",
                status: .rejected,
                isAssignedByMentor: false,
                lastUpdated: twoDaysAgo
            ),
            Experiment(
                id: exp4Id,
                experimentNumber: "EXP-04",
                title: "TCP Client-Server Socket Communication",
                subjectId: subjectCNId,
                studentId: student2Id,
                mentorId: mentor1Id,
                date: today,
                aim: "To establish a TCP client-server connection and exchange echo messages.",
                procedure: "1. Create socket using socket(), bind to local port, and listen().\n2. Accept client connection and spawn handler.\n3. Send and receive echo payload.",
                result: "Draft in progress.",
                status: .pending,
                isAssignedByMentor: false,
                lastUpdated: today
            )
        ]
    }
    
    public static var assignments: [Assignment] {
        let calendar = Calendar.current
        let today = Date()
        let dueDate = calendar.date(byAdding: .day, value: 5, to: today) ?? today
        
        return [
            Assignment(
                id: UUID(uuidString: "a1111111-1111-1111-1111-111111111111")!,
                mentorId: mentor1Id,
                studentId: student1Id,
                subjectId: subjectDSAId,
                title: "Dijkstra's Shortest Path Algorithm",
                aim: "Implement Dijkstra's algorithm using priority queue to find shortest path in weighted graph.",
                procedure: "1. Initialize distance array with infinity, source with 0.\n2. Use min-heap to extract min-distance node.\n3. Relax neighboring edges.",
                experimentNumber: "EXP-05",
                assignedDate: today,
                dueDate: dueDate,
                status: .pending,
                isCompleted: false
            ),
            Assignment(
                id: UUID(uuidString: "a2222222-2222-2222-2222-222222222222")!,
                mentorId: mentor1Id,
                studentId: student2Id,
                subjectId: subjectOSId,
                title: "Dining Philosophers Synchronization",
                aim: "Solve the dining philosophers deadlock using semaphores or mutex locks.",
                procedure: "1. Represent chopsticks as semaphores.\n2. Implement asymmetric pickup or state-based monitor to prevent deadlock.",
                experimentNumber: "EXP-06",
                assignedDate: today,
                dueDate: dueDate,
                status: .pending,
                isCompleted: false
            )
        ]
    }
    
    public static var verifications: [Verification] {
        let calendar = Calendar.current
        let today = Date()
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today) ?? today
        let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: today) ?? today
        
        let exp1Id = UUID(uuidString: "e1111111-1111-1111-1111-111111111111")!
        let exp3Id = UUID(uuidString: "e3333333-3333-3333-3333-333333333333")!
        
        return [
            Verification(
                id: UUID(),
                experimentId: exp1Id,
                mentorId: mentor1Id,
                mentorName: "Dr. Robert Smith",
                status: .verified,
                comments: "Excellent BST implementation and clean recursion. Verified on hardware.",
                timestamp: oneWeekAgo
            ),
            Verification(
                id: UUID(),
                experimentId: exp3Id,
                mentorId: mentor1Id,
                mentorName: "Dr. Robert Smith",
                status: .rejected,
                comments: "Missing foreign key definitions on CourseEnrollment table. Please update schema and resubmit.",
                timestamp: twoDaysAgo
            )
        ]
    }
}
