//
//  IncomingCallView.swift
//  SitterApp
//
//  Created by Ibrahim Mo Gedami on 26/08/2025.
//

import Foundation
import SwiftUI
import FirebaseFirestore

struct IncomingCallView: View {
    
    @EnvironmentObject var authService: FirebaseService
    @EnvironmentObject var agoraService: AgoraService
    @Environment(\.dismiss) var dismiss
    let call: Call
    @State private var callerProfile: UserProfile?
    @State private var isLoading = true
    @State private var callStatusListener: ListenerRegistration?
    @State private var timeoutTimer: Timer?
    
    var body: some View {
        VStack(spacing: 30) {
            if isLoading {
                ProgressView("Loading caller info...")
            } else if let caller = callerProfile {
                VStack(spacing: 20) {
                    Text("Incoming Call")
                        .font(.title2)
                    
                    Text(caller.name)
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text(caller.email)
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 40) {
                        Button {
                            rejectCall()
                        } label: {
                            Image(systemName: "phone.down.fill")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.red)
                                .clipShape(Circle())
                        }
                        
                        Button {
                            acceptCall()
                        } label: {
                            Image(systemName: "phone.fill")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.green)
                                .clipShape(Circle())
                        }
                    }
                }
            } else {
                Text("Caller information not available")
            }
        }
        .padding()
        .onAppear {
            loadCallerInfo()
            setupCallStatusListener()
            startTimeoutTimer()
            RingtoneManager.shared.playRingtone(.incoming)
        }
        .onDisappear {
            cleanup()
        }
    }
    
    private func startTimeoutTimer() {
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: Constants.callTimeout, repeats: false) { _ in
            autoRejectCall()
        }
    }
    
    private func autoRejectCall() {
        authService.updateCallStatus(channelName: call.channelName, status: "timeout") { _ in }
        dismiss()
    }
    
    private func cleanup() {
        callStatusListener?.remove()
        timeoutTimer?.invalidate()
        RingtoneManager.shared.stopRingtone()
    }
    
    private func setupCallStatusListener() {
        callStatusListener = authService.listenForCallStatus(channelName: call.channelName) { status in
            if status == "ended" || status == "timeout" {
                dismiss()
            }
        }
    }
    
    private func loadCallerInfo() {
        authService.getUserProfile(userId: call.callerId) { result in
            isLoading = false
            switch result {
            case .success(let profile):
                callerProfile = profile
            case .failure:
                callerProfile = nil
            }
        }
    }
    
    private func acceptCall() {
        authService.updateCallStatus(channelName: call.channelName, status: "accepted") { result in
            switch result {
            case .success:
                RingtoneManager.shared.stopRingtone()
                agoraService.joinChannel(call.channelName)
                dismiss()
            case .failure(let error):
                print("Failed to accept call: \(error)")
            }
        }
    }
    
    private func rejectCall() {
        authService.updateCallStatus(channelName: call.channelName, status: "rejected") { result in
            switch result {
            case .success:
                RingtoneManager.shared.stopRingtone()
                dismiss()
            case .failure(let error):
                print("Failed to reject call: \(error)")
            }
        }
    }

}
