//
//  AuthError.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 11.02.26.
//
import Foundation

enum AuthError: LocalizedError {
    case usernameTaken
    case userNotFound
    case emailNotVerified

    var errorDescription: String? {
        switch self {
        case .usernameTaken:
            return "This username is already taken."
        case .userNotFound:
            return "User not found."
        case .emailNotVerified:
            return "Please verify your email before logging in."
        }
    }
}
