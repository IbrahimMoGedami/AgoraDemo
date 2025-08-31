//
//  ParentMainView.swift
//  SitterApp
//
//  Created by Ibrahim Mo Gedami on 26/08/2025.
//

import Foundation
import SwiftUI
import FirebaseFirestore

struct ParentMainView: View {
    
    @EnvironmentObject var authService: FirebaseService
    @EnvironmentObject var agoraService: AgoraService
    @Binding var showCallView: Bool
    @Binding var activeCall: Call?
    
    @State private var sitters: [UserProfile] = []
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var callListener: ListenerRegistration?
    @State private var incomingCall: Call?
    
    var body: some View {
        NavigationView {
            List {
                if isLoading {
                    ProgressView("Loading sitters...")
                } else if !sitters.isEmpty {
                    ForEach(sitters) { sitter in
                        SitterRow(sitter: sitter, showCallView: $showCallView, activeCall: $activeCall)
                    }
                } else {
                    Text("No sitters available")
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("Available Sitters")
            .navigationBarItems(trailing: Button("Sign Out") {
                signOut()
            })
            .onAppear {
                loadSitters()
                setupCallListener()
            }
            .onDisappear {
                callListener?.remove()
            }
            .sheet(item: $incomingCall) { call in
                IncomingCallView(call: call)
            }
        }
        .alert("Error", isPresented: .constant(!errorMessage.isEmpty)) {
            Button("OK") { errorMessage = "" }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func setupCallListener() {
        guard let userId = authService.currentUser?.uid else { return }
        
        callListener = authService.listenForIncomingCalls(userId: userId) { call in
            incomingCall = call
        }
    }
    
    private func loadSitters() {
        isLoading = true
        authService.getAvailableSitters { result in
            isLoading = false
            switch result {
            case .success(let sitters):
                self.sitters = sitters
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func signOut() {
        do {
            try authService.signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
}
