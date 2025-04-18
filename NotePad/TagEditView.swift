//
//  TagEditMode.swift
//  NotePad
//
//  Created by Prat B on 18.04.25.
//


import SwiftUI
import CoreData

enum TagEditMode {
    case create
    case edit(tag: Tag)
}

struct TagEditView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    let mode: TagEditMode
    
    @State private var name: String = ""
    @State private var selectedColor: String = "blue"
    
    // Available colors for tags
    private let availableColors = [
        "red", "orange", "yellow", "green", "blue", "purple", "pink", "gray"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Tag Details")) {
                    TextField("Name", text: $name)
                    
                    VStack(alignment: .leading) {
                        Text("Color")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(availableColors, id: \.self) { color in
                                    ColorCircle(
                                        color: Color(color),
                                        isSelected: selectedColor == color
                                    )
                                    .onTapGesture {
                                        selectedColor = color
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
                
                if case .edit(let tag) = mode {
                    Section(header: Text("Associated Notes")) {
                        if let notes = tag.notes as? Set<Note>, !notes.isEmpty {
                            ForEach(Array(notes), id: \.self) { note in
                                Text(note.title ?? "Untitled")
                            }
                        } else {
                            Text("No notes associated with this tag")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTag()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .onAppear {
                setupInitialValues()
            }
        }
    }
    
    private var title: String {
        switch mode {
        case .create:
            return "New Tag"
        case .edit:
            return "Edit Tag"
        }
    }
    
    private func setupInitialValues() {
        switch mode {
        case .create:
            // Default values for new tag
            break
        case .edit(let tag):
            // Load existing tag values
            name = tag.name ?? ""
            selectedColor = tag.color ?? "blue"
        }
    }
    
    private func saveTag() {
        switch mode {
        case .create:
            let newTag = Tag(context: viewContext)
            newTag.name = name
            newTag.color = selectedColor
            
        case .edit(let tag):
            tag.name = name
            tag.color = selectedColor
        }
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error saving tag: \(error)")
            // In a real app, you would show this error to the user
        }
    }
}

struct ColorCircle: View {
    let color: Color
    let isSelected: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .fill(color)
                .frame(width: 30, height: 30)
            
            if isSelected {
                Circle()
                    .strokeBorder(Color.primary, lineWidth: 2)
                    .frame(width: 36, height: 36)
            }
        }
    }
}

struct TagEditView_Previews: PreviewProvider {
    static var previews: some View {
        TagEditView(mode: .create)
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}