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
    @Binding var activeCall: Call?
    
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
        
        // Create the call object
        let callData: [String: Any] = [
            "callerId": callerId,
            "receiverId": sitter.id,
            "channelName": channelName,
            "status": "ringing",
            "createdAt": Timestamp(date: Date()),
            "callType": "voice",
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
        
        authService.createCall(from: callerId, to: sitter.id, channelName: channelName) { [self] result in
            switch result {
            case .success:
                print("Call created, waiting for sitter to accept...")
                
                callStatusListener = authService.waitForCallAcceptance(channelName: channelName) { [self] acceptanceResult in
                    isCalling = false
                    RingtoneManager.shared.stopRingtone()

                    switch acceptanceResult {
                    case .success(let accepted):
                        if accepted {
                            print("Sitter accepted the call")
                            // Stop the ringtone when call is answered
                            // Agora service already handles joining the channel
                        } else {
                            print("Call was rejected or ended")
                            showCallView = false
                            activeCall = nil
                        }
                    case .failure(let error):
                        print("Error waiting for call acceptance: \(error)")
                        showCallView = false
                        activeCall = nil
                    }
                    callStatusListener?.remove()
                }
                
            case .failure(let error):
                print("Failed to create call: \(error.localizedDescription)")
                RingtoneManager.shared.stopRingtone()
                isCalling = false
                showCallView = false
                activeCall = nil
            }
        }
    }
    
}
