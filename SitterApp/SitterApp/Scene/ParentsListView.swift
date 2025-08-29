//
//  ParentsListView.swift
//  SitterApp
//
//  Created by Ibrahim Mo Gedami on 26/08/2025.
//

import Foundation
import SwiftUI
import FirebaseFirestore

struct ParentsListView: View {
    
    let parents: [UserProfile]
    let isLoading: Bool
    
    var body: some View {
        List {
            if isLoading {
                ProgressView("Loading parents...")
            } else if parents.isEmpty {
                Text("No parents available")
                    .foregroundColor(.gray)
            } else {
                ForEach(parents) { parent in
                    ParentRow(parent: parent)
                }
            }
        }
    }

}

struct ParentRow: View {
    
    @EnvironmentObject var authService: FirebaseService
    @EnvironmentObject var agoraService: AgoraService
    let parent: UserProfile
    @State private var isCalling = false
    @State private var callStatusListener: ListenerRegistration?
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(parent.name)
                    .font(.headline)
                Text(parent.email)
                    .font(.subheadline)
                    .foregroundColor(.gray)
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
        .onDisappear {
            callStatusListener?.remove()
        }
    }
    
    private func startCall() {
        guard let callerId = authService.currentUser?.uid else { return }
        
        let timestamp = Int(Date().timeIntervalSince1970)
        let channelName = "call_\(timestamp)_\(callerId.prefix(8))_\(parent.id.prefix(8))"
        
        isCalling = true
        RingtoneManager.shared.playRingtone(.outgoing)
        
        authService.createCall(from: callerId, to: parent.id, channelName: channelName) { [self] result in
            switch result {
            case .success:
                callStatusListener = authService.waitForCallAcceptance(channelName: channelName) { [self] acceptanceResult in
                    RingtoneManager.shared.stopRingtone()
                    
                    switch acceptanceResult {
                    case .success(let accepted):
                        if accepted {
                            agoraService.joinChannel(channelName)
                        }
                    case .failure(let error):
                        print("Error: \(error)")
                    }
                    isCalling = false
                    callStatusListener?.remove()
                }
                
            case .failure(let error):
                RingtoneManager.shared.stopRingtone()
                print("Failed to create call: \(error)")
                isCalling = false
            }
        }
    }

}
