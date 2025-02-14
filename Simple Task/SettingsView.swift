import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var categoryManager: CategoryManager  // Use shared category manager
    @State private var newCategory = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Category Tags").font(.headline)) {
                    List {
                        ForEach(categoryManager.categories, id: \.self) { category in
                            Text(category)
                        }
                        .onDelete { indexSet in
                            categoryManager.categories.remove(atOffsets: indexSet)
                        }
                    }
                }
                
                Section(header: Text("Add New Category").font(.headline)) {
                    HStack {
                        TextField("New Category", text: $newCategory)
                        Button(action: {
                            guard !newCategory.isEmpty else { return }
                            if !categoryManager.categories.contains(newCategory) {
                                categoryManager.categories.append(newCategory)
                            }
                            newCategory = ""
                        }) {
                            Image(systemName: "plus.circle.fill")
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            // Removed the custom toolbar back/close button so only the system's back button appears.
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SettingsView()
                .environmentObject(CategoryManager())
        }
    }
}

