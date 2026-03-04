//
//  MapPlaceholderSection.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 26.02.26.
//
import SwiftUI

struct MapPlaceholderSection: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(.systemGray6))
            .overlay(
                VStack(spacing: 6) {
                    Image(systemName: "map")
                        .font(.system(size: 22))
                        .foregroundColor(Color(.systemGray3))

                    Text("Map coming soon")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(.systemGray3))
                }
            )
            .padding(.horizontal, 16)
    }
}
