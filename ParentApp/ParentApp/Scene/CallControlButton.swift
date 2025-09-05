//
//  CallControlButton.swift
//  ParentApp
//
//  Created by Ibrahim Mo Gedami on 05/09/2025.
//

import SwiftUI

struct CallControlButton: View {
    
    let icon: String
    let text: String
    let color: Color
    let backgroundColor: Color
    let size: CGFloat
    let iconSize: CGFloat
    let textSize: CGFloat
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: iconSize, weight: .bold))
                    .frame(width: size, height: size)
                    .background(backgroundColor)
                    .foregroundColor(color)
                    .clipShape(Circle())
                
                Text(text)
                    .font(.system(size: textSize, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ScaleButtonStyle: ButtonStyle {
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
    
}

struct PrimaryButtonStyle: ButtonStyle {
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
    }
    
}

