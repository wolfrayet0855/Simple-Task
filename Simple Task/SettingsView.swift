import SwiftUI

struct SettingsView: View {
    @State private var categories: [String] = ["Work", "Personal", "Fitness", "Shopping", "Other"]
    @State private var newCategory = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Category Tags").font(.headline)) {
                    List {
                        ForEach(categories, id: \.self) { category in
                            Text(category)
                        }
                        .onDelete { indexSet in
                            categories.remove(atOffsets: indexSet)
                        }
                    }
                }
                
                Section(header: Text("Add New Category").font(.headline)) {
                    HStack {
                        TextField("New Category", text: $newCategory)
                        Button(action: {
                            guard !newCategory.isEmpty else { return }
                            categories.append(newCategory)
                            newCategory = ""
                        }) {
                            Image(systemName: "plus.circle.fill")
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        // Add dismiss functionality if presented modally.
                    }
                }
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}

