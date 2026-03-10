//
//  CustomTextField.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 11.02.26.
//

import SwiftUI

struct CustomTextField: View {
    @Binding var text: String
    
    let placeholder: String
    let isSecure: Bool
    let showToggle: Bool
    let showAvailability: Bool
    let isAvailable: Bool?
    let isError: Bool
    
    @State private var isSecureVisible: Bool = false
    @FocusState private var isFocused: Bool
    
    init(
        text: Binding<String>,
        placeholder: String,
        isSecure: Bool = false,
        showToggle: Bool = false,
        showAvailability: Bool = false,
        isAvailable: Bool? = nil,
        isError: Bool = false
    ) {
        self._text = text
        self.placeholder = placeholder
        self.isSecure = isSecure
        self.showToggle = showToggle
        self.showAvailability = showAvailability
        self.isAvailable = isAvailable
        self.isError = isError
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                if isSecure && !isSecureVisible {
                    SecureField(placeholder, text: $text)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($isFocused)
                } else {
                    TextField(placeholder, text: $text)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($isFocused)
                }
                
                if showAvailability, let available = isAvailable {
                    Image(systemName: available ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(available ? .green : .red)
                        .font(.system(size: 20))
                }
                
                if showToggle && isSecure {
                    Button {
                        isSecureVisible.toggle()
                    } label: {
                        Image(systemName: isSecureVisible ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 20))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isFocused ? Color.accentColor : (isError ? Color.red : Color.clear),
                        lineWidth: isFocused ? 2 : 1
                    )
            )
        }
    }
}
