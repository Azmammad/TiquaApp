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
        let email: String

        if identifier.contains("@") {
            email = identifier
        } else {
            email = try await getEmail(from: identifier)
        }

        let result = try await auth.signIn(withEmail: email, password: password)
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
              let email = data["email"] as? String,
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

        return User(
            id: uid,
            username: username,
            email: email,
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

        let querySnap = try await db.collection("users")
            .whereField("usernameLower", isEqualTo: usernameLower)
            .limit(to: 1)
            .getDocuments()

        if let doc = querySnap.documents.first,
           let email = doc.data()["email"] as? String {
            return email
        }

        let fallbackSnap = try await db.collection("users")
            .whereField("username", isEqualTo: username)
            .limit(to: 1)
            .getDocuments()

        if let doc = fallbackSnap.documents.first,
           let email = doc.data()["email"] as? String {
            return email
        }

        throw AuthError.userNotFound
    }
}
