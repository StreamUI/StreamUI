//
//  File.swift
//
//
//  Created by Jordan Howlett on 6/26/24.
//

import Foundation
import SceneKit
import SwiftUI

protocol SceneKitContentProvider {
    func setupScene(in view: SCNView)
}

class SceneKitRenderer: ObservableObject {
    let scnView: SCNView
    @Published var snapshotImage: NSImage?
    @Published var frameCount: Int = 0
    
    init(size: CGSize, contentProvider: SceneKitContentProvider) {
        self.scnView = SCNView(frame: CGRect(origin: .zero, size: size))
        contentProvider.setupScene(in: self.scnView)
    }
    
    func updateSnapshot() {
        self.snapshotImage = self.scnView.snapshot()
        print("snapper", self.snapshotImage)
        self.frameCount += 1
    }
}

struct SceneKitSnapshotView: View {
    @StateObject private var renderer: SceneKitRenderer
    @State private var timer: Timer?
    
    init<Content: SceneKitContentProvider>(size: CGSize = CGSize(width: 300, height: 400), frameRate: Double = 30, content: Content) {
        _renderer = StateObject(wrappedValue: SceneKitRenderer(size: size, contentProvider: content))
//        self.timer = Timer.publish(every: 1.0 / frameRate, on: .main, in: .common)
    }
    
    var body: some View {
        VStack {
            if let image = renderer.snapshotImage {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Color.blue
            }
            Text("Frame: \(renderer.frameCount)")
        }
        .onAppear {
            timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { _ in
                print("Timer fired")
                renderer.updateSnapshot()
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
}

struct ChildSceneKitView: SceneKitContentProvider {
    func setupScene(in view: SCNView) {
        let scene = SCNScene()
        
        // Set up camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 5)
        scene.rootNode.addChildNode(cameraNode)
        
        // Add ball
        let ball = SCNSphere(radius: 0.3)
        ball.firstMaterial?.diffuse.contents = NSColor.red
        let ballNode = SCNNode(geometry: ball)
        ballNode.position = SCNVector3(x: 0, y: 0, z: 0)
        scene.rootNode.addChildNode(ballNode)
        
        // Animate the ball
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 2.0
        animation.fromValue = SCNVector3(x: -2, y: 0, z: 0)
        animation.toValue = SCNVector3(x: 2, y: 0, z: 0)
        animation.autoreverses = true
        animation.repeatCount = .greatestFiniteMagnitude
        ballNode.addAnimation(animation, forKey: "position")
        
        view.scene = scene
        view.allowsCameraControl = true
        view.autoenablesDefaultLighting = true
        view.backgroundColor = .black
    }
}

// struct SceneKitSnapshotView<Content: View>: View {
//    @State private var snapshotImage: NSImage? = nil
//    @State private var frameCount: Int = 0
//
//    private let content: () -> Content
//    private let frameRate: TimeInterval
//    private let sceneSize: CGSize
//    private let scnView: SCNView
//
//    init(
//        frameRate: TimeInterval = 1.0 / 30.0,
//        sceneSize: CGSize = CGSize(width: 300, height: 400),
//        @ViewBuilder content: @escaping () -> Content
//    ) {
//        self.frameRate = frameRate
//        self.sceneSize = sceneSize
//        self.content = content
//        self.scnView = SCNView(frame: CGRect(origin: .zero, size: sceneSize))
//    }
//
//    var body: some View {
//        VStack {
//            if let snapshotImage = snapshotImage {
//                Image(nsImage: snapshotImage)
//                    .resizable()
//                    .frame(width: sceneSize.width, height: sceneSize.height)
//            } else {
//                Color.blue
//                    .frame(width: sceneSize.width, height: sceneSize.height)
//            }
//            Text("Frame: \(frameCount)")
//        }
//        .onAppear(perform: startRendering)
//        .background(
//            SceneKitViewRepresentable(content: content, scnView: scnView)
//                .frame(width: 0, height: 0)
//        )
//    }
//
//    private func startRendering() {
//        Timer.scheduledTimer(withTimeInterval: self.frameRate, repeats: true) { _ in
//            DispatchQueue.main.async {
//                self.takeSnapshot()
//                self.frameCount += 1
//            }
//        }
//    }
//
//    private func takeSnapshot() {
//        if self.scnView.frame.size != self.sceneSize {
//            self.scnView.frame.size = self.sceneSize
//        }
//        let snapshot = self.scnView.snapshot()
//        self.snapshotImage = snapshot
//    }
// }
//
// struct SceneKitViewRepresentable<Content: View>: NSViewRepresentable {
//    let content: () -> Content
//    let scnView: SCNView
//
//    func makeNSView(context: Context) -> SCNView {
//        return self.scnView
//    }
//
//    func updateNSView(_ nsView: SCNView, context: Context) {
//        let hostingController = NSHostingController(rootView: content())
//        if let scnScene = hostingController.view.subviews.first as? SCNView {
//            nsView.scene = scnScene.scene
//            nsView.allowsCameraControl = scnScene.allowsCameraControl
//            nsView.autoenablesDefaultLighting = scnScene.autoenablesDefaultLighting
//            nsView.backgroundColor = scnScene.backgroundColor
//        }
//    }
// }

// struct SKSnapshotView: View {
//    @State private var snapshotImage: NSImage? = nil
//    @State private var scene: SCNScene
//    @State private var frameCount: Int = 0
//
//    private let frameRate: TimeInterval = 1.0 / 30.0 // 30 FPS
//    private let sceneSize = CGSize(width: 300, height: 400)
//    private let scnView: SCNView
//
//    init() {
//        self.scene = SCNScene()
//        self.scnView = SCNView(frame: CGRect(origin: .zero, size: sceneSize))
//
//        scnView.scene = scene
//        scnView.allowsCameraControl = true
//        scnView.autoenablesDefaultLighting = true
//        scnView.backgroundColor = .white
//
//        // Set up camera
//        let cameraNode = SCNNode()
//        cameraNode.camera = SCNCamera()
//        cameraNode.position = SCNVector3(x: 0, y: 0, z: 5)
//        scene.rootNode.addChildNode(cameraNode)
//
//        // Add ball
//        let ball = SCNSphere(radius: 0.3)
//        ball.firstMaterial?.diffuse.contents = NSColor.red
//        let ballNode = SCNNode(geometry: ball)
//        ballNode.position = SCNVector3(x: 0, y: 0, z: 0)
//        scene.rootNode.addChildNode(ballNode)
//
//        // Add physics body to the scene
//        scene.physicsWorld.gravity = SCNVector3(x: 0, y: -9.8, z: 0)
//        let floorNode = SCNNode()
//        floorNode.geometry = SCNFloor()
//        floorNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
//        scene.rootNode.addChildNode(floorNode)
//    }
//
//    var body: some View {
//        VStack {
//            if let snapshotImage = snapshotImage {
//                Image(nsImage: snapshotImage)
//                    .resizable()
//                    .frame(width: sceneSize.width, height: sceneSize.height)
//            } else {
//                Color.blue
//                    .frame(width: sceneSize.width, height: sceneSize.height)
//            }
//            Text("Frame: \(frameCount)")
//        }
//        .onAppear(perform: startRendering)
//    }
//
//    private func startRendering() {
//        Timer.scheduledTimer(withTimeInterval: frameRate, repeats: true) { _ in
//            DispatchQueue.main.async {
//                self.updateScene()
//                self.takeSnapshot()
//                self.frameCount += 1
//            }
//        }
//    }
//
//    private func updateScene() {
//        guard let ballNode = scene.rootNode.childNodes.first(where: { $0.geometry is SCNSphere }) else { return }
//
//        let x = sin(Double(frameCount) / 30.0) * 2.0
//        let y = cos(Double(frameCount) / 30.0) * 2.0
//
//        SCNTransaction.begin()
//        SCNTransaction.animationDuration = frameRate
//        ballNode.position = SCNVector3(x: CGFloat(Float(x)), y: CGFloat(Float(y)), z: 0)
//        SCNTransaction.commit()
//    }

//    private func takeSnapshot() {
//        if scnView.frame.size != sceneSize {
//            scnView.frame.size = sceneSize
//        }
//        let snapshot = scnView.snapshot()
//        snapshotImage = snapshot
//    }
// }

// struct ChildSceneKitView: View {
//    let scene: SCNScene
//
//    init() {
//        self.scene = SCNScene()
//
//        // Set up camera
//        let cameraNode = SCNNode()
//        cameraNode.camera = SCNCamera()
//        cameraNode.position = SCNVector3(x: 0, y: 0, z: 5)
//        self.scene.rootNode.addChildNode(cameraNode)
//
//        // Add ball
//        let ball = SCNSphere(radius: 0.3)
//        ball.firstMaterial?.diffuse.contents = NSColor.red
//        let ballNode = SCNNode(geometry: ball)
//        ballNode.position = SCNVector3(x: 0, y: 0, z: 0)
//        self.scene.rootNode.addChildNode(ballNode)
//
//        // Animate the ball
//        let animation = CABasicAnimation(keyPath: "position")
//        animation.duration = 2.0
//        animation.fromValue = SCNVector3(x: -2, y: 0, z: 0)
//        animation.toValue = SCNVector3(x: 2, y: 0, z: 0)
//        animation.autoreverses = true
//        animation.repeatCount = .greatestFiniteMagnitude
//        ballNode.addAnimation(animation, forKey: "position")
//    }
//
//    var body: some View {
//        SceneView(scene: scene, options: [.allowsCameraControl, .autoenablesDefaultLighting])
//    }
// }

public struct SceneKitTestView: View {
    @Environment(\.recorder) private var recorder
    @State private var scene: SCNScene?
    
    public init() {}
    
    public var body: some View {
        VStack {
//            SceneView(scene: scene, options: [.allowsCameraControl, .autoenablesDefaultLighting])
//                .frame(width: 300, height: 400)
//                .background(Color.gray)
//                .onAppear {
//                    setupScene()
//                }
            
//            SceneKitSnapshotView {
//                ChildSceneKitView()
//            }
            SceneKitSnapshotView(content: ChildSceneKitView())
                .frame(width: 300, height: 400)
                .background(Color.gray)
            
            Text("Frame: \(recorder?.frameTimer.frameCount ?? 0)")
        }
        .onChange(of: recorder?.frameTimer.frameCount) { _ in
            updateBallPosition()
        }
    }
    
    private func setupScene() {
        self.scene = SCNScene()
        
        let ball = SCNSphere(radius: 0.5)
        ball.firstMaterial?.diffuse.contents = NSColor.red
        
        let ballNode = SCNNode(geometry: ball)
        ballNode.name = "ball"
        self.scene?.rootNode.addChildNode(ballNode)
        
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 5)
        self.scene?.rootNode.addChildNode(cameraNode)
    }
    
    private func updateBallPosition() {
        guard let frameCount = recorder?.frameTimer.frameCount,
              let ballNode = scene?.rootNode.childNode(withName: "ball", recursively: true)
        else {
            return
        }
        
        let x = sin(Double(frameCount) / 30.0) * 2.0
        let y = cos(Double(frameCount) / 30.0) * 2.0
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 1.0 / 60.0 // Smooth animation at 60 FPS
        ballNode.position = SCNVector3(x: CGFloat(Float(x)), y: CGFloat(Float(y)), z: 0)
        SCNTransaction.commit()
    }
}
