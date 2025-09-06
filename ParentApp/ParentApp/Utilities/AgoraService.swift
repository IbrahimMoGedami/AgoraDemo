//
//  AgoraService.swift
//  ParentApp
//
//  Created by Ibrahim Mo Gedami on 25/08/2025.
//

import Foundation
import AgoraRtcKit
import AVFAudio

class AgoraService: NSObject, ObservableObject {
    
    @Published var isInCall = false
    @Published var isMuted = false
    @Published var isSpeakerEnabled = true
    @Published var isVideoEnabled = true
    @Published var isCallAnswered = false
    @Published var connectionState: AgoraConnectionState = .disconnected
    @Published var currentChannel: String?
    @Published var callState: CallState = .idle
    @Published var currentCall: Call?
    @Published var remoteVideoUid: UInt? = nil
    @Published var isUpgradingToVideo = false
    
    enum CallState {
        case idle, initiating, ringing, inProgress, ending, upgrading
    }
    
    private var agoraKit: AgoraRtcEngineKit?
    private var uid: UInt = 0
    private var localVideoView: UIView?
    private var remoteVideoView: UIView?
    
    override init() {
        super.init()
        setupAgoraEngine()
        setupAudioSession()
    }
    
    private func setupAgoraEngine() {
        let config = AgoraRtcEngineConfig()
        config.appId = Constants.appId
        agoraKit = AgoraRtcEngineKit.sharedEngine(with: config, delegate: self)
        
        // Configure audio and video settings
        agoraKit?.setChannelProfile(.communication)
        agoraKit?.enableAudio()
        agoraKit?.enableVideo()
        agoraKit?.setAudioProfile(.speechStandard)
        agoraKit?.setVideoEncoderConfiguration(
            AgoraVideoEncoderConfiguration(
                size: AgoraVideoDimension640x360,
                frameRate: .fps15,
                bitrate: AgoraVideoBitrateStandard,
                orientationMode: .adaptative, mirrorMode: .enabled
            )
        )
        
        // Set audio session configuration
        agoraKit?.setAudioSessionOperationRestriction(.all)
        agoraKit?.enableAudioVolumeIndication(200, smooth: 3, reportVad: true)
    }
    
    func upgradeToVideoCall() {
        guard let agoraKit = agoraKit, currentCall != nil else { return }
        
        isUpgradingToVideo = true
        callState = .upgrading
        
        // Enable video publishing
        let options = AgoraRtcChannelMediaOptions()
        options.publishCameraTrack = true
        options.publishMicrophoneTrack = true
        options.clientRoleType = .broadcaster
        
        let result = agoraKit.updateChannel(with: options)
        if result == 0 {
            print("Successfully upgraded to video call")
            // Start local video preview
            agoraKit.startPreview()
            isVideoEnabled = true
            
            // Update local call state
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.callState = .inProgress
                self.isUpgradingToVideo = false
            }
        } else {
            print("Failed to upgrade to video call: \(result)")
            isUpgradingToVideo = false
            callState = .inProgress
        }
    }
    
    func downgradeToAudioCall() {
        guard let agoraKit = agoraKit else { return }
        
        // Disable video publishing
        let options = AgoraRtcChannelMediaOptions()
        options.publishCameraTrack = false
        options.publishMicrophoneTrack = true
        
        let result = agoraKit.updateChannel(with: options)
        
        if result == 0 {
            print("Successfully downgraded to audio call")
            isVideoEnabled = false
            agoraKit.stopPreview()
        } else {
            print("Failed to downgrade to audio call: \(result)")
        }
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetooth, .allowBluetoothA2DP])
            try audioSession.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    func setupLocalVideo(container: UIView) {
        guard let agoraKit = agoraKit else { return }
        
        let videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.uid = 0
        videoCanvas.view = container
        videoCanvas.renderMode = .hidden
        agoraKit.setupLocalVideo(videoCanvas)
        localVideoView = container
        
        // Start local preview
        agoraKit.startPreview()
    }
    
    func setupRemoteVideo(container: UIView, uid: UInt) {
        guard let agoraKit = agoraKit else { return }
        
        let videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.uid = uid
        videoCanvas.view = container
        videoCanvas.renderMode = .hidden
        agoraKit.setupRemoteVideo(videoCanvas)
        remoteVideoView = container
        remoteVideoUid = uid
    }
    
    func startCall(call: Call) {
        self.currentCall = call
        self.callState = .initiating
        self.isCallAnswered = false
        joinChannel(call.channelName)
    }
    
    func answerCall() {
        self.isCallAnswered = true
        self.callState = .inProgress
        RingtoneManager.shared.stopRingtone()
    }
    
    func joinChannel(_ channel: String, token: String? = nil) {
        guard let agoraKit else { return }
        
        connectionState = .connecting
        currentChannel = channel
        callState = .ringing
        let option = AgoraRtcChannelMediaOptions()
        option.clientRoleType = .broadcaster
        option.channelProfile = .communication
        option.publishCameraTrack = currentCall?.callType == .video
        option.publishMicrophoneTrack = true
        
        let result = agoraKit.joinChannel(
            byToken: Constants.token,
            channelId: Constants.channelName,
            uid: 0,
            mediaOptions: option,
            joinSuccess: nil
        )
        
        if result != 0 {
            connectionState = .failed
            print("Join channel failed with error code: \(result)")
            print("Error description: \(getAgoraErrorDescription(Int(result)))")
        }
    }
    
    // Helper function to get error description
    private func getAgoraErrorDescription(_ errorCode: Int) -> String {
        switch errorCode {
        case -1: return "Failed to initialize Agora engine"
        case -2: return "Invalid argument"
        case -3: return "Not ready"
        case -4: return "Not supported"
        case -5: return "Refused"
        case -6: return "Buffer too small"
        case -7: return "Not initialized"
        case -8: return "No permission"
        case -9: return "Timed out"
        case -10: return "Canceled"
        case -11: return "Too often"
        case -12: return "Bind socket error"
        case -13: return "Net down"
        case -14: return "No buffers"
        case -15: return "No memory"
        case -16: return "Port already in use"
        case -17: return "Too many items"
        case -18: return "Key expired"
        case -19: return "Permission denied"
        case -20: return "Connection interrupted"
        case -21: return "Connection lost"
        case -22: return "Not in channel"
        case -23: return "Size too large"
        case -24: return "Invalid URL"
        case -25: return "Invalid domain"
        case -26: return "DNS resolution failed"
        case -27: return "DNS timeout"
        case -101: return "Invalid App ID"
        case -102: return "Invalid channel name"
        case -103: return "Channel key expired"
        case -104: return "Channel key rejected"
        case -105: return "Socket error"
        case -106: return "Too many data streams"
        case -107: return "Stream not found"
        case -108: return "Decryption failed"
        case -109: return "User ignored"
        case -110: return "User muted"
        case -111: return "User not found"
        case -112: return "User not in channel"
        case -113: return "User not authorized"
        case -114: return "Audio device error"
        case -115: return "Video device error"
        case -116: return "Audio recording error"
        case -117: return "Audio playback error"
        case -118: return "No recording device"
        case -119: return "No playback device"
        case -120: return "Network error"
        case -121: return "Network timeout"
        case -122: return "Network response error"
        case -123: return "No network"
        case -124: return "Network busy"
        case -125: return "Network no route"
        case -126: return "Network unreachable"
        case -127: return "Network congestion"
        case -128: return "Network reset"
        case -129: return "Network aborted"
        case -130: return "Network refused"
        case -131: return "Network down"
        case -132: return "Network invalid argument"
        case -133: return "Network address in use"
        case -134: return "Network not connected"
        case -135: return "Network not initialized"
        case -136: return "Network not ready"
        case -137: return "Network not supported"
        case -138: return "Network protocol error"
        case -139: return "Network security error"
        case -140: return "Network ssl error"
        case -141: return "Network ssl handshake failed"
        case -142: return "Network ssl peer certificate error"
        case -143: return "Network ssl peer certificate expired"
        case -144: return "Network ssl peer certificate not yet valid"
        case -145: return "Network ssl peer certificate revoked"
        case -146: return "Network ssl peer certificate unknown"
        case -147: return "Network ssl peer certificate bad"
        case -148: return "Network ssl peer certificate unsupported"
        case -149: return "Network ssl peer certificate incomplete"
        case -150: return "Network ssl peer certificate format error"
        default: return "Unknown error (\(errorCode))"
        }
    }
    
    func leaveChannel() {
        guard let agoraKit = agoraKit else { return }
        agoraKit.stopPreview()
        agoraKit.leaveChannel { [weak self] stats in
            guard let self else { return }
            self.isInCall = false
            self.connectionState = .disconnected
            self.currentChannel = nil
            self.callState = .idle
            self.currentCall = nil
            self.remoteVideoUid = nil
            RingtoneManager.shared.stopRingtone()
            print("Left channel successfully")
        }
    }
    
    func toggleMute() {
        guard let agoraKit else { return }
        
        isMuted.toggle()
        agoraKit.muteLocalAudioStream(isMuted)
        print("Audio muted: \(isMuted)")
    }
    
    func toggleSpeaker() {
        guard let agoraKit = agoraKit else { return }
        
        isSpeakerEnabled.toggle()
        agoraKit.setEnableSpeakerphone(isSpeakerEnabled)
        print("Speaker enabled: \(isSpeakerEnabled)")
    }
    
    func toggleVideo() {
        guard let agoraKit = agoraKit else { return }
        
        isVideoEnabled.toggle()
        agoraKit.muteLocalVideoStream(!isVideoEnabled)
        print("Video enabled: \(isVideoEnabled)")
    }
    
    func switchCamera() {
        guard let agoraKit = agoraKit else { return }
        agoraKit.switchCamera()
    }
    
    func updateCallState(_ state: CallState) {
        callState = state
    }
    
    deinit {
        leaveChannel()
        AgoraRtcEngineKit.destroy()
    }

}

extension AgoraService: AgoraRtcEngineDelegate {
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
        DispatchQueue.main.async {
            self.isInCall = true
            self.connectionState = .connected
            self.uid = uid
            if self.callState == .initiating {
                self.callState = .inProgress
            }
            print("Successfully joined channel: \(channel) with UID: \(uid)")
        }
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didLeaveChannelWith stats: AgoraChannelStats) {
        DispatchQueue.main.async {
            self.isInCall = false
            self.connectionState = .disconnected
            self.callState = .idle
            self.remoteVideoUid = nil
            print("Left channel")
        }
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, firstRemoteVideoDecodedOfUid uid: UInt, size: CGSize, elapsed: Int) {
        DispatchQueue.main.async {
            self.remoteVideoUid = uid
            print("First remote video decoded for UID: \(uid)")
        }
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        DispatchQueue.main.async {
            if self.remoteVideoUid == uid {
                self.remoteVideoUid = nil
            }
        }
    }
    
    private func rtcEngine(_ engine: AgoraRtcEngineKit, connectionChangedTo state: AgoraConnectionState, reason: AgoraConnectionChangedReason) {
        DispatchQueue.main.async {
            switch state {
            case .connecting:
                self.connectionState = .connecting
                print("Connecting to channel...")
            case .connected:
                self.connectionState = .connected
                print("Connected to channel")
            case .reconnecting:
                self.connectionState = .reconnecting
                print("Reconnecting to channel...")
            case .failed:
                self.connectionState = .failed
                print("Connection failed")
            case .disconnected:
                self.connectionState = .disconnected
                print("Disconnected from channel")
            @unknown default:
                break
            }
        }
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurError errorCode: AgoraErrorCode) {
        DispatchQueue.main.async {
            let errorDescription = self.getAgoraErrorDescription(Int(errorCode.rawValue))
            print("Agora error \(errorCode.rawValue): \(errorDescription)")
            self.connectionState = .failed
        }
    }
    
}
