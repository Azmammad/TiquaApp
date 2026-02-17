//
//  ProfileServiceProtocol.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 17.02.26.
//

import Foundation

protocol ProfileServiceProtocol {
    func fetchCurrentUser() async throws -> User
    func updateProfile(fullName: String, bio: String) async throws
    func uploadProfileImage(_ imageData: Data) async throws -> String
}
