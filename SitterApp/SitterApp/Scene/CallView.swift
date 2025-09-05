//
//  CallView.swift
//  SitterApp
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
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    let call: Call
    
    @State private var callDuration = 0
    @State private var timer: Timer?
    @State private var callStatusListener: ListenerRegistration?
    @State private var otherUserProfile: UserProfile?
    @State private var isLoadingProfile = true
    @State private var showCallEndedAlert = false
    @State private var isVideoFullscreen = false
    
    // Video views
    @State private var localVideoView = UIView()
    @State private var remoteVideoView = UIView()
    
    // Adaptive layout properties
    private var isCompactWidth: Bool {
        horizontalSizeClass == .compact
    }
    
    private var isCompactHeight: Bool {
        verticalSizeClass == .compact
    }
    
    private var isVeryCompact: Bool {
        isCompactWidth && isCompactHeight
    }
    
    // Button sizing
    private var buttonSize: CGFloat {
        if isVeryCompact {
            return 50
        } else if isCompactWidth {
            return 60
        } else {
            return 70
        }
    }
    
    private var buttonIconSize: CGFloat {
        if isVeryCompact {
            return 20
        } else if isCompactWidth {
            return 24
        } else {
            return 28
        }
    }
    
    private var buttonTextSize: CGFloat {
        if isVeryCompact {
            return 10
        } else if isCompactWidth {
            return 12
        } else {
            return 14
        }
    }
    
    private var buttonSpacing: CGFloat {
        if isVeryCompact {
            return 16
        } else if isCompactWidth {
            return 20
        } else {
            return 30
        }
    }
    
    private var controlsPadding: CGFloat {
        if isVeryCompact {
            return 12
        } else if isCompactWidth {
            return 16
        } else {
            return 20
        }
    }
    
    var body: some View {
        callView
    }
    
    private var callView: some View {
        ZStack {
            // Background with gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.7)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Video container
                if call.callType == .video {
                    ZStack {
                        // Remote video
                        VideoView(uiView: remoteVideoView)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .opacity(agoraService.remoteVideoUid != nil ? 1 : 0)
                        
                        // Local video preview (pip)
                        if agoraService.isVideoEnabled {
                            VideoView(uiView: localVideoView)
                                .frame(
                                    width: isVeryCompact ? 80 : 120,
                                    height: isVeryCompact ? 100 : 160
                                )
                                .cornerRadius(8)
                                .padding(isVeryCompact ? 8 : 12)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        }
                        
                        // Caller info overlay when no video
                        if agoraService.remoteVideoUid == nil {
                            VStack(spacing: isVeryCompact ? 12 : 20) {
                                if isLoadingProfile {
                                    ProgressView("Loading...")
                                        .tint(.white)
                                        .scaleEffect(isVeryCompact ? 0.8 : 1.0)
                                } else if let profile = otherUserProfile {
                                    ZStack {
                                        Circle()
                                            .fill(Color.white.opacity(0.2))
                                            .frame(
                                                width: isVeryCompact ? 80 : 120,
                                                height: isVeryCompact ? 80 : 120
                                            )
                                        
                                        Text(profile.name.prefix(1).uppercased())
                                            .font(.system(
                                                size: isVeryCompact ? 30 : 50,
                                                weight: .bold
                                            ))
                                            .foregroundColor(.white)
                                    }
                                    
                                    Text(profile.name)
                                        .font(.system(
                                            size: isVeryCompact ? 16 : 20,
                                            weight: .bold
                                        ))
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 8)
                                }
                                
                                Text(connectionStatusText)
                                    .font(.system(size: isVeryCompact ? 12 : 14))
                                    .foregroundColor(connectionStatusColor)
                            }
                            .padding()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Audio call UI
                    VStack(spacing: isVeryCompact ? 20 : 30) {
                        if isLoadingProfile {
                            ProgressView("Loading...")
                                .tint(.white)
                                .scaleEffect(isVeryCompact ? 0.8 : 1.0)
                        } else if let profile = otherUserProfile {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(
                                        width: isVeryCompact ? 80 : 120,
                                        height: isVeryCompact ? 80 : 120
                                    )
                                
                                Text(profile.name.prefix(1).uppercased())
                                    .font(.system(
                                        size: isVeryCompact ? 30 : 50,
                                        weight: .bold
                                    ))
                                    .foregroundColor(.white)
                            }
                            
                            Text(profile.name)
                                .font(.system(
                                    size: isVeryCompact ? 16 : 20,
                                    weight: .bold
                                ))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 8)
                        }
                        
                        Text(connectionStatusText)
                            .font(.system(size: isVeryCompact ? 12 : 14))
                            .foregroundColor(connectionStatusColor)
                        
                        if agoraService.isCallAnswered {
                            Text(timeString(from: callDuration))
                                .font(.system(
                                    size: isVeryCompact ? 18 : 24,
                                    weight: .medium,
                                    design: .monospaced
                                ))
                                .foregroundColor(.white)
                        } else {
                            Text(callStatusText)
                                .font(.system(
                                    size: isVeryCompact ? 14 : 18,
                                    weight: .medium
                                ))
                                .foregroundColor(.white)
                        }
                    }
                    .padding()
                }
                
                Spacer()
                
                // Call controls
                if agoraService.isCallAnswered {
                    callControls
                        .padding(.bottom, controlsPadding)
                } else if agoraService.callState == .ringing {
                    callingStatusView
                }
            }
        }
        .onAppear {
            setupVideoViews()
            setupCallStatusListener()
            loadOtherUserProfile()
            
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
    
    private var callControls: some View {
        Group {
            if call.callType == .video {
                // Video call controls with more buttons
                VStack(spacing: 12) {
                    // Primary controls row
                    HStack(spacing: buttonSpacing) {
                        // Mute button
                        CallControlButton(
                            icon: agoraService.isMuted ? "mic.slash.fill" : "mic.fill",
                            text: agoraService.isMuted ? "Unmute" : "Mute",
                            color: agoraService.isMuted ? .red : .white,
                            backgroundColor: agoraService.isMuted ? .white.opacity(0.2) : .black.opacity(0.3),
                            size: buttonSize,
                            iconSize: buttonIconSize,
                            textSize: buttonTextSize,
                            action: { agoraService.toggleMute() }
                        )
                        
                        // End call button
                        CallControlButton(
                            icon: "phone.down.fill",
                            text: "End",
                            color: .white,
                            backgroundColor: .red,
                            size: buttonSize,
                            iconSize: buttonIconSize,
                            textSize: buttonTextSize,
                            action: { endCall() }
                        )
                        
                        // Speaker button
                        CallControlButton(
                            icon: agoraService.isSpeakerEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill",
                            text: agoraService.isSpeakerEnabled ? "Speaker" : "Earpiece",
                            color: .white,
                            backgroundColor: .black.opacity(0.3),
                            size: buttonSize,
                            iconSize: buttonIconSize,
                            textSize: buttonTextSize,
                            action: { agoraService.toggleSpeaker() }
                        )
                    }
                    
                    // Secondary controls row
                    HStack(spacing: buttonSpacing) {
                        // Video toggle button
                        CallControlButton(
                            icon: agoraService.isVideoEnabled ? "video.fill" : "video.slash.fill",
                            text: agoraService.isVideoEnabled ? "Video On" : "Video Off",
                            color: agoraService.isVideoEnabled ? .white : .red,
                            backgroundColor: .black.opacity(0.3),
                            size: buttonSize,
                            iconSize: buttonIconSize,
                            textSize: buttonTextSize,
                            action: { agoraService.toggleVideo() }
                        )
                        
                        // Camera switch button
                        CallControlButton(
                            icon: "camera.rotate.fill",
                            text: "Switch",
                            color: .white,
                            backgroundColor: .black.opacity(0.3),
                            size: buttonSize,
                            iconSize: buttonIconSize,
                            textSize: buttonTextSize,
                            action: { agoraService.switchCamera() }
                        )
                        
                        // Placeholder for layout balance
                        CallControlButton(
                            icon: "circle.fill",
                            text: "More",
                            color: .clear,
                            backgroundColor: .clear,
                            size: buttonSize,
                            iconSize: buttonIconSize,
                            textSize: buttonTextSize,
                            action: {}
                        )
                        .hidden()
                    }
                }
            } else {
                // Audio call controls - simpler layout
                HStack(spacing: buttonSpacing) {
                    // Mute button
                    CallControlButton(
                        icon: agoraService.isMuted ? "mic.slash.fill" : "mic.fill",
                        text: agoraService.isMuted ? "Unmute" : "Mute",
                        color: agoraService.isMuted ? .red : .white,
                        backgroundColor: agoraService.isMuted ? .white.opacity(0.2) : .black.opacity(0.3),
                        size: buttonSize,
                        iconSize: buttonIconSize,
                        textSize: buttonTextSize,
                        action: { agoraService.toggleMute() }
                    )
                    
                    // End call button
                    CallControlButton(
                        icon: "phone.down.fill",
                        text: "End",
                        color: .white,
                        backgroundColor: .red,
                        size: buttonSize,
                        iconSize: buttonIconSize,
                        textSize: buttonTextSize,
                        action: { endCall() }
                    )
                    
                    // Speaker button
                    CallControlButton(
                        icon: agoraService.isSpeakerEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill",
                        text: agoraService.isSpeakerEnabled ? "Speaker" : "Earpiece",
                        color: .white,
                        backgroundColor: .black.opacity(0.3),
                        size: buttonSize,
                        iconSize: buttonIconSize,
                        textSize: buttonTextSize,
                        action: { agoraService.toggleSpeaker() }
                    )
                }
            }
        }
        .padding(.horizontal, controlsPadding)
    }
    
    private var callingStatusView: some View {
        VStack {
            CallControlButton(
                icon: "phone.down.fill",
                text: "End",
                color: .white,
                backgroundColor: .red,
                size: buttonSize,
                iconSize: buttonIconSize,
                textSize: buttonTextSize,
                action: { endCall() }
            )
        }
    }
    
    private func setupVideoViews() {
        if call.callType == .video {
            agoraService.setupLocalVideo(container: localVideoView)
            
            // Setup remote video when available
            if let remoteUid = agoraService.remoteVideoUid {
                agoraService.setupRemoteVideo(container: remoteVideoView, uid: remoteUid)
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
            if status == .ended || status == .timeout || status == .rejected {
                showCallEndedAlert = true
                endCall(updateFirebase: false)
            } else if status == .answered {
                RingtoneManager.shared.stopRingtone()
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
