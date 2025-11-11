//
//  LoadingView.swift
//  MYDCC
//
//  Created by mao.496 on 5/8/25.
//

import SwiftUI

struct LoadingView: View {
    @State private var isRotating = false

    var body: some View {
        ZStack {
            Color.backgroundDark.ignoresSafeArea()

            VStack(spacing: 30) {
                // App icon
                Image("LoadingIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .cornerRadius(26)
                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)

                // Spinning circle
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.accentBlue, Color.dccBlue]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 50, height: 50)
                    .rotationEffect(Angle(degrees: isRotating ? 360 : 0))
                    .animation(
                        Animation.linear(duration: 1)
                            .repeatForever(autoreverses: false),
                        value: isRotating
                    )
                    .onAppear {
                        isRotating = true
                    }

                Text("Loading...")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
            }
        }
    }
}

struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingView()
    }
}
