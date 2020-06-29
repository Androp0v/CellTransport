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

class GameViewController: UIViewController, UIDocumentPickerDelegate {
    
    var stepCounter: Int = 0
    
    // Simulation parameters
    
    let nCells: Int = 100 //Number of biological cells to simulate simultaneously
    let cellsPerDimension = 100 //Cells are subdivided in cubic cells: cellsPerDimension for each side
    let nbodies: Int = 524288 //4194304 // 16777216
    let nMicrotubules: Int = 400
    let cellRadius: Float = 14000 //nm
    let centrosomeRadius: Float = 1400 //nm
    let nucleusLocation: SCNVector3 = SCNVector3(0.0,0.0,0.2*14000)
    let centrosomeLocation: SCNVector3 = SCNVector3(0.0,0.0,0.0)
    public let deltat: Float = 0.00001
    
    var microtubuleDistances: [Float] = []
    var microtubulePoints: [SCNVector3] = []
    var microtubuleNSegments: [Int] = []
    var microtubulePointsArray: [simd_float3] = []
    
    var cellIDDict: Dictionary<Int, [Int]> = [:]
    
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
    
    var truePause = false
    @IBOutlet var pauseButton: UIButton!
    @IBAction func playPause(_ sender: Any) {
        if pauseButton.currentImage == UIImage.init(systemName: "pause.fill"){
            scene.isPaused = true
            truePause = true
            pauseButton.setImage(UIImage.init(systemName: "play.fill"), for: .normal)
        }else{
            scene.isPaused = false
            truePause = false
            pauseButton.setImage(UIImage.init(systemName: "pause.fill"), for: .normal)
        }
    }
    
    // Save to .txt code
    
    @IBAction func exportToFile(_ sender: Any) {
        // Create a document picker for directories.
        let documentPicker = UIDocumentPickerViewController(documentTypes: [kUTTypeFolder as String], in: .open)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false

        // Present the document picker.
        present(documentPicker, animated: true, completion: nil)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        //Execute code after picking an export folder with exportToFile()
        exportHistogramToFile(histogram: (secondChildTabVC?.getHistogramData(number: 1)) ?? [], folderURL: urls[0], filename: "Hist1")
        exportHistogramToFile(histogram: (secondChildTabVC?.getHistogramData(number: 2)) ?? [], folderURL: urls[0], filename: "Hist2")
        exportHistogramToFile(histogram: (secondChildTabVC?.getHistogramData(number: 3)) ?? [], folderURL: urls[0], filename: "Hist3")
        exportHistogramToFile(histogram: (secondChildTabVC?.getHistogramData(number: 4)) ?? [], folderURL: urls[0], filename: "Hist4")
    }
    
    @IBOutlet var topBarBackground: UIView!
    
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
    
    fileprivate var microtubulePointsBuffer: [MTLBuffer?] = []
    
    fileprivate var buffer: MTLCommandBuffer?
    
    let nBuffers = 1
    var isRunning = false
    
    var currentViewController: UIViewController?
    lazy var firstChildTabVC: ParametersViewController? = {
        let firstChildTabVC = self.storyboard?.instantiateViewController(withIdentifier: "ParametersViewController")
        return (firstChildTabVC as! ParametersViewController)
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
        
        //Create [Float] lists to populate buffers
        
        let initializedTimeJump = [Float](repeating: 0.0, count: nbodies)
        let initializedUpdatedTimeJump = [Float](repeating: 0.0, count: nbodies)
        let initializedTimeBetweenJumps = [Float](repeating: -1.0, count: nbodies)
        
        //Initialize buffers and populate those of them that need it
        
        distancesBuffer.append(device.makeBuffer(
            length: nbodies * MemoryLayout<Float>.stride
        ))
        
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
    
    func initializeMetalMTs(){
        
        microtubulePointsBuffer.append(device.makeBuffer(
            bytes: microtubulePointsArray,
            length: microtubulePointsArray.count * MemoryLayout<simd_float3>.stride
        ))
        
    }
    
    func spawnBoundingBox() -> SCNNode{
        
        var boundingBox:SCNGeometry

        boundingBox = SCNBox(width: CGFloat(2.0*cellRadius), height: CGFloat(2.0*cellRadius), length: CGFloat(2.0*cellRadius), chamferRadius: 0.0)
        boundingBox.firstMaterial?.fillMode = .lines
        boundingBox.firstMaterial?.isDoubleSided = true
        boundingBox.firstMaterial?.diffuse.contents = UIColor.white
        boundingBox.firstMaterial?.transparency = 0.05
        
        let boundingBoxNode = SCNNode(geometry: boundingBox)
        scene.rootNode.addChildNode(boundingBoxNode)
        
        return boundingBoxNode
    }
    
    func spawnMicrotubules() -> ([SCNNode],[SCNVector3],[Int],[simd_float3]){
        
        var nodelist : [SCNNode] = []
        var microtubulePoints: [SCNVector3] = []
        var microtubuleNSegments: [Int] = []
        
        var microtubulePointsArray: [simd_float3] = []
        
        for i in 0..<(nCells*nMicrotubules){
            let points = generateMicrotubule(cellRadius: cellRadius, centrosomeRadius: centrosomeRadius, centrosomeLocation: centrosomeLocation)
            microtubuleNSegments.append(points.count)
            
            for point in points{
                microtubulePoints.append(point)
                microtubulePointsArray.append(simd_float3(point))
            }
            
            //Introduce separators after each cell (situated at an impossible point)
            
            microtubulePointsArray.append(simd_float3(cellRadius,cellRadius,cellRadius))
            
            //Add MTs to the CellID dictionary
            
            addMTToCellIDDict(cellIDDict: cellIDDict, points: points, currentCellNumber: i, cellsPerDimension: cellsPerDimension)
                        
            //UI configuration
            
            let microtubuleColor = UIColor.green.withAlphaComponent(0.0).cgColor
            
            if i < nMicrotubules{
                let geometry = SCNGeometry.lineThrough(points: points,
                                                       width: 2,
                                                       closed: false,
                                                       color: microtubuleColor)
                let node = SCNNode(geometry: geometry)
                scene.rootNode.addChildNode(node)
                nodelist.append(node)
            }
        }
        
        //Create MTLBuffers that require MT data
        //initializeMetalMTs() //TO-DO
                
        return (nodelist,microtubulePoints,microtubuleNSegments,microtubulePointsArray)
    }
    
    func spawnCellMembrane() -> SCNNode{
        
        //var membrane:SCNSphere
        
        //membrane = SCNSphere(radius: CGFloat(cellRadius))
        //membrane.segmentCount = 96
        
        var membrane: SCNGeometry
        membrane = SCNIcosphere(radius: cellRadius)
        
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.black
        material.reflective.contents = UIColor(red: 0.2, green: 0.764, blue: 1, alpha: 1)
        material.reflective.intensity = 1
        material.transparent.contents = UIColor.black.withAlphaComponent(0.15)
        material.transparencyMode = .default
        material.fresnelExponent = 4
        
        material.lightingModel = .constant
        material.blendMode = .screen
        material.writesToDepthBuffer = false
        
        membrane.materials = [material]
        
        let membraneNode = SCNNode(geometry: membrane)

        scene.rootNode.addChildNode(membraneNode)
        
        membraneNode.position = SCNVector3(x: 0, y: 0, z: 0)
        
        //Added second sphere membrane for faint base color
        let membrane2 = SCNSphere(radius: CGFloat(cellRadius*0.99))
        membrane2.segmentCount = 96
        membrane2.firstMaterial?.transparency = 0.05
        membrane2.firstMaterial?.diffuse.contents = UIColor(red: 0.2, green: 0.764, blue: 1, alpha: 1)
        membrane2.firstMaterial?.lightingModel = .constant
        let membraneNode2 = SCNNode(geometry: membrane2)
        scene.rootNode.addChildNode(membraneNode2)
        membraneNode2.position = SCNVector3(x: 0, y: 0, z: 0)
        
        return membraneNode
    }
    
    func spawnCellNucleus() -> SCNNode{
        var nucleus:SCNGeometry
        
        nucleus = SCNSphere(radius: CGFloat(0.3*cellRadius))
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
                
        // finish UI configuration
        
        let blurEffect = UIBlurEffect(style: .systemThickMaterial)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = self.topBarBackground.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        topBarBackground.addSubview(blurEffectView)
        
        //nparticlesTextField.text = String(nbodies)
        buttonContainerView.layer.cornerRadius = 7.5
        alertView.layer.cornerRadius = 7.5
        alertView.backgroundColor = UIColor.clear
        
        segmentedControl.selectedSegmentIndex = TabIndex.firstChildTab.rawValue
        displayCurrentTab(TabIndex.firstChildTab.rawValue)
        
        // hacky hack to initialize lazy var safely on a main thread
        self.secondChildTabVC?.clearAllGraphs(Any.self)
        
        // finish VC UIs
        
        self.firstChildTabVC?.changenCellsText(text: String(nCells))
        self.firstChildTabVC?.changeParticlesPerCellText(text: String(nbodies/nCells))
        self.firstChildTabVC?.changenBodiesText(text: String(nbodies))
        self.firstChildTabVC?.changeMicrotubulesText(text: String(nMicrotubules))
        
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
        
        // spawn the cell membrane
        DispatchQueue.main.async {
            self.alertLabel.text = "Generating cellular membrane"
        }
        let membrane = spawnCellMembrane()
        
        // spawn the cell nucleus
        DispatchQueue.main.async {
            self.alertLabel.text = "Generating cellular nucleus"
        }
        //let nucleus = spawnCellNucleus()
        
        // spawn the microtubules
        DispatchQueue.main.async {
            self.alertLabel.text = "Generating microtubule structure"
        }
        let (microtubules, microtubulePointsReturned,
                microtubuleNSegmentsReturned, microtubulePointsArrayReturned) = spawnMicrotubules()
        microtubulePoints = microtubulePointsReturned
        microtubuleNSegments = microtubuleNSegmentsReturned
        microtubulePointsArray = microtubulePointsArrayReturned
                
        for microtubulePoint in microtubulePoints{
            microtubuleDistances.append(sqrt(microtubulePoint.x*microtubulePoint.x + microtubulePoint.y*microtubulePoint.y + microtubulePoint.z*microtubulePoint.z))
        }
        
        self.secondChildTabVC?.setHistogramData3(cellRadius: self.cellRadius, points: microtubulePoints)
        
        // spawn points
        DispatchQueue.main.async {
            self.alertLabel.text = "Initializing all particle positions"
        }
        var pointsNodeList: [SCNNode] = []
        
        for _ in 0..<nBuffers{
            let meshData = MetalMeshDeformable.initializePoints(device, nbodies: nbodies/nBuffers, nBodiesPerCell: nbodies/nCells, cellRadius: cellRadius)
            positionsIn.append(meshData.vertexBuffer1)
            positionsOut.append(meshData.vertexBuffer2)
            
            let pointsNode = SCNNode(geometry: meshData.geometry)
            pointsNode.geometry?.firstMaterial?.diffuse.contents = UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
            pointsNode.geometry?.firstMaterial?.transparency = 1.0 //0.7
            pointsNode.geometry?.firstMaterial?.lightingModel = .constant
            pointsNode.geometry?.firstMaterial?.writesToDepthBuffer = false
            pointsNode.geometry?.firstMaterial?.readsFromDepthBuffer = true
            //pointsNode.geometry?.firstMaterial?.blendMode = SCNBlendMode.add
                        
            pointsNodeList.append(pointsNode)
            
            scene.rootNode.addChildNode(pointsNode)
        }
        
        // animate the 3d object
        boundingBox.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 2, z: 0, duration: rotationTime)))
        membrane.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 2, z: 0, duration: rotationTime)))
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
    
    //Define a struct of parameters to be passed to the kernel function in Metal
    struct simulationParameters{
        var deltat_to_metal: Float;
        var cellRadius_to_metal: Float;
    }
    
    func metalUpdaterChild(){
        
        // Create simulationParameters struct
        
        var simulationParametersObject = simulationParameters(deltat_to_metal: deltat, cellRadius_to_metal: cellRadius)
        
        // Update MTLBuffers thorugh compute pipeline
            
        buffer = queue?.makeCommandBuffer()
            
        // Compute kernel
        let threadsPerArray = MTLSizeMake(nbodies/nBuffers, 1, 1)
        //let groupsize = MTLSizeMake(computePipelineState[0]!.maxTotalThreadsPerThreadgroup,1,1)
        let groupsize = MTLSizeMake(64,1,1)
        
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
            computeEncoder?.setBytes(&simulationParametersObject, length: MemoryLayout<simulationParameters>.stride, index: 8)
            computeEncoder?.dispatchThreads(threadsPerArray, threadsPerThreadgroup: groupsize)
        }
          
        computeEncoder?.endEncoding()
        buffer!.commit()
          
        swap(&positionsIn, &positionsOut)
        swap(&timeLastJumpBuffer, &updatedTimeLastJumpBuffer)
        swap(&oldTimeBuffer, &newTimeBuffer)
          
        let distances = distancesBuffer[0]!.contents().assumingMemoryBound(to: Float.self)
        let timeJumps = timeBetweenJumpsBuffer[0]!.contents().assumingMemoryBound(to: Float.self)
        
        if !(self.secondChildTabVC?.histogramChart1?.isBusy ?? true){
            DispatchQueue.global(qos: .default).async {
                self.secondChildTabVC?.setHistogramData1(cellRadius: self.cellRadius, distances: distances, nBodies: self.nbodies)
            }
        }
            
        if !(self.secondChildTabVC?.histogramChart2?.isBusy ?? true){
            DispatchQueue.global(qos: .default).async {
                self.secondChildTabVC?.setHistogramData2(cellRadius: self.cellRadius, distances: timeJumps, nBodies: self.nbodies)
            }
        }
            
        if !(self.secondChildTabVC?.histogramChart3?.isBusy ?? true){
            DispatchQueue.global(qos: .default).async {
                self.secondChildTabVC?.setHistogramData3(cellRadius: self.cellRadius, points: self.microtubulePoints)
            }
        }
        
        if !(self.secondChildTabVC?.histogramChart4?.isBusy ?? true){
            DispatchQueue.global(qos: .default).async {
                self.secondChildTabVC?.setHistogramData4(cellRadius: self.cellRadius, counts: self.microtubuleNSegments)
            }
        }
                        
        stepCounter += 1
        
    }
    
    func metalUpdater(){
        
        isRunning = true
        
        metalUpdaterChild()
        
        if !truePause{
            while scene.isPaused{
                DispatchQueue.global(qos: .background).sync {
                    metalUpdaterChild()
                }
            }
        }
        isRunning = false
    }
    
}

extension GameViewController: SCNSceneRendererDelegate {
    
  func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
            
    if !isRunning{
        DispatchQueue.global(qos: .background).sync{
            metalUpdater()
        }
    }
  }
    
}
