//
//  ParentApp.swift
//  ParentApp
//
//  Created by Ibrahim Mo Gedami on 25/08/2025.
//

import SwiftUI
import FirebaseCore
import AVFAudio

@main
struct ParentApp: App {
    
    @StateObject private var authService = FirebaseService.shared
    @StateObject private var agoraService = AgoraService()
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ParentHomeView()
                .environmentObject(authService)
                .environmentObject(agoraService)
        }
    }

}

struct CallButton: View {
    
    let icon: String
    let color: Color
    
    var body: some View {
        Image(systemName: icon)
            .foregroundColor(.white)
            .padding()
            .background(color)
            .clipShape(Circle())
    }

}

extension View {
    
    func glow(color: Color = .white, radius: CGFloat = 4) -> some View {
        self
            .shadow(color: color, radius: radius / 3)
            .shadow(color: color, radius: radius / 3)
            .shadow(color: color, radius: radius / 3)
    }

}

//struct CallControlButton: View {
//    
//    let icon: String
//    let text: String
//    let color: Color
//    let backgroundColor: Color
//    let action: () -> Void
//    
//    init(icon: String, text: String, color: Color, backgroundColor: Color = .clear, action: @escaping () -> Void) {
//        self.icon = icon
//        self.text = text
//        self.color = color
//        self.backgroundColor = backgroundColor
//        self.action = action
//    }
//    
//    var body: some View {
//        VStack {
//            Button(action: action) {
//                Image(systemName: icon)
//                    .font(.system(size: 24))
//                    .foregroundColor(color)
//                    .frame(width: 60, height: 60)
//                    .background(backgroundColor)
//                    .clipShape(Circle())
//            }
//            
//            Text(text)
//                .font(.caption)
//                .foregroundColor(.white)
//                .padding(.top, 5)
//        }
//    }
//
//}
//
