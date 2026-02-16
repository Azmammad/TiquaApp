//
//  CreateView.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 14.02.26.
//

import SwiftUI

struct CreateView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.accentColor)
                        .padding(.top, 40)
                    
                    Text("Create New Post")
                        .font(.system(size: 28, weight: .bold))
                        .padding(.top, 20)
                    
                    Text("Share your authentic travel experiences with the world")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            }
            .navigationTitle("Create")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    CreateView()
}
