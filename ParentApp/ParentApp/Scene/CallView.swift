//
//  CallView.swift
//  ParentApp
//
//  Created by Ibrahim Mo Gedami on 26/08/2025.
//

import Foundation
import SwiftUI
import AgoraRtcKit
import FirebaseFirestore

struct CallView: View {
    
    @EnvironmentObject var agoraService: AgoraService
    @EnvironmentObject var authService: FirebaseService
    @Environment(\.dismiss) var dismiss
    @State private var callDuration = 0
    @State private var timer: Timer?
    @State private var currentChannel: String?
    @State private var callStatusListener: ListenerRegistration?
    @State private var otherUserProfile: UserProfile?
    @State private var isLoadingProfile = true
    @State private var showCallEndedAlert = false
    
    var body: some View {
        VStack(spacing: 30) {
            // Call header
            VStack {
                if isLoadingProfile {
                    ProgressView("Loading...")
                } else if let profile = otherUserProfile {
                    Text(profile.name).font(.title2).fontWeight(.bold)
                    Text(profile.userType.capitalized).font(.subheadline).foregroundColor(.secondary)
                }
                
                Text("Ongoing Call")
                    .font(.title2)
                
                Text(timeString(from: callDuration))
                    .font(.title3)
                    .monospacedDigit()
//                
//                Text(agoraService.connectionState == .connected ? "Connected" : "Connecting...")
//                    .foregroundColor(agoraService.connectionState == .connected ? .green : .orange)
                Text(connectionStatusText)
                    .foregroundColor(connectionStatusColor)
            }
            
            // Call controls
            HStack(spacing: 40) {
                CallControlButton(
                    icon: agoraService.isMuted ? "mic.slash.fill" : "mic.fill",
                    text: agoraService.isMuted ? "Unmute" : "Mute",
                    color: agoraService.isMuted ? .red : .gray,
                    action: { agoraService.toggleMute() }
                )
                
                CallControlButton(
                    icon: "phone.down.fill",
                    text: "End Call",
                    color: .red,
                    action: { endCall() }
                )
                
                CallControlButton(
                    icon: agoraService.isSpeakerEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill",
                    text: agoraService.isSpeakerEnabled ? "Speaker" : "Earpiece",
                    color: agoraService.isSpeakerEnabled ? .green : .gray,
                    action: { agoraService.toggleSpeaker() }
                )
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            startTimer()
            currentChannel = agoraService.currentChannel
            setupCallStatusListener()
            loadOtherUserProfile()
        }
        .onDisappear {
            cleanup()
        }
    }
    
    private var connectionStatusText: String {
        switch agoraService.connectionState {
        case .connected: return "Connected"
        case .connecting: return "Connecting..."
        case .reconnecting: return "Reconnecting..."
        case .disconnected: return "Disconnected"
        case .failed: return "Connection Failed"
        @unknown default: break
        }
    }
    
    private var connectionStatusColor: Color {
        switch agoraService.connectionState {
        case .connected: return .green
        case .connecting, .reconnecting: return .orange
        case .disconnected, .failed: return .red
        @unknown default: break
        }
    }
    
    private func setupCallStatusListener() {
        guard let channel = currentChannel else { return }
        
        callStatusListener = authService.listenForCallStatus(channelName: channel) { status in
            if status == "ended" || status == "timeout" {
                showCallEndedAlert = true
                endCall(updateFirebase: false)
            }
        }
    }
    
    private func loadOtherUserProfile() {
        guard let currentUserId = authService.currentUser?.uid,
              let channel = currentChannel else { return }
        
        authService.getCallInfo(channelName: channel) { result in
            isLoadingProfile = false
            if case .success(let call) = result {
                let otherUserId = call.callerId == currentUserId ? call.receiverId : call.callerId
                authService.getUserProfile(userId: otherUserId) { result in
                    if case .success(let profile) = result {
                        otherUserProfile = profile
                    }
                }
            }
        }
    }
    
    private func endCall(updateFirebase: Bool = true) {
        cleanup()
        
        if updateFirebase, let channel = currentChannel {
            authService.endCall(channelName: channel) { _ in }
        }
        
        agoraService.leaveChannel()
        RingtoneManager.shared.playRingtone(.endCall)
        if !showCallEndedAlert {
            dismiss()
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            callDuration += 1
        }
    }
    
    private func cleanup() {
        stopTimer()
        callStatusListener?.remove()
        RingtoneManager.shared.stopRingtone()
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }

}
