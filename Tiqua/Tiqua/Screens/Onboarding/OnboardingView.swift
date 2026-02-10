//
//  OnboardingView.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 10.02.26.
//
import SwiftUI

struct OnboardingView: View {

    let onFinish: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text("Tiqua")
                .font(.largeTitle)
                .bold()

            Text("Share real travel experiences only when you're there.")
                .multilineTextAlignment(.center)

            Button("Get Started") {
                onFinish()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
