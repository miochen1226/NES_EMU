//
//  ContentView.swift
//  NesWatch Watch App
//
//  Created by miochen on 2026/2/12.
//

import SwiftUI
internal import Combine

struct ContentView: View {
    var body: some View {
        GameView(scene: scene)
            .frame(width: nil, height: nil,alignment: .top)
            .overlay(
                GeometryReader { geometry in
                    Color.clear
                    .onAppear {
                        scene.handleSizeChange(geometry.size)
                    }
                    .onChange(of: geometry.size, { oldValue, newValue in
                        scene.handleSizeChange(geometry.size)
                    })
                }
            )
//            .overlay(
//                VStack {
//                    HStack {
//                        //Spacer()
//                        Text(labenFps)
//                            .onReceive(timer) { _ in
//                                updateFps()
//                            }
//                        Spacer()
//                    }
//                    Spacer()
//                }
//                .foregroundStyle(.white)
//                .padding()
//            )
    }
    private func updateFps() {
        let fpsInfo = scene.getFpsInfo()
        labenFps = fpsInfo
    }
    
    @State var labenFps = "FPS"
    @State var scene = GameScene()
    @State var timer = Timer.publish (every: 1, on: .current, in: .common).autoconnect()
}

#Preview {
    ContentView()
}
