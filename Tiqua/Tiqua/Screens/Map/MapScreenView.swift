//
//  MapScreenView.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 04.03.26.
//


import SwiftUI

struct MapScreenView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Spacer()
                Image(systemName: "map")
                    .font(.system(size: 56))
                    .foregroundColor(Color(.systemGray3))
                Text("Map coming soon")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(.systemGray3))
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
            .navigationTitle("Map")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}