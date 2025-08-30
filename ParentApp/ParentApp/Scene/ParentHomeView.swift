//
//  ParentHomeView.swift
//  ParentApp
//
//  Created by Ibrahim Mo Gedami on 25/08/2025.
//

import SwiftUI

struct ParentHomeView: View {
    
    @EnvironmentObject var authService: FirebaseService
    @EnvironmentObject var agoraService: AgoraService
    @State private var showCallView = false
    
    var body: some View {
        Group {
            if authService.isAuthenticated {
                if agoraService.isInCall {
                    CallView()
                } else {
                    ParentMainView(showCallView: $showCallView)
                }
            } else {
                LoginView()
            }
        }
    }
    
}
