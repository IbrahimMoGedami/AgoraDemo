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
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    let call: Call
    
    @State private var callDuration = 0
    @State private var timer: Timer?
    @State private var callStatusListener: ListenerRegistration?
    @State private var callTypeListener: ListenerRegistration?
    @State private var otherUserProfile: UserProfile?
    @State private var isLoadingProfile = true
    @State private var showCallEndedAlert = false
    @State private var showUpgradeAlert = false
    @State private var currentCallType: CallType
    @State private var isUpgrading = false
    
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
            return 40
        } else if isCompactWidth {
            return 45
        } else {
            return 50
        }
    }
    
    private var buttonIconSize: CGFloat {
        if isVeryCompact {
            return 15
        } else if isCompactWidth {
            return 20
        } else {
            return 25
        }
    }
    
    private var buttonTextSize: CGFloat {
        if isVeryCompact {
            return 8
        } else if isCompactWidth {
            return 10
        } else {
            return 12
        }
    }
    
    private var buttonSpacing: CGFloat {
        if isVeryCompact {
            return 8
        } else if isCompactWidth {
            return 10
        } else {
            return 12
        }
    }
    
    private var controlsPadding: CGFloat {
        if isVeryCompact {
            return 10
        } else if isCompactWidth {
            return 12
        } else {
            return 14
        }
    }
    
    init(call: Call) {
        self.call = call
        self._currentCallType = State(initialValue: call.callType)
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
                callContent
                
                Spacer()
                
                // Call controls
                if agoraService.isCallAnswered {
                    callControls
                        .padding(.bottom, controlsPadding)
                } else if agoraService.callState == .ringing {
                    callingStatusView
                }
            }
            
            if isUpgrading {
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
                
                VStack {
                    ProgressView("Upgrading to video call...")
                        .tint(.white)
                        .scaleEffect(1.5)
                    
                    Text("Please wait")
                        .foregroundColor(.white)
                        .padding(.top, 10)
                }
            }
        }
        .onAppear {
            setupVideoViews()
            setupCallStatusListener()
            setupCallTypeListener()
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
        .alert("Upgrade to Video Call", isPresented: $showUpgradeAlert) {
            Button("Upgrade") {
                initiateCallUpgrade()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Do you want to upgrade this audio call to a video call?")
        }
    }
    
    private var callContent: some View {
        Group {
            if currentCallType == .video {
                // Video call UI
                ZStack {
                    VideoView(uiView: remoteVideoView)
                        .frame(maxWidth: .infinity, maxHeight: isVeryCompact ? .infinity : .infinity)
                        .opacity(agoraService.remoteVideoUid != nil ? 1 : 0)
                    
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
                    
                    if agoraService.remoteVideoUid == nil {
                        audioFallbackUI
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: isVeryCompact ? .infinity : .infinity)
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
        }
    }
    
    private var audioFallbackUI: some View {
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
    
    private var callControls: some View {
        HStack {
            Spacer()
            HStack(spacing: buttonSpacing * 1.5) {
                // Mute button
                CallControlButton(
                    icon: agoraService.isMuted ? "mic.slash.fill" : "mic.fill",
                    text: agoraService.isMuted ? "Unmute" : "Mute",
                    isActive: !agoraService.isMuted,
                    backgroundColor: agoraService.isMuted ? .red : .white,
                    foregroundColor: agoraService.isMuted ? .white.opacity(0.2) : .black.opacity(0.3),
                    size: buttonSize,
                    iconSize: buttonIconSize,
                    textSize: buttonTextSize,
                    action: { agoraService.toggleMute() }
                )
                
                // End call button (centered and emphasized)
                CallControlButton(
                    icon: "phone.down.fill",
                    text: "End",
                    isActive: true,
                    backgroundColor: .red,
                    foregroundColor: .white,
                    size: buttonSize * 1.2,
                    iconSize: buttonIconSize * 1.2,
                    textSize: buttonTextSize,
                    action: { endCall() }
                )
                
                // Speaker button
                CallControlButton(
                    icon: agoraService.isSpeakerEnabled ? "speaker.wave.3.fill" : "speaker.slash.fill",
                    text: "Speaker",
                    isActive: agoraService.isSpeakerEnabled,
                    backgroundColor: .black.opacity(0.3),
                    foregroundColor: .white,
                    size: buttonSize,
                    iconSize: buttonIconSize,
                    textSize: buttonTextSize,
                    action: { agoraService.toggleSpeaker() }
                )
                
                if currentCallType == .video {
                    // Video toggle
                    CallControlButton(
                        icon: agoraService.isVideoEnabled ? "video.fill" : "video.slash.fill",
                        text: "Video",
                        isActive: agoraService.isVideoEnabled,
                        backgroundColor: .black.opacity(0.3),
                        foregroundColor: .white,
                        size: buttonSize,
                        iconSize: buttonIconSize,
                        textSize: buttonTextSize,
                        action: { agoraService.toggleVideo() }
                    )
                    
                    // Camera switch
                    CallControlButton(
                        icon: "camera.rotate",
                        text: "Flip",
                        isActive: true,
                        backgroundColor: .blue.opacity(0.8),
                        foregroundColor: .white,
                        size: buttonSize,
                        iconSize: buttonIconSize,
                        textSize: buttonTextSize,
                        action: { agoraService.switchCamera() }
                    )
                    
                    // Downgrade to audio
                    CallControlButton(
                        icon: "phone.fill",
                        text: "Audio",
                        isActive: true,
                        backgroundColor: .blue.opacity(0.8),
                        foregroundColor: .white,
                        size: buttonSize,
                        iconSize: buttonIconSize,
                        textSize: buttonTextSize,
                        action: { downgradeToAudio() }
                    )
                } else {
                    // Upgrade to video
                    CallControlButton(
                        icon: "video.fill",
                        text: "Video",
                        isActive: true,
                        backgroundColor: .blue,
                        foregroundColor: .white,
                        size: buttonSize,
                        iconSize: buttonIconSize,
                        textSize: buttonTextSize,
                        action: { showUpgradeAlert = true }
                    )
                }
            }
            Spacer()
        }
    }
    
    private var callingStatusView: some View {
        CallControlButton(
            icon: "phone.down.fill",
            text: "End Call",
            isActive: true,
            backgroundColor: .red,
            foregroundColor: .white,
            size: buttonSize * 1.1,
            iconSize: buttonIconSize * 1.1,
            textSize: buttonTextSize,
            action: { endCall() }
        )
    }
    
    private func setupVideoViews() {
        if currentCallType == .video {
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
        case .upgrading: return "Upgrading To Video Call"
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
    
    private func setupCallTypeListener() {
        callTypeListener = authService.listenForCallTypeChanges(channelName: call.channelName) { callType in
            if callType != self.currentCallType {
                self.handleCallTypeChange(newCallType: callType)
            }
        }
    }
    
    private func handleCallTypeChange(newCallType: CallType) {
        if newCallType == .video && currentCallType == .voice {
            // Received upgrade request
            acceptCallUpgrade()
        } else if newCallType == .voice && currentCallType == .video {
            // Received downgrade request
            acceptCallDowngrade()
        }
    }
    
    private func initiateCallUpgrade() {
        isUpgrading = true
        
        // Update Firebase first
        authService.updateCallType(channelName: call.channelName, callType: .video) { result in
            switch result {
            case .success:
                // Then upgrade Agora connection
                self.agoraService.upgradeToVideoCall()
                self.currentCallType = .video
                self.setupVideoViews()
                self.isUpgrading = false
                
            case .failure(let error):
                print("Failed to upgrade call: \(error)")
                self.isUpgrading = false
            }
        }
    }
    
    private func acceptCallUpgrade() {
        isUpgrading = true
        
        // Upgrade Agora connection
        agoraService.upgradeToVideoCall()
        currentCallType = .video
        setupVideoViews()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.isUpgrading = false
        }
    }
    
    private func acceptCallDowngrade() {
        agoraService.downgradeToAudioCall()
        currentCallType = .voice
    }
    
    private func downgradeToAudio() {
        // Update Firebase first
        authService.updateCallType(channelName: call.channelName, callType: .voice) { result in
            switch result {
            case .success:
                // Then downgrade Agora connection
                self.agoraService.downgradeToAudioCall()
                self.currentCallType = .voice
                
            case .failure(let error):
                print("Failed to downgrade call: \(error)")
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
        callTypeListener?.remove()
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
