//
//  AuthValidation.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 11.02.26.
//


import Foundation

enum AuthValidation {
    static func isValidPassword(_ password: String) -> Bool {
        let pattern = #"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$"#
        return password.range(of: pattern, options: .regularExpression) != nil
    }
}
