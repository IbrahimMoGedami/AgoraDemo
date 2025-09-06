//
//  CallStatus.swift
//  ParentApp
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
    
    var firestoreValue: String {
        switch self {
        case .inProgress: return "inProgress"
        default: return self.rawValue
        }
    }
    
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
    let status: CallStatus
    let createdAt: Date
    var callType: CallType
    let timeoutAt: Date?
    
    init?(from data: [String: Any], id: String) {
        guard let callerId = data[Constants.Fields.callerId] as? String,
              let receiverId = data[Constants.Fields.receiverId] as? String,
              let channelName = data[Constants.Fields.channelName] as? String,
              let statusString = data[Constants.Fields.status] as? String,
              let status = CallStatus(rawValue: statusString),
              let timestamp = data[Constants.Fields.createdAt] as? Timestamp,
              let callTypeString = data[Constants.Fields.callType] as? String,
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
        self.timeoutAt = (data[Constants.Fields.timeoutAt] as? Timestamp)?.dateValue()
    }

}

struct UserProfile: Identifiable {
    
    let id: String
    let email: String
    let name: String
    let userType: String
    let createdAt: Date
    
    init?(from data: [String: Any]) {
        guard let uid = data[Constants.Fields.uid] as? String,
              let email = data[Constants.Fields.email] as? String,
              let name = data[Constants.Fields.name] as? String,
              let userTypeString = data[Constants.Fields.userType] as? String,
              let userType = UserType(rawValue: userTypeString),
              let timestamp = data[Constants.Fields.createdAt] as? Timestamp else {
            return nil
        }
        
        self.id = uid
        self.email = email
        self.name = name
        self.userType = userType.rawValue
        self.createdAt = timestamp.dateValue()
    }

}
