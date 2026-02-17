//
//  ProfileService.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 16.02.26.
//
import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

final class ProfileService: ProfileServiceProtocol {
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    private let authService: AuthServiceProtocol

    init(authService: AuthServiceProtocol = FirebaseAuthService()) {
        self.authService = authService
    }

    func fetchCurrentUser() async throws -> User {
        guard let currentUser = try await authService.getCurrentUser() else {
            throw NSError(
                domain: "ProfileService",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: "No authenticated user found"]
            )
        }

        let uid = currentUser.id

        let userDoc = try await db.collection("users").document(uid).getDocument()

        guard let data = userDoc.data() else {
            throw NSError(
                domain: "ProfileService",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "User data not found"]
            )
        }

        let username = data["username"] as? String ?? ""
        let email = data["email"] as? String ?? ""
        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        let isEmailVerified = data["isEmailVerified"] as? Bool ?? false
        let fullName = data["fullName"] as? String
        let bio = data["bio"] as? String
        let profileImageURL = data["profileImageURL"] as? String

        return User(
            id: uid,
            username: username,
            email: email,
            createdAt: createdAt,
            isEmailVerified: isEmailVerified,
            fullName: fullName,
            bio: bio,
            profileImageURL: profileImageURL
        )
    }

    func updateProfile(fullName: String, bio: String) async throws {
        guard let currentUser = try await authService.getCurrentUser() else {
            throw NSError(
                domain: "ProfileService",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: "No authenticated user found"]
            )
        }

        let uid = currentUser.id

        try await db.collection("users").document(uid).setData([
            "fullName": fullName,
            "bio": bio
        ], merge: true)
    }

    func uploadProfileImage(_ imageData: Data) async throws -> String {
        guard let currentUser = try await authService.getCurrentUser() else {
            throw NSError(
                domain: "ProfileService",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: "No authenticated user found"]
            )
        }

        let uid = currentUser.id

        let storageRef = storage.reference()
        let profileImageRef = storageRef.child("profile_images/\(uid).jpg")

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        _ = try await profileImageRef.putDataAsync(imageData, metadata: metadata)

        let downloadURL = try await profileImageRef.downloadURL()
        let urlString = downloadURL.absoluteString

        try await db.collection("users").document(uid).setData(
            ["profileImageURL": urlString],
            merge: true
        )

        return urlString
    }
}
