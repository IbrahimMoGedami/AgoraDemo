//
//  SitterRow.swift
//  ParentApp
//
//  Created by Ibrahim Mo Gedami on 26/08/2025.
//

import Foundation
import SwiftUI
import FirebaseFirestore

struct SitterRow: View {
    
    @EnvironmentObject var authService: FirebaseService
    @EnvironmentObject var agoraService: AgoraService
    let sitter: UserProfile
    @Binding var showCallView: Bool
    
    @State private var isCalling = false
    @State private var callStatusListener: ListenerRegistration?
    
    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Text(sitter.name.prefix(1).uppercased())
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading) {
                Text(sitter.name)
                    .font(.headline)
                Text(sitter.email)
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
            .buttonStyle(BorderlessButtonStyle())
        }
        .padding(.vertical, 8)
        .onDisappear {
            callStatusListener?.remove()
        }
    }
    
    private func startCall() {
        guard let callerId = authService.currentUser?.uid else { return }
        
        let timestamp = Int(Date().timeIntervalSince1970)
        let channelName = "call_\(timestamp)_\(callerId.prefix(8))_\(sitter.id.prefix(8))"
        
        print("Creating call with channel: \(channelName)")
        isCalling = true
        RingtoneManager.shared.playRingtone(.outgoing)
        
        authService.createCall(from: callerId, to: sitter.id, channelName: channelName) { [self] result in
            switch result {
            case .success:
                print("Call created, waiting for sitter to accept...")
                
                callStatusListener = authService.waitForCallAcceptance(channelName: channelName) { [self] acceptanceResult in
                    RingtoneManager.shared.stopRingtone()
                    
                    switch acceptanceResult {
                    case .success(let accepted):
                        if accepted {
                            print("Sitter accepted the call, joining channel...")
                            agoraService.joinChannel(channelName)
                            showCallView = true
                        } else {
                            print("Call was rejected or ended")
                        }
                    case .failure(let error):
                        print("Error waiting for call acceptance: \(error)")
                    }
                    isCalling = false
                    callStatusListener?.remove()
                }
                
            case .failure(let error):
                print("Failed to create call: \(error.localizedDescription)")
                RingtoneManager.shared.stopRingtone()
                isCalling = false
            }
        }
    }
    
}
