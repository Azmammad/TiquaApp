//
//  FirebaseUserSearchService.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 25.02.26.
//


import Foundation
import FirebaseFirestore

final class FirebaseUserSearchService: UserSearchServiceProtocol {
    private let db = Firestore.firestore()

    func searchUsers(query: String) async throws -> [User] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return [] }

        let snapshot = try await db.collection("users")
            .whereField("username", isGreaterThanOrEqualTo: trimmed)
            .whereField("username", isLessThan: trimmed + "\u{f8ff}")
            .limit(to: 20)
            .getDocuments()

        return snapshot.documents.compactMap { decode(document: $0) }
    }

    private func decode(document: QueryDocumentSnapshot) -> User? {
        let data = document.data()

        guard
            let id = data["id"] as? String,
            let username = data["username"] as? String,
            let email = data["email"] as? String,
            let timestamp = data["createdAt"] as? Timestamp
        else { return nil }

        return User(
            id: id,
            username: username,
            email: email,
            createdAt: timestamp.dateValue(),
            isEmailVerified: data["isEmailVerified"] as? Bool ?? false,
            fullName: data["fullName"] as? String,
            bio: data["bio"] as? String,
            profileImageURL: data["profileImageURL"] as? String
        )
    }
}