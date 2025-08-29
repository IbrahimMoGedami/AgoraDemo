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

struct CallControlButton: View {
    
    let icon: String
    let text: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: icon)
                    .font(.title2)
                    .padding()
                    .background(color.opacity(0.3))
                    .foregroundColor(color)
                    .clipShape(Circle())
                Text(text).font(.caption)
            }
        }
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
