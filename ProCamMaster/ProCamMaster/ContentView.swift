//
//  ContentView.swift
//  ProCam Master
//
//  应用主视图
//  Created by Claude
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        CameraView()
            .ignoresSafeArea()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
