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
    @Binding var showCallView: Bool
    @Binding var activeCall: Call?
    
    @State private var parents: [UserProfile] = []
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var incomingCall: Call?
    @State private var callListener: ListenerRegistration?
    
    var body: some View {
        NavigationView {
            List {
                if isLoading {
                    ProgressView("Loading parents...")
                } else if parents.isEmpty {
                    Text("No parents available")
                        .foregroundColor(.gray)
                } else {
                    ForEach(parents) { parent in
                        ParentRow(parent: parent, showCallView: $showCallView, activeCall: $activeCall)
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

struct ParentRow: View {
    
    @EnvironmentObject var authService: FirebaseService
    @EnvironmentObject var agoraService: AgoraService
    let parent: UserProfile
    @Binding var showCallView: Bool
    @Binding var activeCall: Call?
    
    @State private var isCalling = false
    @State private var callStatusListener: ListenerRegistration?
    
    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Text(parent.name.prefix(1).uppercased())
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.green)
            }
            
            VStack(alignment: .leading) {
                Text(parent.name)
                    .font(.headline)
                Text(parent.email)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Menu {
                Button(action: {
                    startCall(type: .voice)
                }) {
                    Label("Voice Call", systemImage: "phone.fill")
                }
                
                Button(action: {
                    startCall(type: .video)
                }) {
                    Label("Video Call", systemImage: "video.fill")
                }
            } label: {
                Image(systemName: "phone.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
            }
        }
        .padding(.vertical, 8)
        .onDisappear {
            callStatusListener?.remove()
        }
    }
    
    private func startCall(type: CallType) {
        guard let callerId = authService.currentUser?.uid else { return }
        
        let timestamp = Int(Date().timeIntervalSince1970)
        let channelName = "call_\(timestamp)_\(callerId.prefix(8))_\(parent.id.prefix(8))"
        
        isCalling = true
        RingtoneManager.shared.playRingtone(.outgoing)
        
        // Create the call object
        let callData: [String: Any] = [
            "callerId": callerId,
            "receiverId": parent.id,
            "channelName": channelName,
            "status": "ringing",
            "createdAt": Timestamp(date: Date()),
            "callType": type.rawValue,
            "timeoutAt": Timestamp(date: Date().addingTimeInterval(Constants.callTimeout))
        ]
        
        guard let call = Call(from: callData, id: channelName) else {
            isCalling = false
            RingtoneManager.shared.stopRingtone()
            return
        }
        
        activeCall = call
        agoraService.startCall(call: call)
        showCallView = true
        
        authService.createCall(from: callerId, to: parent.id, channelName: channelName, callType: type) { result in
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
            isCalling = false
            
            RingtoneManager.shared.stopRingtone()

            switch result {
            case .success(let accepted):
                if accepted {
                } else {
                    showCallView = false
                    activeCall = nil
                }
            case .failure(let error):
                print("Call error: \(error)")
                showCallView = false
                activeCall = nil
            }
        }
    }
    
    private func handleCallError(_ error: Error) {
        RingtoneManager.shared.stopRingtone()
        isCalling = false
        showCallView = false
        activeCall = nil
        print("Call failed: \(error)")
    }
    
}
