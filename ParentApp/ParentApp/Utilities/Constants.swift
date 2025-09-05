//
//  Constants.swift
//  SitterApp
//
//  Created by Ibrahim Mo Gedami on 26/08/2025.
//

import Foundation

class Constants {
    
    static let channelName = "testingChannel"
    static let token = "007eJxTYJhjPEctos57Y19n5dRvbmfU9gc8rb77KmD59b+LXFYsKJuqwGCclmRmmmyckmxqaGZibJFqkZJiamxmZGZiaJKWbJSWlDFjV0ZDICPD0ogqBkYoBPH5GEpSi0sy89KdMxLz8lJzGBgAbtol/A=="
    static let appId = "3fb65c3dc516438e8dd53626414fc2fb"
    static let callTimeout = 30.0
    
    struct Collections {
        static let users = "users"
        static let calls = "calls"
    }
    
    struct Fields {
        // User fields
        static let uid = "uid"
        static let email = "email"
        static let name = "name"
        static let userType = "userType"
        static let createdAt = "createdAt"
        
        // Call fields
        static let callerId = "callerId"
        static let receiverId = "receiverId"
        static let channelName = "channelName"
        static let status = "status"
        static let updatedAt = "updatedAt"
        static let callType = "callType"
        static let timeoutAt = "timeoutAt"
    }
    
}
