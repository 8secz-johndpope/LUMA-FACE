//
//  AR.swift
//  Luma Face
//
//  Created by Hexagons on 2018-11-24.
//  Copyright © 2018 Hexagons. All rights reserved.
//

import ARKit
import PixelKit

protocol ARMirror {
    func activityUpdated(_ active: Bool)
    func didUpdate(arFrame: ARFrame)
    func didAdd()
    func didUpdate(geo: ARFaceGeometry)
    func didRemove()
}

class AR: NSObject, ARSessionDelegate, ARSCNViewDelegate, ContentDelegate {
    
    var mirrors: [ARMirror] = []
    
    static var isSupported: Bool {
        return ARFaceTrackingConfiguration.isSupported
    }
    
    let view: UIView
    
    let session: ARSession
    let scnView: ARSCNView
    
    var lowFps: Bool = false
    
    var node: SCNNode?
    
    var wireframe: Bool = false
    
    var lastUpdate: Date?
    var lastActive: Bool {
        guard let date = lastUpdate else { return false }
        let time = -date.timeIntervalSinceNow
        return time < 0.1
    }
    var isActive: Bool = false
    
    var image: UIImage?
    var pix: PIX?
    var content: Bool = true
    
    var bgSphere: SCNSphere!
    var bgNode: SCNNode!
    
//    var image: UIImage?
    
//    var faceAnchor: ARFaceAnchor?
//    let scnFaceGeometry: ARSCNFaceGeometry
//    let faceNode: SCNNode

    let maskSceneView: SCNView
    let maskScene: SCNScene

    var maskNode: SCNNode?

    var cam: SCNCamera?
    var camNode: SCNNode?
    var camSubNode: SCNNode?
    
    var freeze: Bool = false
        
    init(frame: CGRect) {
        
        view = UIView(frame: frame)
        
        session = ARSession()
        
        scnView = ARSCNView(frame: view.bounds)
        
        maskSceneView = SCNView()
        maskScene = SCNScene()
        
//        let device: MTLDevice = scnView.device!
//        scnFaceGeometry = ARSCNFaceGeometry(device: device)!
//        faceNode = SCNNode()
        
        
        super.init()
        
        
        session.delegate = self
        
        scnView.session = session
        scnView.delegate = self
        view.addSubview(scnView)
        
        wireframeOn()
        
//        scnFaceGeometry.firstMaterial!.fillMode = .lines
//        faceNode.geometry = scnFaceGeometry
        
//        mirror?.didSetup(cam: scnView.scene.rootNode.camera!)
        
        bgSphere = SCNSphere(radius: 10)
        bgSphere.firstMaterial!.isDoubleSided = true
        bgSphere.firstMaterial!.diffuse.contents = UIColor.black
        bgNode = SCNNode(geometry: bgSphere)
        scnView.scene.rootNode.addChildNode(bgNode)
        
        
        maskSceneView.scene = maskScene
        
        maskScene.background.contents = UIColor.black
        
        cam = SCNCamera()
        cam!.fieldOfView = 68
        cam!.zFar = 10
        cam!.zNear = 0.01
        camNode = SCNNode()
        camSubNode = SCNNode()
        camSubNode?.eulerAngles = SCNVector3(0, 0, CGFloat.pi / 2)
        camSubNode!.camera = cam
        camNode!.addChildNode(camSubNode!)
        maskScene.rootNode.addChildNode(camNode!)
        
    }
    
    func run() {
        let config = ARFaceTrackingConfiguration()
        if lowFps {
            if #available(iOS 11.3, *) {
                config.videoFormat = ARFaceTrackingConfiguration.supportedVideoFormats.last!
            }
        }
        config.isLightEstimationEnabled = false
        let options: ARSession.RunOptions = [
            .resetTracking,
            .removeExistingAnchors
        ]
        session.run(config, options: options)
    }
    
    func pause() {
        session.pause()
    }
    
//    func add(content: Any) {
//        guard node != nil else { return }
//        node!.geometry!.firstMaterial!.fillMode = .fill
//        node!.geometry!.firstMaterial!.diffuse.contents = content
//        self.image = nil
//        self.pix = nil
//    }
    
    func new(texture: MTLTexture) {
        guard !wireframe else { return }
        maskNode?.geometry!.firstMaterial!.fillMode = .fill
        maskNode?.geometry!.firstMaterial!.diffuse.contents = texture
        node?.geometry!.firstMaterial!.fillMode = .fill
        node?.geometry!.firstMaterial!.diffuse.contents = texture
    }
    func new(image: UIImage) {
        guard !wireframe else { return }
        maskNode?.geometry!.firstMaterial!.fillMode = .fill
        maskNode?.geometry!.firstMaterial!.diffuse.contents = image
        node?.geometry!.firstMaterial!.fillMode = .fill
        node?.geometry!.firstMaterial!.diffuse.contents = image
    }
    
    func wireframeOn() {
        node?.geometry!.firstMaterial!.fillMode = .lines
        node?.geometry!.firstMaterial!.diffuse.contents = nil
        maskNode?.geometry!.firstMaterial!.fillMode = .lines
        maskNode?.geometry!.firstMaterial!.diffuse.contents = nil
        wireframe = true
    }
    
    func wireframeOff() {
        wireframe = false
    }
    
//    func addImage(_ image: UIImage) {
//        guard node != nil else { return }
//        node!.geometry!.firstMaterial!.fillMode = .fill
//        node!.geometry!.firstMaterial!.diffuse.contents = image
//        self.image = image
//        self.pix = nil
//    }
    
//    func addPIXA() {
//        guard node != nil else { return }
//        node!.geometry!.firstMaterial!.fillMode = .fill
//        let noisePix = NoisePIX(res: ._1024)
//        noisePix.zPosition = .live / 10
//        self.pix = noisePix !** 0.25
//        self.image = nil
//    }
    
//    func addPIXB() {
//        guard node != nil else { return }
//        node!.geometry!.firstMaterial!.fillMode = .fill
//        let noisePix = NoisePIX(res: ._1024)
//        noisePix.octaves = 3
//        noisePix.zPosition = .live / 10
//        self.pix = noisePix._quantize(0.05)._edge()
//        self.image = nil
//    }
    
//    func removeImage() {
//        guard node != nil else { return }
//        node!.geometry!.firstMaterial!.fillMode = .lines
//        node!.geometry!.firstMaterial!.diffuse.contents = nil
//        self.image = nil
//        self.pix = nil
//    }
    
    // MARK: ARSessionDelegate
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
//        print("AR SE FRAME")
        if isActive != lastActive {
            isActive = lastActive
//            print("AR ACTIVE", isActive)
            mirrors.forEach { mirror in
                mirror.activityUpdated(isActive)
            }
        }
        mirrors.forEach { mirror in
            mirror.didUpdate(arFrame: frame)
        }
        if let pix = self.pix {
            node!.geometry!.firstMaterial!.diffuse.contents = pix.renderedTexture
        }
        if !freeze {
            DispatchQueue.main.async {
                self.camNode?.transform = SCNMatrix4(frame.camera.transform)
//                self.cam?.projectionTransform = SCNMatrix4(frame.camera.projectionMatrix)
            }
        }
    }
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
//        print("AR SE ADD", anchors.count)
        mirrors.forEach { mirror in
            mirror.didAdd()
        }
////        guard faceAnchor == nil else { print("FACE too late.."); return }
////        faceAnchor = anchors.first! as? ARFaceAnchor
////        guard faceAnchor != nil else { print("FaceAnchor not valid.."); return }
////        scnFaceGeometry.update(from: faceAnchor!.geometry)
//        scnView.scene.rootNode.addChildNode(faceNode)
    }

    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
//        print("AR SE NEW", anchors.count)
        guard let faceAnchor = anchors.first! as? ARFaceAnchor else {
            print("Non face anchor.")
            return
        }
        mirrors.forEach { mirror in
            mirror.didUpdate(geo: faceAnchor.geometry)
        }
        
        lastUpdate = Date()
        
//        guard let faceAnchor = anchors.first! as? ARFaceAnchor else { return }
//        scnFaceGeometry.update(from: faceAnchor.geometry)
    }
    
    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
//        print("AR SE RM", anchors.count)
        mirrors.forEach { mirror in
            mirror.didRemove()
        }
    }
    
    // MARK: ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer,
                  nodeFor anchor: ARAnchor) -> SCNNode? {
//        print("AR SCN NODE")
        
        guard let device = scnView.device else {
            print("AR Error: Device not found.")
            return nil
        }
        
        let faceGeometry = ARSCNFaceGeometry(device: device)
        node = SCNNode(geometry: faceGeometry)
        
        let nodeFaceGeometry = ARSCNFaceGeometry(device: device)
        maskNode = SCNNode(geometry: nodeFaceGeometry)
        maskScene.rootNode.addChildNode(maskNode!)
        
        if wireframe {
            wireframeOn()
        }
        
//        if pix != nil {
//            addPIXA()
//        } else if let image = self.image {
//            addImage(image)
//        } else {
//            removeImage()
//        }
        
        return node
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
//        print("AR SCN DID ADD")
//        mirror?.didAdd()
    }
    
    func renderer(_ renderer: SCNSceneRenderer, willUpdate node: SCNNode, for anchor: ARAnchor) {
//        print("AR SCN WILL NEW")
    }
    
    func renderer(_ renderer: SCNSceneRenderer,
                  didUpdate node: SCNNode,
                  for anchor: ARAnchor) {
//        print("AR SCN DID NEW")
        
        guard let faceAnchor = anchor as? ARFaceAnchor,
              let faceGeometry = node.geometry as? ARSCNFaceGeometry else {
                print("Non face anchor.")
                return
        }
        
        
        if !freeze {
            DispatchQueue.main.async {
                self.maskNode!.transform = SCNMatrix4(anchor.transform)
                (self.maskNode!.geometry as! ARSCNFaceGeometry).update(from: faceAnchor.geometry)
            }
        }

        
        let geo = faceAnchor.geometry
        faceGeometry.update(from: geo)
//        DispatchQueue(label: "AR").async {
//        DispatchQueue.global(qos: .background).async {
//            self.mirror?.didUpdate(geo: geo)
//        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer,
                  didRemove node: SCNNode,
                  for anchor: ARAnchor) {
//        print("AR SCN DID RM")
        self.node = nil
//        mirror?.didRemove()
    }
    
    func moveMask(to point: CGPoint) {
        camSubNode?.position = SCNVector3(-point.y / 1000, -point.x / 1000, 0)
    }
    
    func scaleMask(to scale: CGFloat) {
        cam?.fieldOfView = 68 / scale
    }
    
}
