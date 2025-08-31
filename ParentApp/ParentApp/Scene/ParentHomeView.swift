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
     @State private var activeCall: Call?
     
     var body: some View {
         Group {
             if authService.isAuthenticated {
                 if agoraService.isInCall, let call = agoraService.currentCall {
                     CallView(call: call)
                 } else {
                     ParentMainView(showCallView: $showCallView, activeCall: $activeCall)
                 }
             } else {
                 LoginView()
             }
         }
         .onChange(of: agoraService.isInCall) { _, isInCall in
             if isInCall {
                 showCallView = true
             }
         }
     }
    
}
