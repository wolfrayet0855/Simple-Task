import Combine

// Legacy-only shim. Categories are persisted Tags now; this goes away with the Legacy screens.
class CategoryManager: ObservableObject {
    @Published var categories: [String] = ["Work", "Personal", "Fitness", "Shopping", "Other"]
}
