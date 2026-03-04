//
//  MapPlaceholderSection.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 26.02.26.
//


import SwiftUI

struct MapPlaceholderSection: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color(.systemGray6))
            .frame(height: 148)
            .overlay(
                VStack(spacing: 8) {
                    Image(systemName: "map")
                        .font(.system(size: 26))
                        .foregroundColor(Color(.systemGray3))

                    Text("Map coming soon")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(.systemGray3))
                }
            )
            .padding(.horizontal, 16)
    }
}