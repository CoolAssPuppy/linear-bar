import Foundation

/// Utility for filtering and sorting Linear items
enum ItemFilter {

    /// Filter configuration for Linear items
    struct FilterOptions {
        var showCompletedItems: Bool = true
        var showCanceledItems: Bool = false

        init(showCompleted: Bool = true, showCanceled: Bool = false) {
            self.showCompletedItems = showCompleted
            self.showCanceledItems = showCanceled
        }
    }

    // MARK: - Filtering

    /// Filters an array of LinearItems based on their completion/cancellation state
    static func filter(_ items: [any LinearItem], options: FilterOptions) -> [any LinearItem] {
        items.filter { item in
            shouldInclude(item, options: options)
        }
    }

    /// Checks if a single item should be included based on filter options
    static func shouldInclude(_ item: any LinearItem, options: FilterOptions) -> Bool {
        if let issue = item as? Issue {
            return shouldIncludeIssue(issue, options: options)
        }

        if let project = item as? Project {
            return shouldIncludeProject(project, options: options)
        }

        if let initiative = item as? Initiative {
            return shouldIncludeInitiative(initiative, options: options)
        }

        return true
    }

    private static func shouldIncludeIssue(_ issue: Issue, options: FilterOptions) -> Bool {
        guard let stateType = issue.state?.type else { return true }

        if stateType == "completed" && !options.showCompletedItems {
            return false
        }
        if stateType == "canceled" && !options.showCanceledItems {
            return false
        }
        return true
    }

    private static func shouldIncludeProject(_ project: Project, options: FilterOptions) -> Bool {
        let state = project.state.lowercased()

        if state == "completed" && !options.showCompletedItems {
            return false
        }
        if state == "canceled" && !options.showCanceledItems {
            return false
        }
        return true
    }

    private static func shouldIncludeInitiative(_ initiative: Initiative, options: FilterOptions) -> Bool {
        guard let status = initiative.status?.lowercased() else { return true }

        if status == "completed" && !options.showCompletedItems {
            return false
        }
        return true
    }

    // MARK: - Sorting

    /// Sorts an array of LinearItems by the specified sort order
    static func sort(_ items: [any LinearItem], by order: SortOrder) -> [any LinearItem] {
        items.sorted { item1, item2 in
            compare(item1, item2, by: order)
        }
    }

    /// Compares two items based on the sort order
    static func compare(_ item1: any LinearItem, _ item2: any LinearItem, by order: SortOrder) -> Bool {
        switch order {
        case .createdNewest:
            let date1 = item1.createdAt ?? Date.distantPast
            let date2 = item2.createdAt ?? Date.distantPast
            return date1 > date2

        case .createdOldest:
            let date1 = item1.createdAt ?? Date.distantPast
            let date2 = item2.createdAt ?? Date.distantPast
            return date1 < date2

        case .updatedNewest:
            let date1 = item1.updatedAt ?? Date.distantPast
            let date2 = item2.updatedAt ?? Date.distantPast
            return date1 > date2

        case .updatedOldest:
            let date1 = item1.updatedAt ?? Date.distantPast
            let date2 = item2.updatedAt ?? Date.distantPast
            return date1 < date2

        case .dueDate:
            return compareDueDates(item1, item2)
        }
    }

    private static func compareDueDates(_ item1: any LinearItem, _ item2: any LinearItem) -> Bool {
        let dueDate1 = getDueDate(from: item1)
        let dueDate2 = getDueDate(from: item2)

        // Items with due dates come first, sorted by due date (earliest first)
        // Items without due dates come after, sorted by created date (newest first)
        switch (dueDate1, dueDate2) {
        case (.some(let date1), .some(let date2)):
            return date1 < date2
        case (.some, .none):
            return true
        case (.none, .some):
            return false
        case (.none, .none):
            let created1 = item1.createdAt ?? Date.distantPast
            let created2 = item2.createdAt ?? Date.distantPast
            return created1 > created2
        }
    }

    // MARK: - Filter and Sort Combined

    /// Filters and sorts items in a single operation
    static func filterAndSort(
        _ items: [any LinearItem],
        options: FilterOptions,
        sortOrder: SortOrder
    ) -> [any LinearItem] {
        let filtered = filter(items, options: options)
        return sort(filtered, by: sortOrder)
    }

    // MARK: - Due Date Extraction

    /// Extracts the due date from a LinearItem
    static func getDueDate(from item: any LinearItem) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)

        if let issue = item as? Issue, let dueDate = issue.dueDate {
            return formatter.date(from: dueDate)
        }

        if let project = item as? Project, let targetDate = project.targetDate {
            return formatter.date(from: targetDate)
        }

        if let initiative = item as? Initiative, let targetDate = initiative.targetDate {
            return formatter.date(from: targetDate)
        }

        return nil
    }
}
