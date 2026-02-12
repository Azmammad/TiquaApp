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
            return "This username is already taken. Please choose another one."
        case .userNotFound:
            return "Username or email not found. Please check and try again."
        case .emailNotVerified:
            return "Please verify your email before logging in. Check your inbox for the verification link."
        }
    }
}
