//
//  AuthService.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 10.02.26.
//
import Foundation

protocol AuthService {
    func register(username: String, email: String, password: String) async throws -> User
    func login(identifier: String, password: String) async throws -> User
    func logout() async throws
    func sendPasswordReset(email: String) async throws
    func checkUsernameAvailability(_ username: String) async throws -> Bool
    func getCurrentUser() async throws -> User?
    func getEmail(from username: String) async throws -> String
}
