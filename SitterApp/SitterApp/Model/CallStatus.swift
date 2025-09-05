//
//  CallStatus.swift
//  SitterApp
//
//  Created by Ibrahim Mo Gedami on 25/08/2025.
//

import Foundation
import FirebaseCore
import FirebaseFirestore

enum CallType: String, Codable {
    case voice, video
}

enum CallStatus: String, Codable {
    case initiating, ringing, inProgress, answered, ended, missed, rejected, timeout
}

enum AgoraConnectionState {
    case disconnected, connecting, connected, reconnecting, failed
}

enum UserType: String, Codable {
    case parent, sitter
}

enum RingtoneType {
    case incoming, outgoing, endCall
}

struct Call: Identifiable {
    let id: String
    let callerId: String
    let receiverId: String
    let channelName: String
    let status: String
    let createdAt: Date
    let callType: CallType
    let timeoutAt: Date?
    
    init?(from data: [String: Any], id: String) {
        guard let callerId = data["callerId"] as? String,
              let receiverId = data["receiverId"] as? String,
              let channelName = data["channelName"] as? String,
              let status = data["status"] as? String,
              let timestamp = data["createdAt"] as? Timestamp,
              let callTypeString = data["callType"] as? String,
              let callType = CallType(rawValue: callTypeString) else {
            return nil
        }
        
        self.id = id
        self.callerId = callerId
        self.receiverId = receiverId
        self.channelName = channelName
        self.status = status
        self.createdAt = timestamp.dateValue()
        self.callType = callType
        self.timeoutAt = (data["timeoutAt"] as? Timestamp)?.dateValue()
    }
}

struct UserProfile: Identifiable {
    let id: String
    let email: String
    let name: String
    let userType: String
    let createdAt: Date
    
    init?(from data: [String: Any]) {
        guard let uid = data["uid"] as? String,
              let email = data["email"] as? String,
              let name = data["name"] as? String,
              let userType = data["userType"] as? String,
              let timestamp = data["createdAt"] as? Timestamp else {
            return nil
        }
        
        self.id = uid
        self.email = email
        self.name = name
        self.userType = userType
        self.createdAt = timestamp.dateValue()
    }
}
