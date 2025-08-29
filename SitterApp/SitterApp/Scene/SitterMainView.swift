//
//  SitterMainView.swift
//  SitterApp
//
//  Created by Ibrahim Mo Gedami on 26/08/2025.
//

import Foundation
import SwiftUI
import FirebaseFirestore

struct SitterMainView: View {
    
    @EnvironmentObject var authService: FirebaseService
    @EnvironmentObject var agoraService: AgoraService
    @State private var parents: [UserProfile] = []
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var incomingCall: Call?
    @State private var callListener: ListenerRegistration?
    
    var body: some View {
//        VStack {
//            if !parents.isEmpty {
//                ParentsListView(parents: parents, isLoading: isLoading)
//            } else {
//                VStack {
//                    Text("Waiting for calls...")
//                        .font(.title2)
//                        .foregroundColor(.gray)
//                        .padding()
//                    
//                    if let user = authService.currentUser {
//                        Text("Logged in as: \(user.email ?? "Unknown")")
//                            .font(.subheadline)
//                            .foregroundColor(.secondary)
//                    }
//                }
//            }
//        }
        List {
            if isLoading {
                ProgressView("Loading parents...")
            } else if parents.isEmpty {
                Text("No parents available")
                    .foregroundColor(.gray)
            } else {
                ForEach(parents) { parent in
                    UserRow(user: parent, userType: "parent")
                }
            }
        }
        .navigationTitle("Sitter Dashboard")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Sign Out") { signOut() }
            }
        }
        .onAppear {
            loadParents()
            setupCallListener()
        }
        .onDisappear {
            callListener?.remove()
        }
        .sheet(item: $incomingCall) { call in
            IncomingCallView(call: call)
        }
        .alert("Error", isPresented: .constant(!errorMessage.isEmpty)) {
            Button("OK") { errorMessage = "" }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func loadParents() {
        isLoading = true
        authService.getAvailableParents { result in
            isLoading = false
            switch result {
            case .success(let parents):
                self.parents = parents
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func setupCallListener() {
        guard let userId = authService.currentUser?.uid else { return }
        callListener = authService.listenForAnyIncomingCalls(userId: userId) { call in
            incomingCall = call
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

struct UserRow: View {
    
    @EnvironmentObject var authService: FirebaseService
    @EnvironmentObject var agoraService: AgoraService
    let user: UserProfile
    let userType: String
    @State private var isCalling = false
    @State private var callStatusListener: ListenerRegistration?
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(user.name).font(.headline)
                Text(user.email).font(.subheadline).foregroundColor(.gray)
            }
            Spacer()
            Button {
                startCall()
            } label: {
                Image(systemName: "phone.fill")
                    .foregroundColor(.green)
                    .font(.title2)
            }
            .disabled(isCalling)
        }
        .padding(.vertical, 8)
        .onDisappear { callStatusListener?.remove() }
    }
    
    private func startCall() {
        guard let callerId = authService.currentUser?.uid else { return }
        
        let timestamp = Int(Date().timeIntervalSince1970)
        let channelName = "call_\(timestamp)_\(callerId.prefix(8))_\(user.id.prefix(8))"
        
        isCalling = true
        RingtoneManager.shared.playRingtone(.outgoing)
        
        authService.createCall(from: callerId, to: user.id, channelName: channelName) { result in
            switch result {
            case .success:
                setupCallMonitoring(channelName: channelName)
            case .failure(let error):
                handleCallError(error)
            }
        }
    }
    
    private func setupCallMonitoring(channelName: String) {
        callStatusListener = authService.waitForCallAcceptance(channelName: channelName) { result in
            RingtoneManager.shared.stopRingtone()
            isCalling = false
            
            switch result {
            case .success(let accepted):
                if accepted { agoraService.joinChannel(channelName) }
            case .failure(let error):
                print("Call error: \(error)")
            }
        }
    }
    
    private func handleCallError(_ error: Error) {
        RingtoneManager.shared.stopRingtone()
        isCalling = false
        print("Call failed: \(error)")
    }
    
}
