//
//  DetailView.swift
//  ToDoList
//
//  Created by user on 9/13/24.
//

import SwiftUI

struct DetailView: View {
    var passedValue: String // Don't initialize it -it will be passed from the parent view
    
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        VStack {
            Image(systemName: "star")
                .resizable()
                .scaledToFit()
                .foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
            
            Text("You are a super star!\n And you passed over the value \(passedValue)")
                .font(.largeTitle)
                .multilineTextAlignment(.center)
            
            Spacer()
            
            Button("Click to return.") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    DetailView(passedValue: "Item1")
}
