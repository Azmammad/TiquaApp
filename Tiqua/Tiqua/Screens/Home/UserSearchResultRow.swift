//
//  UserSearchResultRow.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 25.02.26.
//


import SwiftUI
import Kingfisher

struct UserSearchResultRow: View {
    let user: User

    var body: some View {
        HStack(spacing: 12) {
            if let urlString = user.profileImageURL,
               let url = URL(string: urlString) {
                KFImage(url)
                    .placeholder {
                        Circle().fill(Color(.systemGray5))
                    }
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.gray)
                    )
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("@\(user.username)")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                if let fullName = user.fullName, !fullName.isEmpty {
                    Text(fullName)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}