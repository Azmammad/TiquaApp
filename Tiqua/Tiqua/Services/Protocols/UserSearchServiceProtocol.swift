//
//  UserSearchServiceProtocol.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 25.02.26.
//
import Foundation

protocol UserSearchServiceProtocol {
    func searchUsers(query: String) async throws -> [User]
}
