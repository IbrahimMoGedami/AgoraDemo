//
//  SitterHomeView.swift
//  SitterApp
//
//  Created by Ibrahim Mo Gedami on 25/08/2025.
//

import SwiftUI

struct SitterHomeView: View {
    
    @EnvironmentObject var authService: FirebaseService
    @EnvironmentObject var agoraService: AgoraService
    @State private var showCallView = false
    
    var body: some View {
        Group {
            if authService.isAuthenticated {
                if agoraService.isInCall {
                    CallView()
                } else {
                    SitterMainView(showCallView: $showCallView)
                }
            } else {
                SitterLoginView()
            }
        }
    }
    
}
