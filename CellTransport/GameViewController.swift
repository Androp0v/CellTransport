//
//  GameViewController.swift
//  CellTransport
//
//  Created by Raúl Montón Pinillos on 04/02/2020.
//  Copyright © 2020 Raúl Montón Pinillos. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit
import Metal
import MetalKit

class GameViewController: UIViewController {
    
    var stepCounter: Int = 0
    
    // Simulation parameters
    
    let nbodies: Int = 524288 //4194304
    let nMicrotubules: Int = 400
    let cellRadius: Float = 14000 //nm
    let centrosomeLocation: SCNVector3 = SCNVector3(0.0,0.0,0.0)
    let nucleusLocation: SCNVector3 = SCNVector3(0.0,0.0,0.2)
    
    var microtubuleDistances: [Float] = []
    
    // UI outlets and variables
    @IBOutlet var scnView: SCNView!
    let scene = SCNScene(named: "art.scnassets/ship.scn")!
    @IBOutlet var segmentedControl: UISegmentedControl!
    @IBOutlet var containerView: UIView!
    @IBOutlet var buttonContainerView: UIView!
    @IBAction func changeSegment(_ sender: UISegmentedControl) {
        self.currentViewController!.view.removeFromSuperview()
        self.currentViewController!.removeFromParent()
        displayCurrentTab(sender.selectedSegmentIndex)
    }
    @IBOutlet var alertView: UIView!
    @IBOutlet var alertLabel: UILabel!
    @IBOutlet var freezeButton: UIButton!
    @IBOutlet var FrozenView: UIView!
    @IBAction func freeze(_ sender: Any) {
        if scene.isPaused == true{
            scene.isPaused = false
            freezeButton.setImage(UIImage(systemName: "snow"), for: .normal)
            FrozenView.alpha = 0.0
            DispatchQueue.main.async {
                self.alertLabel.text = ""
                self.alertView.backgroundColor = UIColor.clear
            }
        }else{
            scene.isPaused = true
            freezeButton.setImage(UIImage(named: "Defrost"), for: .normal)
            FrozenView.alpha = 1.0
            DispatchQueue.main.async {
                self.alertLabel.text = "Simulation running in the background"
                self.alertView.backgroundColor = UIColor.init(cgColor: CGColor(srgbRed: 0.5, green: 0.5, blue: 0.5, alpha: 0.5))
            }
        }
    }
    
    let rotationTime: TimeInterval = 40
    
    enum TabIndex : Int {
        case firstChildTab = 0
        case secondChildTab = 1
    }
    
    // Metal variables
    
    var device: MTLDevice!
    fileprivate var queue: MTLCommandQueue?
    fileprivate var library: MTLLibrary!
    fileprivate var computePipelineState: [MTLComputePipelineState?] = []
    fileprivate var positionsIn: [MTLBuffer?] = []
    fileprivate var positionsOut: [MTLBuffer?] = []
    fileprivate var distancesBuffer: [MTLBuffer?] = []
    fileprivate var timeLastJumpBuffer: [MTLBuffer?] = []
    fileprivate var updatedTimeLastJumpBuffer: [MTLBuffer?] = []
    fileprivate var timeBetweenJumpsBuffer: [MTLBuffer?] = []
    
    fileprivate var oldTimeBuffer: [MTLBuffer?] = []
    fileprivate var newTimeBuffer: [MTLBuffer?] = []
    
    fileprivate var buffer: MTLCommandBuffer?
    
    let nBuffers = 1
    var isRunning = false
    
    var currentViewController: UIViewController?
    lazy var firstChildTabVC: UIViewController? = {
        let firstChildTabVC = self.storyboard?.instantiateViewController(withIdentifier: "ParametersViewController")
        return firstChildTabVC
    }()
    lazy var secondChildTabVC : GraphsViewController? = {
        let secondChildTabVC = self.storyboard?.instantiateViewController(withIdentifier: "GraphsViewController")
        
        return (secondChildTabVC as! GraphsViewController)
    }()
    
    func viewControllerForSelectedSegmentIndex(_ index: Int) -> UIViewController? {
        var vc: UIViewController?
        switch index {
        case 0 :
            vc = firstChildTabVC
        case 1 :
            vc = secondChildTabVC
        default:
        return nil
        }
    
        return vc
    }
    
    func displayCurrentTab(_ tabIndex: Int){
        if let vc = viewControllerForSelectedSegmentIndex(tabIndex) {
            
            self.addChild(vc)
            vc.didMove(toParent: self)
            
            vc.view.frame = self.containerView.bounds
            self.containerView.addSubview(vc.view)
            self.currentViewController = vc
        }
    }
    
    func initComputePipelineState(_ device: MTLDevice) {
        
        let compute = (library.makeFunction(name: "compute"))!
        
        
        for _ in 0..<nBuffers{
            
            do {
                let computePipelineStatelocal = try device.makeComputePipelineState(function: compute)
                computePipelineState.append(computePipelineStatelocal)
            } catch {
                print("Failed to create compute pipeline state")
            }
        }
        
        /*
        do {
            if let compute = library.makeFunction(name: "compute") {
                computePipelineState = try device.makeComputePipelineState(function: compute)
            }
        } catch {
            print("Failed to create compute pipeline state")
        }
        */
        
    }
    
    func initializeMetal(){
        device = MTLCreateSystemDefaultDevice()
        queue = device.makeCommandQueue()
        library = device.makeDefaultLibrary()
        initComputePipelineState(device)
        
        distancesBuffer.append(device.makeBuffer(
            length: nbodies * MemoryLayout<Float>.stride
        ))
        
        let initializedTimeJump = [Float](repeating: 0.0, count: nbodies)
        let initializedUpdatedTimeJump = [Float](repeating: 0.0, count: nbodies)
        let initializedTimeBetweenJumps = [Float](repeating: -1.0, count: nbodies)
        
        timeLastJumpBuffer.append(device.makeBuffer(
            bytes: initializedTimeJump,
            length: nbodies * MemoryLayout<Float>.stride
        ))
        
        updatedTimeLastJumpBuffer.append(device.makeBuffer(
            bytes: initializedUpdatedTimeJump,
            length: nbodies * MemoryLayout<Float>.stride
        ))
        
        timeBetweenJumpsBuffer.append(device.makeBuffer(
            bytes: initializedTimeBetweenJumps,
            length: nbodies * MemoryLayout<Float>.stride
        ))
        
        let oldTime = [Float](repeating: 0.0, count: nbodies)
        
        oldTimeBuffer.append(device.makeBuffer(
            bytes: oldTime,
            length: nbodies * MemoryLayout<Float>.stride
        ))
        
        newTimeBuffer.append(device.makeBuffer(
            length: nbodies * MemoryLayout<Float>.stride
        ))
        
    }
    
    func spawnBoundingBox() -> SCNNode{
        
        var boundingBox:SCNGeometry

        boundingBox = SCNBox(width: CGFloat(2.0*cellRadius), height: CGFloat(2.0*cellRadius), length: CGFloat(2.0*cellRadius), chamferRadius: 0.0)
        boundingBox.firstMaterial?.fillMode = .lines
        boundingBox.firstMaterial?.isDoubleSided = true
        boundingBox.firstMaterial?.diffuse.contents = UIColor.white
        boundingBox.firstMaterial?.transparency = 0.02
        
        let boundingBoxNode = SCNNode(geometry: boundingBox)
        scene.rootNode.addChildNode(boundingBoxNode)
        
        return boundingBoxNode
    }
    
    func spawnMicrotubules() -> ([SCNNode],[SCNVector3]){
        
        var nodelist : [SCNNode] = []
        var microtubulePoints: [SCNVector3] = []
        
        for _ in 0...(nMicrotubules - 1){
            let points = generateMicrotubule(cellRadius: cellRadius, centrosomeLocation: centrosomeLocation)
            
            for point in points{
                microtubulePoints.append(point)
            }
            
            let microtubuleColor = UIColor.green.withAlphaComponent(0.0).cgColor

            let geometry = SCNGeometry.lineThrough(points: points,
                                                   width: 2,
                                                   closed: false,
                                                   color: microtubuleColor)
            let node = SCNNode(geometry: geometry)
            scene.rootNode.addChildNode(node)
            nodelist.append(node)
        }
        
        return (nodelist,microtubulePoints)
    }
    
    func spawnCellNucleus() -> SCNNode{
        var nucleus:SCNGeometry
        
        nucleus = SCNSphere(radius: 0.3)
        nucleus.firstMaterial?.diffuse.contents = UIColor.purple
        nucleus.firstMaterial?.diffuse.contents = UIImage(named: "cellmembrane.png")
        let nucleusNode = SCNNode(geometry: nucleus)
        
        let nucleusAxis = SCNNode()
        nucleusAxis.addChildNode(nucleusNode)
        
        scene.rootNode.addChildNode(nucleusAxis)
        
        nucleusAxis.position = SCNVector3(x: 0, y: 0, z: 0)
        nucleusNode.position = nucleusLocation
        
        return nucleusAxis
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // initialize Metal for GPU calculations
        initializeMetal()
                
        // create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 5*cellRadius, z: 5*cellRadius)
        scene.rootNode.addChildNode(lightNode)
        
        // create and add a camera to the scene
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.focalLength = 50.0
        cameraNode.camera?.zFar = 500000
        scene.rootNode.addChildNode(cameraNode)
        
        // place the camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 7*cellRadius)
        
        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = UIColor.darkGray
        scene.rootNode.addChildNode(ambientLightNode)
        
        // set the scene to the view
        scnView.scene = scene
        //scnView.delegate = self
        
        // allows the user to manipulate the camera
        scnView.allowsCameraControl = true
        
        // show statistics such as fps and timing information
        scnView.showsStatistics = true
        
        // configure the view
        scnView.backgroundColor = UIColor.black
        
        // add a tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        scnView.addGestureRecognizer(tapGesture)
        
        // finish UI configuration
        //nparticlesTextField.text = String(nbodies)
        buttonContainerView.layer.cornerRadius = 7.5
        alertView.layer.cornerRadius = 7.5
        alertView.backgroundColor = UIColor.clear
        
        segmentedControl.selectedSegmentIndex = TabIndex.firstChildTab.rawValue
        displayCurrentTab(TabIndex.firstChildTab.rawValue)
        
        // hacky hack to initialize lazy var safely on a main thread
        self.secondChildTabVC?.clearAllGraphs(Any.self)
        
        //Initialize the simulation
        DispatchQueue.global(qos: .default).async {
            self.initializeSimulation()
        }
    }
    
    func initializeSimulation(){
        // spawn the bounding box
        DispatchQueue.main.async {
            self.alertLabel.text = "Drawing bounding box"
            self.alertView.backgroundColor = UIColor.init(cgColor: CGColor(srgbRed: 0.5, green: 0.5, blue: 0.5, alpha: 0.5))
        }
        let boundingBox = spawnBoundingBox()
        
        // spawn the cell nucleus
        DispatchQueue.main.async {
            self.alertLabel.text = "Generating cellular nucleus"
        }
        //let nucleus = spawnCellNucleus()
        
        // spawn the microtubules
        DispatchQueue.main.async {
            self.alertLabel.text = "Generating microtubule structure"
        }
        let (microtubules, microtubulePoints) = spawnMicrotubules()
        
        //var microtubuleDistances: [Float] = []
        
        for microtubulePoint in microtubulePoints{
            microtubuleDistances.append(sqrt(microtubulePoint.x*microtubulePoint.x + microtubulePoint.y*microtubulePoint.y + microtubulePoint.z*microtubulePoint.z))
        }
        
        self.secondChildTabVC?.setHistogramData3(cellRadius: self.cellRadius, distances: microtubuleDistances)
        
        // spawn points
        DispatchQueue.main.async {
            self.alertLabel.text = "Initializing all particle positions"
        }
        var pointsNodeList: [SCNNode] = []
        
        for _ in 0..<nBuffers{
            let meshData = MetalMeshDeformable.initializePoints(device, nbodies: nbodies/nBuffers, cellRadius: cellRadius)
            positionsIn.append(meshData.vertexBuffer1)
            positionsOut.append(meshData.vertexBuffer2)
            
            let pointsNode = SCNNode(geometry: meshData.geometry)
            pointsNode.geometry?.firstMaterial?.diffuse.contents = UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
            pointsNode.geometry?.firstMaterial?.transparency = 0.4
            pointsNode.geometry?.firstMaterial?.lightingModel = .constant
            pointsNode.geometry?.firstMaterial?.writesToDepthBuffer = false
            pointsNode.geometry?.firstMaterial?.readsFromDepthBuffer = true
            //pointsNode.geometry?.firstMaterial?.blendMode = SCNBlendMode.add
                        
            pointsNodeList.append(pointsNode)
            
            scene.rootNode.addChildNode(pointsNode)
        }
        
        // animate the 3d object
        boundingBox.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 2, z: 0, duration: rotationTime)))
        for pointsNode in pointsNodeList{
            pointsNode.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 2, z: 0, duration: rotationTime)))
        }
        for microtubule in microtubules{
            microtubule.geometry?.firstMaterial?.lightingModel = .constant
            microtubule.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 2, z: 0, duration: rotationTime)))
        }
        //nucleus.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 2, z: 0, duration: rotationTime)))
        
        //Set renderer delegate to start animation loop
        DispatchQueue.main.async {
            self.alertLabel.text = ""
            self.alertView.backgroundColor = UIColor.clear
        }
        scnView.delegate = self
        
    }
    
    @objc
    func handleTap(_ gestureRecognize: UIGestureRecognizer) {
        // retrieve the SCNView
        
        // check what nodes are tapped
        let p = gestureRecognize.location(in: scnView)
        let hitResults = scnView.hitTest(p, options: [:])
        // check that we clicked on at least one object
        if hitResults.count > 0 {
            // retrieved the first clicked object
            let result = hitResults[0]
            
            // get its material
            let material = result.node.geometry!.firstMaterial!
            
            // highlight it
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.5
            
            // on completion - unhighlight
            SCNTransaction.completionBlock = {
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.5
                
                material.emission.contents = UIColor.black
                
                SCNTransaction.commit()
            }
            
            material.emission.contents = UIColor.red
            
            SCNTransaction.commit()
        }
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }
    
    func metalUpdaterChild(){
          
          // Update MTLBuffers thorugh compute pipeline
            
          buffer = queue?.makeCommandBuffer()
            
          // Compute kernel
          let threadsPerArray = MTLSizeMake(nbodies/nBuffers, 1, 1)
          let groupsize = MTLSizeMake(computePipelineState[0]!.maxTotalThreadsPerThreadgroup,1,1)
          
          let computeEncoder = buffer!.makeComputeCommandEncoder()
          
          for i in 0..<nBuffers{
              computeEncoder?.setComputePipelineState(computePipelineState[i]!)
              computeEncoder?.setBuffer(positionsIn[i], offset: 0, index: 0)
              computeEncoder?.setBuffer(positionsOut[i], offset: 0, index: 1)
              computeEncoder?.setBuffer(distancesBuffer[i], offset: 0, index: 2)
              computeEncoder?.setBuffer(timeLastJumpBuffer[i], offset: 0, index: 3)
              computeEncoder?.setBuffer(updatedTimeLastJumpBuffer[i], offset: 0, index: 4)
              computeEncoder?.setBuffer(timeBetweenJumpsBuffer[i], offset: 0, index: 5)
              computeEncoder?.setBuffer(oldTimeBuffer[i], offset: 0, index: 6)
              computeEncoder?.setBuffer(newTimeBuffer[i], offset: 0, index: 7)
              computeEncoder?.dispatchThreads(threadsPerArray, threadsPerThreadgroup: groupsize)
          }
          
          computeEncoder?.endEncoding()
          buffer!.commit()
          
          swap(&positionsIn, &positionsOut)
          swap(&timeLastJumpBuffer, &updatedTimeLastJumpBuffer)
          swap(&oldTimeBuffer, &newTimeBuffer)
          
          let distances = distancesBuffer[0]!.contents().assumingMemoryBound(to: Float.self)
          let timeJumps = timeBetweenJumpsBuffer[0]!.contents().assumingMemoryBound(to: Float.self)
              
          DispatchQueue.global(qos: .default).async {
            //TO-DO: This crashes window resizing and switch to full screen mode (switch to async)
            self.secondChildTabVC?.setHistogramData1(cellRadius: self.cellRadius, distances: distances)
            self.secondChildTabVC?.setHistogramData2(cellRadius: self.cellRadius, distances: timeJumps)
            self.secondChildTabVC?.setHistogramData3(cellRadius: self.cellRadius, distances: self.microtubuleDistances)
          }
          
          stepCounter += 1
    
      }
    
    func metalUpdater(){
        
        if isRunning{
            return
        }
        
        isRunning = true
        
        metalUpdaterChild()
        
        while scene.isPaused{
            DispatchQueue.global(qos: .default).sync {
                metalUpdaterChild()
            }
        }
        
        isRunning = false
  
    }
    
}

extension GameViewController: SCNSceneRendererDelegate {
    
  func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
            
    DispatchQueue.global(qos: .background).sync{
        metalUpdater()
    }
 
  }
    
}
