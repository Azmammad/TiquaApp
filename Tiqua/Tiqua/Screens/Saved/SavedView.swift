//
//  SavedView.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 14.02.26.
//
import SwiftUI

struct SavedView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.accentColor)
                        .padding(.top, 40)
                    
                    Text("Your Saved Posts")
                        .font(.system(size: 28, weight: .bold))
                        .padding(.top, 20)
                    
                    Text("All your favorite travel experiences in one place")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            }
            .navigationTitle("Saved")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    SavedView()
}
