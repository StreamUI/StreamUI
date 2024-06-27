//
//  File.swift
//
//
//  Created by Jordan Howlett on 6/20/24.
//

import AVFoundation
import Foundation
import SceneKit
import SpriteKit
import SwiftUI

class Ball: SCNNode {
    let id: String
    let radius: CGFloat

    init(radius: CGFloat, pos: SCNVector3, id: String) {
        self.id = id
        self.radius = radius
        super.init()

        let sphereGeometry = SCNSphere(radius: radius)
        let material = SCNMaterial()
        material.diffuse.contents = NSImage(named: "Ball")
        sphereGeometry.materials = [material]

        self.geometry = sphereGeometry
        self.position = pos

        let body = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(geometry: sphereGeometry, options: nil))
        body.restitution = 0.6
        body.allowsResting = false
        self.physicsBody = body
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func animateSizeAndColor() {
        let scaleUp = SCNAction.scale(to: 1.5, duration: 1)
        let scaleDown = SCNAction.scale(to: 1.0, duration: 1)
        let scaleSequence = SCNAction.sequence([scaleUp, scaleDown])

        let blueColor = SCNAction.customAction(duration: 1) { node, elapsedTime in
            let material = node.geometry?.firstMaterial
            material?.diffuse.contents = NSColor(red: 0, green: 0, blue: elapsedTime, alpha: 1)
        }
        let redColor = SCNAction.customAction(duration: 1) { node, elapsedTime in
            let material = node.geometry?.firstMaterial
            material?.diffuse.contents = NSColor(red: elapsedTime, green: 0, blue: 1 - elapsedTime, alpha: 1)
        }
        let colorSequence = SCNAction.sequence([blueColor, redColor])

        let group = SCNAction.group([scaleSequence, colorSequence])
        let repeatForever = SCNAction.repeatForever(group)

        runAction(repeatForever)
    }
}

// struct SceneKitSnapshotView: View {
//    @State private var snapshotImage: NSImage? = nil
//    private let frameRate: TimeInterval = 1.0 / 30.0 // 30 FPS
//    private let sceneSize = CGSize(width: 300, height: 400)
//    private let scene: SCNScene
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
//        let ball = Ball(radius: 0.3, pos: SCNVector3(x: 0, y: 0, z: 0), id: UUID().uuidString)
//        scene.rootNode.addChildNode(ball)
//        ball.animateSizeAndColor()
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
//        }
//        .onAppear(perform: startRendering)
//    }
//
//    private func startRendering() {
//        Timer.scheduledTimer(withTimeInterval: frameRate, repeats: true) { _ in
//            DispatchQueue.main.async {
//                print("[SceneKit] starting")
//                if self.scnView.frame.size != self.sceneSize {
//                    self.scnView.frame.size = self.sceneSize
//                }
//                let snapshot = self.scnView.snapshot()
//                self.snapshotImage = snapshot
//                print("[SceneKit] snapshot taken")
//            }
//        }
//    }
// }

// struct SpriteKitSnapshotView: View {
//    @State private var snapshotImage: NSImage? = nil
//    private let frameRate: TimeInterval = 1.0 / 30.0 // 30 FPS
//    private let sceneSize = CGSize(width: 300, height: 400)
//    private let scene: SKScene
//    private let skView = SKView(frame: .zero)
//
//    init() {
//        let scene = BallScene(size: sceneSize)
//        scene.scaleMode = .resizeFill
//        self.scene = scene
//        skView.presentScene(scene)
//    }
//
//    var body: some View {
//        VStack {
//            if let snapshotImage = snapshotImage {
//                Image(nsImage: snapshotImage)
//                    .resizable()
//                    .frame(width: sceneSize.width, height: sceneSize.height)
//                    .background(Color.gray)
//            } else {
//                Color.blue
//                    .frame(width: sceneSize.width, height: sceneSize.height)
//            }
//        }
//        .onAppear(perform: startRendering)
//    }
//
//    private func startRendering() {
//        Timer.scheduledTimer(withTimeInterval: frameRate, repeats: true) { _ in
//            DispatchQueue.main.async {
//                print("[SceneKit] starting")
//                if let texture = skView.texture(from: skView.scene!) {
//                    print("[SceneKit] text", texture)
//                    let cgImage = texture.cgImage()
//                    let nsImage = NSImage(cgImage: cgImage, size: sceneSize)
//                    self.snapshotImage = nsImage
//                }
//            }
//        }
//    }
// }

// class Ball: SKNode {
//    let id: String
//    private let img = SKSpriteNode(imageNamed: "Ball")
//    let radius: CGFloat
//
//    init(radius: CGFloat, pos: CGPoint, id: String) {
//        self.id = id
//        self.radius = radius
//        super.init()
//        self.position = pos
//
//        let body = SKPhysicsBody(circleOfRadius: radius)
//        body.isDynamic = true
//        body.restitution = 0.6
//        body.allowsRotation = false
//        body.usesPreciseCollisionDetection = true
//        body.contactTestBitMask = 1
//        self.physicsBody = body
//
//        img.size = CGSize(width: radius * 2, height: radius * 2)
//        addChild(img)
//    }
//
//    @available(*, unavailable)
//    required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    func animateSizeAndColor() {
//        let resizeAction = SKAction.sequence([
//            SKAction.scale(to: 1.5, duration: 1),
//            SKAction.scale(to: 1.0, duration: 1)
//        ])
//        let colorizeAction = SKAction.sequence([
//            SKAction.colorize(with: .blue, colorBlendFactor: 1.0, duration: 1),
//            SKAction.colorize(with: .red, colorBlendFactor: 1.0, duration: 1)
//        ])
//        let group = SKAction.group([resizeAction, colorizeAction])
//        let repeatAction = SKAction.repeatForever(group)
//        img.run(repeatAction)
//    }
// }
//
// class BallScene: SKScene {
//    override func didMove(to view: SKView) {
//        backgroundColor = .white
//        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
//
//        let ball = Ball(radius: 30, pos: CGPoint(x: frame.midX, y: frame.midY), id: UUID().uuidString)
//        addChild(ball)
//        ball.animateSizeAndColor()
//    }
// }

public struct SpriteKitTestView: View {
    @Environment(\.recorder) private var recorder

    @State private var counter: Int = 0
    @State private var timer: Timer?
    @State private var circleSize: CGFloat = 100
    @State private var circleColor: Color = .red

    public init() {}

    var newFrameCount: Int {
        print("recorder count", recorder?.frameTimer.frameCount)
        return 10
    }

    public var body: some View {
        VStack {
//            SpriteView(scene: BallScene(size: CGSize(width: 300, height: 400)))
//                .frame(width: 300, height: 400)
//                .edgesIgnoringSafeArea(.all)

//            SpriteKitView()
//                .frame(width: 300, height: 400)
//                .background(Color.gray)

//            SceneKitSnapshotView()
//                .frame(width: 300, height: 400)
//                .background(Color.gray)

//            SpriteKitSceneWrapper {
//                SpriteView(scene: BallScene(size: CGSize(width: 300, height: 400)))
//                    .frame(width: 300, height: 400)
//                    .edgesIgnoringSafeArea(.all)
//            }

            Text("\(newFrameCount)")

            Circle()
                .fill(circleColor)
                .frame(width: circleSize, height: circleSize)
                .onAppear {
                    startCircleAnimation()
                }
        }
        .onChange(of: recorder?.frameTimer.frameCount) { newCount in
            print("new frame count", recorder?.frameTimer.frameCount, newCount)
            updateCircleAnimation()
        }
    }

    private func scaleEffectBasedOnFrameCount() -> CGFloat {
        if let frameCount = recorder?.frameTimer.frameCount {
            return 1.0 + 0.5 * sin(Double(frameCount) / 10.0)
        }
        return 1.0
    }

    private func startCircleAnimation() {
        withAnimation(Animation.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
            circleSize = 150
            circleColor = .blue
        }
    }

    private func updateCircleAnimation() {
        if let frameCount = recorder?.frameTimer.frameCount {
            withAnimation(.linear(duration: 0.5)) {
                circleSize = 100 + CGFloat(frameCount % 50)
                circleColor = frameCount % 2 == 0 ? .red : .blue
            }
        }
    }
}
