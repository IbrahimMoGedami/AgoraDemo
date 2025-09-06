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
    let isActive: Bool
    var backgroundColor: Color// = .black.opacity(0.3)
    var foregroundColor: Color// = .white
    let size: CGFloat
    let iconSize: CGFloat
    let textSize: CGFloat
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(isActive ? backgroundColor : Color.gray.opacity(0.5))
                        .frame(width: size, height: size)
                        .overlay(
                            Circle()
                                .stroke(isActive ? foregroundColor : Color.gray, lineWidth: 1)
                                .opacity(0.5)
                        )
                    
                    Image(systemName: icon)
                        .font(.system(size: iconSize, weight: .semibold))
                        .foregroundColor(isActive ? foregroundColor : .gray)
                }
                
                Text(text)
                    .font(.system(size: textSize, weight: .medium))
                    .foregroundColor(isActive ? foregroundColor : .gray)
                    .lineLimit(1)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
}

struct ScaleButtonStyle: ButtonStyle {
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
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
