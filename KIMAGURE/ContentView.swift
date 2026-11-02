//
//  ContentView.swift
//  KIMAGURE
//
//  Created by maho hayashi on 2026/11/03.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: FortuneViewModel?

    var body: some View {
        Group {
            if let viewModel {
                FortuneRootView(viewModel: viewModel)
            } else {
                ProgressView()
                    .task {
                        viewModel = FortuneViewModel(modelContext: modelContext)
                    }
            }
        }
        .tint(.black)
        .preferredColorScheme(.light)
    }
}
