//
//  FirebaseAuthService.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 10.02.26.
//
import Foundation
import FirebaseAuth
import FirebaseFirestore

final class FirebaseAuthService: AuthServiceProtocol {
    private let auth = Auth.auth()
    private let db = Firestore.firestore()

    func register(username: String, email: String, password: String) async throws -> User {
        let usernameLower = username.lowercased()

        let result = try await auth.createUser(withEmail: email, password: password)
        let firebaseUser = result.user
        let uid = firebaseUser.uid

        let now = Date()

        do {
            try await firebaseUser.sendEmailVerification()

            let _ = try await db.runTransaction({ tx, errorPointer in
                let usernameRef = self.db.collection("usernames").document(usernameLower)

                let usernameDoc: DocumentSnapshot
                do {
                    usernameDoc = try tx.getDocument(usernameRef)
                } catch let fetchError as NSError {
                    errorPointer?.pointee = fetchError
                    return nil
                }

                if usernameDoc.exists {
                    let error = NSError(
                        domain: "AuthError",
                        code: 409,
                        userInfo: [NSLocalizedDescriptionKey: AuthError.usernameTaken.errorDescription ?? "Username taken"]
                    )
                    errorPointer?.pointee = error
                    return nil
                }

                let userRef = self.db.collection("users").document(uid)

                tx.setData([
                    "id": uid,
                    "username": username,
                    "usernameLower": usernameLower,
                    "email": email,
                    "createdAt": Timestamp(date: now),
                    "isEmailVerified": firebaseUser.isEmailVerified
                ], forDocument: userRef)

                tx.setData([
                    "uid": uid
                ], forDocument: usernameRef)

                return nil
            })

            return User(
                id: uid,
                username: username,
                email: email,
                createdAt: now,
                isEmailVerified: firebaseUser.isEmailVerified
            )
        } catch {
            try? await firebaseUser.delete()
            throw error
        }
    }

    func login(identifier: String, password: String) async throws -> User {
        let trimmed = identifier.trimmingCharacters(in: .whitespacesAndNewlines)
        let email: String

        if trimmed.contains("@") {
            email = trimmed
        } else {
            email = try await getEmail(from: trimmed)
        }

        let result: AuthDataResult
        do {
            result = try await auth.signIn(withEmail: email, password: password)
        } catch let error as NSError {
            if error.domain == AuthErrorDomain {
                let code = AuthErrorCode(rawValue: error.code)
                switch code {
                case .wrongPassword, .invalidCredential:
                    throw NSError(
                        domain: AuthErrorDomain,
                        code: AuthErrorCode.wrongPassword.rawValue,
                        userInfo: [NSLocalizedDescriptionKey: "Incorrect password. Please try again."]
                    )
                case .userNotFound:
                    throw AuthError.userNotFound
                case .networkError:
                    throw NSError(
                        domain: AuthErrorDomain,
                        code: AuthErrorCode.networkError.rawValue,
                        userInfo: [NSLocalizedDescriptionKey: "Network error. Please check your internet connection."]
                    )
                case .tooManyRequests:
                    throw NSError(
                        domain: AuthErrorDomain,
                        code: AuthErrorCode.tooManyRequests.rawValue,
                        userInfo: [NSLocalizedDescriptionKey: "Too many failed attempts. Please try again later."]
                    )
                default:
                    throw error
                }
            }
            throw error
        }

        let firebaseUser = result.user

        try await firebaseUser.reload()

        if !firebaseUser.isEmailVerified {
            try await auth.signOut()
            throw AuthError.emailNotVerified
        }

        let uid = firebaseUser.uid

        let userSnap = try await db.collection("users").document(uid).getDocument()
        guard let data = userSnap.data(),
              let username = data["username"] as? String,
              let userEmail = data["email"] as? String,
              let createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
        else {
            throw AuthError.userNotFound
        }

        let isEmailVerified = data["isEmailVerified"] as? Bool ?? firebaseUser.isEmailVerified

        if !isEmailVerified && firebaseUser.isEmailVerified {
            try await db.collection("users").document(uid).setData(
                ["isEmailVerified": true],
                merge: true
            )
        }

        if data["usernameLower"] == nil {
            try? await db.collection("users").document(uid).setData(
                ["usernameLower": username.lowercased()],
                merge: true
            )
        }

        return User(
            id: uid,
            username: username,
            email: userEmail,
            createdAt: createdAt,
            isEmailVerified: firebaseUser.isEmailVerified
        )
    }

    func logout() async throws {
        try auth.signOut()
    }

    func sendPasswordReset(email: String) async throws {
        try await auth.sendPasswordReset(withEmail: email)
    }

    func checkUsernameAvailability(_ username: String) async throws -> Bool {
        let usernameLower = username.lowercased()

        do {
            let doc = try await db.collection("usernames").document(usernameLower).getDocument()
            return !doc.exists
        } catch {
            if error.localizedDescription.contains("permission") {
                throw NSError(
                    domain: "FirebaseError",
                    code: 403,
                    userInfo: [NSLocalizedDescriptionKey: "Unable to check username availability. Please check your internet connection."]
                )
            }
            throw error
        }
    }

    func getCurrentUser() async throws -> User? {
        guard let firebaseUser = auth.currentUser else { return nil }

        let uid = firebaseUser.uid
        let userSnap = try await db.collection("users").document(uid).getDocument()

        guard let data = userSnap.data(),
              let username = data["username"] as? String,
              let email = data["email"] as? String,
              let createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
        else {
            return nil
        }

        let isEmailVerified = data["isEmailVerified"] as? Bool ?? firebaseUser.isEmailVerified

        return User(
            id: uid,
            username: username,
            email: email,
            createdAt: createdAt,
            isEmailVerified: isEmailVerified
        )
    }

    func getEmail(from username: String) async throws -> String {
        let usernameLower = username.lowercased()

        let usernameSnap = try await db.collection("usernames").document(usernameLower).getDocument()
        if usernameSnap.exists, let uid = usernameSnap.data()?["uid"] as? String {
            let userSnap = try await db.collection("users").document(uid).getDocument()
            if let email = userSnap.data()?["email"] as? String {
                return email
            }
        }

        let lowerSnap = try await db.collection("users")
            .whereField("usernameLower", isEqualTo: usernameLower)
            .limit(to: 1)
            .getDocuments()

        if let doc = lowerSnap.documents.first,
           let email = doc.data()["email"] as? String {
            return email
        }

        let end = usernameLower + "\u{f8ff}"
        let rangeSnap = try await db.collection("users")
            .whereField("username", isGreaterThanOrEqualTo: usernameLower)
            .whereField("username", isLessThan: end)
            .limit(to: 10)
            .getDocuments()

        for doc in rangeSnap.documents {
            let data = doc.data()
            if let storedUsername = data["username"] as? String,
               storedUsername.lowercased() == usernameLower,
               let email = data["email"] as? String {
                if data["usernameLower"] == nil {
                    try? await db.collection("users").document(doc.documentID).setData(
                        ["usernameLower": usernameLower],
                        merge: true
                    )
                }
                return email
            }
        }

        throw AuthError.userNotFound
    }
}
