//
//  RingtoneManager.swift
//  SitterApp
//
//  Created by Ibrahim Mo Gedami on 26/08/2025.
//

import Foundation
import AVFoundation
import Foundation

class RingtoneManager: ObservableObject {
    
    static let shared = RingtoneManager()
    private var audioPlayer: AVAudioPlayer?
    
    private init() {}
    
    func playRingtone(_ type: RingtoneType) {
        stopRingtone()
        
        let soundName: String
        switch type {
        case .incoming:
            soundName = "incoming_call"
        case .outgoing:
            soundName = "outgoing_call"
        case .endCall:
            soundName = "call_end"
        }
        guard let url = Bundle.main.url(forResource: soundName, withExtension: "mp3") else {
            print("Ringtone file not found")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = type == .endCall ? 0 : -1
            audioPlayer?.play()
        } catch {
            print("Failed to play ringtone: \(error)")
        }
    }
    
    func stopRingtone() {
        audioPlayer?.stop()
    }
    
}
