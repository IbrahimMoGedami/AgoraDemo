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
    
    let call: Call
    
    @State private var callDuration = 0
    @State private var timer: Timer?
    @State private var callStatusListener: ListenerRegistration?
    @State private var otherUserProfile: UserProfile?
    @State private var isLoadingProfile = true
    @State private var showCallEndedAlert = false
    @State private var isMinimized = false
    
    var body: some View {
        if isMinimized {
            minimizedCallView
        } else {
            fullCallView
        }
    }
    
    private var fullCallView: some View {
        ZStack {
            // Background with gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.7)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Caller info section
                VStack(spacing: 15) {
                    if isLoadingProfile {
                        ProgressView("Loading...")
                            .tint(.white)
                    } else if let profile = otherUserProfile {
                        // Profile image placeholder
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 120, height: 120)
                            
                            Text(profile.name.prefix(1).uppercased())
                                .font(.system(size: 50, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.bottom, 10)
                        
                        Text(profile.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                    }
                    
                    Text(connectionStatusText)
                        .font(.subheadline)
                        .foregroundColor(connectionStatusColor)
                        .padding(.top, 5)
                    
                    if agoraService.isCallAnswered {
                        Text(timeString(from: callDuration))
                            .font(.system(size: 24, weight: .medium, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(.top, 5)
                    } else {
                        Text(callStatusText)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.top, 5)
                    }
                }
                
                Spacer()
                
                // Call controls
                if agoraService.isCallAnswered {
                    HStack(spacing: 40) {
                        CallControlButton(
                            icon: agoraService.isMuted ? "mic.slash.fill" : "mic.fill",
                            text: agoraService.isMuted ? "Unmute" : "Mute",
                            color: agoraService.isMuted ? .red : .white,
                            backgroundColor: agoraService.isMuted ? .white.opacity(0.2) : .black.opacity(0.3),
                            action: { agoraService.toggleMute() }
                        )
                        
                        CallControlButton(
                            icon: "phone.down.fill",
                            text: "End",
                            color: .white,
                            backgroundColor: .red,
                            action: { endCall() }
                        )
                        
                        CallControlButton(
                            icon: agoraService.isSpeakerEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill",
                            text: agoraService.isSpeakerEnabled ? "Speaker" : "Earpiece",
                            color: .white,
                            backgroundColor: .black.opacity(0.3),
                            action: { agoraService.toggleSpeaker() }
                        )
                    }
                    .padding(.bottom, 50)
                } else if agoraService.callState == .ringing {
                    // Show calling status
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                            .padding()
                        
                        Button("Cancel Call") {
                            endCall()
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(10)
                    }
                }
            }
            .padding()
            
            // Minimize button
            VStack {
                HStack {
                    Spacer()
                    Button(action: { isMinimized = true }) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Circle().fill(Color.black.opacity(0.3)))
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 10)
                }
                Spacer()
            }
        }
        .onAppear {
            setupCallStatusListener()
            loadOtherUserProfile()
            
            // Only start timer if call is already answered
            if agoraService.isCallAnswered {
                startTimer()
            }
        }
        .onChange(of: agoraService.isCallAnswered) { _, answered in
            if answered {
                startTimer()
            } else {
                stopTimer()
            }
        }
        .onDisappear {
            cleanup()
        }
        .alert("Call Ended", isPresented: $showCallEndedAlert) {
            Button("OK") { dismiss() }
        } message: {
            Text("The other party has ended the call.")
        }
    }
    
    private var minimizedCallView: some View {
        HStack {
            if let profile = otherUserProfile {
                // Profile circle with initial
                ZStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 40, height: 40)
                    
                    Text(profile.name.prefix(1).uppercased())
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading) {
                    Text(profile.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    if agoraService.isCallAnswered {
                        Text(timeString(from: callDuration))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text(callStatusText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 15) {
                    Button(action: { endCall() }) {
                        Image(systemName: "phone.down.fill")
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Circle().fill(Color.red))
                    }
                    
                    Button(action: { isMinimized = false }) {
                        Image(systemName: "chevron.up")
                            .foregroundColor(.primary)
                            .padding(8)
                            .background(Circle().fill(Color.secondary.opacity(0.2)))
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(radius: 2)
        )
        .padding(.horizontal)
        .onAppear {
            // Keep timer running even when minimized
            if timer == nil && agoraService.isCallAnswered {
                startTimer()
            }
        }
    }
    
    private var connectionStatusText: String {
        switch agoraService.connectionState {
        case .connected: return "Connected"
        case .connecting: return "Connecting..."
        case .reconnecting: return "Reconnecting..."
        case .disconnected: return "Disconnected"
        case .failed: return "Connection Failed"
        @unknown default: return "Unknown"
        }
    }
    
    private var callStatusText: String {
        switch agoraService.callState {
        case .initiating: return "Calling..."
        case .ringing: return "Ringing..."
        case .inProgress: return "In Call"
        case .ending: return "Ending Call..."
        case .idle: return "Idle"
        @unknown default: return "Unknown"
        }
    }
    
    private var connectionStatusColor: Color {
        switch agoraService.connectionState {
        case .connected: return .green
        case .connecting, .reconnecting: return .orange
        case .disconnected, .failed: return .red
        @unknown default: return .gray
        }
    }
    
    private func setupCallStatusListener() {
        callStatusListener = authService.listenForCallStatus(channelName: call.channelName) { status in
            if status == "ended" || status == "timeout" || status == "rejected" {
                showCallEndedAlert = true
                endCall(updateFirebase: false)
            } else if status == "answered" {
                // Call was answered, update UI
                agoraService.answerCall()
            }
        }
    }
    
    private func loadOtherUserProfile() {
        guard let currentUserId = authService.currentUser?.uid else { return }
        
        let otherUserId = call.callerId == currentUserId ? call.receiverId : call.callerId
        authService.getUserProfile(userId: otherUserId) { result in
            isLoadingProfile = false
            if case .success(let profile) = result {
                otherUserProfile = profile
            }
        }
    }
    
    private func endCall(updateFirebase: Bool = true) {
        cleanup()
        
        if updateFirebase {
            authService.endCall(channelName: call.channelName) { _ in }
        }
        
        agoraService.leaveChannel()
        RingtoneManager.shared.playRingtone(.endCall)
        if !showCallEndedAlert {
            dismiss()
        }
    }
    
    private func startTimer() {
        stopTimer() // Ensure no existing timer
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
