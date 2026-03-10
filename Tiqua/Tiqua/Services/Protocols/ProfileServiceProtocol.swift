//
//  ProfileServiceProtocol.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 17.02.26.
//
import Foundation

protocol ProfileServiceProtocol {
    func fetchCurrentUser() async throws -> User
    func fetchUser(userId: String) async throws -> User
    func updateProfile(fullName: String, bio: String) async throws
    func uploadProfileImage(_ imageData: Data) async throws -> String
    func followUser(targetUserId: String) async throws
    func unfollowUser(targetUserId: String) async throws
    func isFollowing(targetUserId: String) async throws -> Bool
    func fetchFollowerCount(userId: String) async throws -> Int
}
