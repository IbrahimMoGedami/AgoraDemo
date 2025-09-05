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
    let action: () -> Void
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    var body: some View {
        GeometryReader { geometry in
            let isCompact = geometry.size.width < 400
            let buttonSize = isCompact ? 50.0 : 60.0
            let iconSize = isCompact ? 20.0 : 24.0
            let fontSize: CGFloat = isCompact ? 10 : 12
            
            VStack(spacing: 4) {
                Button(action: action) {
                    Image(systemName: icon)
                        .font(.system(size: iconSize, weight: .semibold))
                        .foregroundColor(color)
                        .frame(width: buttonSize, height: buttonSize)
                        .background(backgroundColor)
                        .clipShape(Circle())
                        .contentShape(Circle())
                }
                .buttonStyle(ScaleButtonStyle())
                
                Text(text)
                    .font(.system(size: fontSize, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(height: 80) // Fixed height for consistent layout
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
