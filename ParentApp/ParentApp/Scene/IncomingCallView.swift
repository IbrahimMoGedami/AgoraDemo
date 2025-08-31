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
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                if isLoading {
                    ProgressView("Loading...")
                        .tint(.white)
                } else if let caller = callerProfile {
                    VStack(spacing: 25) {
                        // Caller profile image
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 120, height: 120)
                            
                            Text(caller.name.prefix(1).uppercased())
                                .font(.system(size: 50, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 5) {
                            Text(caller.name)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            Text("Incoming Call")
                                .font(.body)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    
                    Spacer()
                    
                    // Call action buttons
                    HStack(spacing: 60) {
                        // Decline button
                        VStack {
                            Button {
                                rejectCall()
                            } label: {
                                Image(systemName: "phone.down.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                                    .frame(width: 70, height: 70)
                                    .background(Color.red)
                                    .clipShape(Circle())
                            }
                            
                            Text("Decline")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.top, 5)
                        }
                        
                        // Accept button
                        VStack {
                            Button {
                                acceptCall()
                            } label: {
                                Image(systemName: "phone.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                                    .frame(width: 70, height: 70)
                                    .background(Color.green)
                                    .clipShape(Circle())
                            }
                            
                            Text("Accept")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.top, 5)
                        }
                    }
                    .padding(.bottom, 50)
                } else {
                    Text("Caller information not available")
                        .foregroundColor(.white)
                }
            }
            .padding()
        }
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
        authService.updateCallStatus(channelName: call.channelName, status: "answered") { result in
            switch result {
            case .success:
                RingtoneManager.shared.stopRingtone()
                agoraService.startCall(call: call)
                agoraService.answerCall()
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
