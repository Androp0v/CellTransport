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
import MobileCoreServices

class GameViewController: UIViewController, UIDocumentPickerDelegate {
    
    //MARK: - Class Properties
    
    var stepCounter: Int = 0
    var startTime: Date = Date()
    var slowMode: Bool = true
    var waitingMode: Bool = false
    var resetArrivalTimesRequired = false
    
    var microtubuleDistances: [Float] = []
    var microtubulePoints: [SCNVector3] = []
    var microtubuleNSegments: [Int] = []
    var microtubulePointsArray: [simd_float3] = []
        
    // CellID to MT dictionaries and arrays
    var cellIDDict: Dictionary<Int, [Int]> = [:]
    var cellIDtoIndex: [Int32] = [] //Array to translate cellID to MT index
    var cellIDtoNMTs: [Int16] = [] //Array to translate cellID to number of MTs in that specific cell
    var indexToPoint: [Int32] = [] //Array to translate MT index to MT point position (x,y,z)
    
    // GDC Queues and control variables
    let queueRandomSeed = DispatchQueue(label: "Random seeding", qos: .default, attributes: .concurrent)
    let queue1 = DispatchQueue(label: "TS-Histogram1", qos: .utility, attributes: .concurrent)
    let queue2 = DispatchQueue(label: "TS-Histogram2", qos: .utility, attributes: .concurrent)
    let queue3 = DispatchQueue(label: "TS-Histogram3", qos: .utility, attributes: .concurrent)
    let queue4 = DispatchQueue(label: "TS-Histogram4", qos: .utility, attributes: .concurrent)
    
    var isBusyRandomSeed = false
    var isBusy1 = false
    var isBusy2 = false
    var isBusy3 = false
    var isBusy4 = false
    
    // Main computing loop
    func metalLoop() {
        while !truePause {
            // Since we are running an infinite loop, we need to manually release the autoreleasepool after each iteration
            autoreleasepool {
                if slowMode && !scene.isPaused {
                    if !waitingMode {
                        // Save the start time to compute elapsed time later
                        let startTime = CACurrentMediaTime()
                        
                        // Launch one timestep of the simulation
                        DispatchQueue.global(qos: .background).sync {
                            metalUpdater()
                        }
                        
                        // Compute elapsed time (in millionths of a second)
                        let elapsedTime = (CACurrentMediaTime() - startTime)
                        
                        // Wait for the remaining time
                        if elapsedTime < 1.0/120.0{
                            let remainingTime = abs(1.0/120.0 - elapsedTime)
                            DispatchQueue.main.asyncAfter(deadline: .now() + remainingTime) {
                                self.waitingMode = false
                            }
                            self.waitingMode = true
                        }
                    }
                } else{
                    DispatchQueue.global(qos: .background).sync {
                            metalUpdater()
                    }
                }
                setBenchmarkLabel(benchmarkLabel: benchmarkLabel, startTime: startTime, steps: stepCounter)
            }
        }
    }
    
    // MARK: - UI elements
    
    @IBOutlet weak var scnContainer: UIView!
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
    @IBOutlet weak var benchmarkLabel: UILabel!
    @IBOutlet var freezeButton: UIButton!
    @IBOutlet var FrozenView: UIView!
    @IBAction func freeze(_ sender: Any) {
        // Reset benchmarking
        stepCounter = 0
        startTime = NSDate.now
        // Play or pause
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
    var pauseOnNextLoop = false
    @IBOutlet var pauseButton: UIButton!
    @IBAction func playPause(_ sender: Any) {
        // Reset benchmarking
        stepCounter = 0
        startTime = NSDate.now
        // Play or pause
        if pauseButton.currentImage == UIImage.init(systemName: "pause.fill"){
            pauseOnNextLoop = true
            pauseButton.setImage(UIImage.init(systemName: "play.fill"), for: .normal)
        }else{
            pauseOnNextLoop = false
            pauseButton.setImage(UIImage.init(systemName: "pause.fill"), for: .normal)
            if truePause {
                truePause = false
                DispatchQueue.global(qos: .background).async {
                    self.metalLoop()
                }
            }
        }
    }
    
    // Enable/disable slow mode
    @IBOutlet weak var slowModeButton: UIButton!
    @IBAction func slowModeToggle(_ sender: Any) {
        if slowModeButton.currentImage == UIImage.init(systemName: "hare.fill"){
            slowModeButton.setImage(UIImage.init(systemName: "tortoise.fill"), for: .normal)
            slowMode = false
        }else{
            slowModeButton.setImage(UIImage.init(systemName: "hare.fill"), for: .normal)
            slowMode = true
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
        exportParametersToFile(folderURL: urls[0], filename: "Parameters")
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
    
    // MARK: - Metal variables
    
    var device: MTLDevice!
    fileprivate var queue: MTLCommandQueue?
    fileprivate var library: MTLLibrary!
    fileprivate var computePipelineState: MTLComputePipelineState?
    fileprivate var verifyCollisionsPipelineState: MTLComputePipelineState?
    fileprivate var positionsIn: MTLBuffer?
    fileprivate var positionsOut: MTLBuffer?
    fileprivate var distancesBuffer: MTLBuffer?
    fileprivate var timeLastJumpBuffer: MTLBuffer?
    fileprivate var updatedTimeLastJumpBuffer: MTLBuffer?
    fileprivate var timeBetweenJumpsBuffer: MTLBuffer?
    
    fileprivate var oldTimeBuffer: MTLBuffer?
    fileprivate var newTimeBuffer: MTLBuffer?
    
    fileprivate var microtubulePointsBuffer: MTLBuffer?
    fileprivate var cellIDtoIndexBuffer: MTLBuffer?
    fileprivate var cellIDtoNMTsBuffer: MTLBuffer?
    fileprivate var indextoPointsBuffer: MTLBuffer?
    fileprivate var isAttachedInBuffer: MTLBuffer?
    fileprivate var isAttachedOutBuffer: MTLBuffer?
    
    fileprivate var randomSeedsInBuffer: MTLBuffer?
    fileprivate var randomSeedsOutBuffer: MTLBuffer?
    
    fileprivate var MTstepNumberInBuffer: MTLBuffer?
    fileprivate var MTstepNumberOutBuffer: MTLBuffer?
    
    fileprivate var cellIDtoOccupiedBuffer: MTLBuffer?
    
    fileprivate var buffer: MTLCommandBuffer?
    
    var isRunning = false
    
    var currentViewController: UIViewController?
    lazy var firstChildTabVC: ParametersViewController? = {
        let firstChildTabVC = self.storyboard?.instantiateViewController(withIdentifier: "ParametersViewController") as! ParametersViewController
        firstChildTabVC.mainGameViewController = self
        return firstChildTabVC
    }()
    lazy var secondChildTabVC : GraphsViewController? = {
        let secondChildTabVC = self.storyboard?.instantiateViewController(withIdentifier: "GraphsViewController")
        
        return (secondChildTabVC as! GraphsViewController)
    }()
    lazy var thirdChildTabVC : ComputeViewController? = {
        let thirdChildTabVC = self.storyboard?.instantiateViewController(withIdentifier: "ComputeViewController")
        
        return (thirdChildTabVC as! ComputeViewController)
    }()
    
    func viewControllerForSelectedSegmentIndex(_ index: Int) -> UIViewController? {
        var vc: UIViewController?
        switch index {
        case 0:
            vc = firstChildTabVC
        case 1:
            vc = secondChildTabVC
        case 2:
            vc = thirdChildTabVC
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
        let verifyCollisions = (library.makeFunction(name: "verifyCollisions"))!
        
        
            
        computePipelineState = try! device.makeComputePipelineState(function: compute)
        verifyCollisionsPipelineState = try! device.makeComputePipelineState(function: verifyCollisions)
        
    }
    
    //MARK: - Initialization
    
    func initializeMetal(){
        device = MTLCreateSystemDefaultDevice()
        queue = device.makeCommandQueue()
        library = device.makeDefaultLibrary()
        initComputePipelineState(device)
        
        //Create [Float] lists to populate buffers
        
        let initializedTimeJump = [Float](repeating: 0.0, count: parameters.nbodies)
        let initializedUpdatedTimeJump = [Float](repeating: 0.0, count: parameters.nbodies)
        let initializedTimeBetweenJumps = [Float](repeating: -1.0, count: parameters.nbodies)
        
        //Initialize buffers and populate those of them that need it
        
        distancesBuffer = device.makeBuffer(
            length: parameters.nbodies * MemoryLayout<Float>.stride
        )
        
        timeLastJumpBuffer = device.makeBuffer(
            bytes: initializedTimeJump,
            length: parameters.nbodies * MemoryLayout<Float>.stride
        )
        
        updatedTimeLastJumpBuffer = device.makeBuffer(
            bytes: initializedUpdatedTimeJump,
            length: parameters.nbodies * MemoryLayout<Float>.stride
        )
        
        timeBetweenJumpsBuffer = device.makeBuffer(
            bytes: initializedTimeBetweenJumps,
            length: parameters.nbodies * MemoryLayout<Float>.stride
        )
        
        let oldTime = [Float](repeating: 0.0, count: parameters.nbodies)
        
        oldTimeBuffer = device.makeBuffer(
            bytes: oldTime,
            length: parameters.nbodies * MemoryLayout<Float>.stride
        )
        
        newTimeBuffer = device.makeBuffer(
            length: parameters.nbodies * MemoryLayout<Float>.stride
        )
        
        var randomSeeds: [Float] = []
        while randomSeeds.count != parameters.nbodies{
            let number = Float.random(in: 0 ..< 1)
            randomSeeds.append(number)
        }
        randomSeedsInBuffer = device.makeBuffer(
            bytes: randomSeeds,
            length: parameters.nbodies * MemoryLayout<Float>.stride
        )
        randomSeedsOutBuffer = device.makeBuffer(
            bytes: randomSeeds,
            length: parameters.nbodies * MemoryLayout<Float>.stride
        )
        
    }
    
    func initializeMetalMTs(){

        microtubulePointsBuffer = device.makeBuffer(
            bytes: microtubulePointsArray,
            length: microtubulePointsArray.count * MemoryLayout<simd_float3>.stride
        )
        
        cellIDtoIndexBuffer = device.makeBuffer(
            bytes: cellIDtoIndex,
            length: cellIDtoIndex.count * MemoryLayout<Int32>.stride
        )
        
        cellIDtoNMTsBuffer = device.makeBuffer(
            bytes: cellIDtoNMTs,
            length: cellIDtoNMTs.count * MemoryLayout<Int16>.stride
        )
        
        indextoPointsBuffer = device.makeBuffer(
            bytes: indexToPoint,
            length: max(1,indexToPoint.count) * MemoryLayout<Int32>.stride
        )
        
        let isAttachedIn: [Int32] = [Int32](repeatElement(-1, count: parameters.nbodies))
        
        isAttachedInBuffer = device.makeBuffer(
            bytes: isAttachedIn,
            length: isAttachedIn.count * MemoryLayout<Int32>.stride
        )
        
        isAttachedOutBuffer = device.makeBuffer(
            bytes: isAttachedIn,
            length: isAttachedIn.count * MemoryLayout<Int32>.stride
        )
        
        let stepNumbers = [Int32](repeatElement(0, count: parameters.nbodies))
        
        MTstepNumberInBuffer = device.makeBuffer(
            bytes: stepNumbers,
            length: parameters.nbodies * MemoryLayout<Int32>.stride
        )
        MTstepNumberOutBuffer = device.makeBuffer(
            bytes: stepNumbers,
            length: parameters.nbodies * MemoryLayout<Int32>.stride
        )
        
        // Not strictly MT related, but useful to have  cellIDtoIndex.count available
        
        let cellIDtoOccupied = [Int32](repeating: 0, count: cellIDtoNMTs.count)
                
        cellIDtoOccupiedBuffer = device.makeBuffer(
            bytes: cellIDtoOccupied,
            length: cellIDtoOccupied.count * MemoryLayout<Int32>.stride
        )
        
    }
    
    func initializeSimulation(){
        // Spawn the bounding box
        DispatchQueue.main.async {
            self.alertLabel.text = "Drawing bounding box"
            self.alertView.backgroundColor = UIColor.init(cgColor: CGColor(srgbRed: 0.5, green: 0.5, blue: 0.5, alpha: 0.5))
        }
        let boundingBox = spawnBoundingBox()
        
        // Spawn the cell membrane
        DispatchQueue.main.async {
            self.alertLabel.text = "Generating cellular membrane"
        }
        let membranes = spawnCellMembrane(scene: scene)
        
        // Spawn the cell nucleus
        DispatchQueue.main.async {
            self.alertLabel.text = "Generating cellular nucleus"
        }
        var nucleus: SCNNode = SCNNode()
        if parameters.nucleusEnabled {
            nucleus = spawnCellNucleus()
        }
        
        // Spawn the microtubules
        DispatchQueue.main.async {
            self.alertLabel.text = "Generating microtubule structure"
        }
        let (microtubules, microtubulePointsReturned,
                microtubuleNSegmentsReturned, microtubulePointsArrayReturned) = spawnAllMicrotubules()
        microtubulePoints = microtubulePointsReturned
        microtubuleNSegments = microtubuleNSegmentsReturned
        microtubulePointsArray = microtubulePointsArrayReturned
                
        for microtubulePoint in microtubulePoints{
            microtubuleDistances.append(sqrt(microtubulePoint.x*microtubulePoint.x + microtubulePoint.y*microtubulePoint.y + microtubulePoint.z*microtubulePoint.z))
        }
        
        self.secondChildTabVC?.setHistogramData3(cellRadius: parameters.cellRadius, points: microtubulePoints)
        
        // Spawn points
        DispatchQueue.main.async {
            self.alertLabel.text = "Initializing all particle positions"
        }
        var pointsNodeList: [SCNNode] = []
        
        let meshData = MetalMeshDeformable.initializePoints(device, nbodies: parameters.nbodies, nBodiesPerCell: parameters.nbodies/parameters.nCells, cellRadius: parameters.cellRadius)
        positionsIn = meshData.vertexBuffer1
        positionsOut = meshData.vertexBuffer2
        
        let pointsNode = SCNNode(geometry: meshData.geometry)
        pointsNode.geometry?.firstMaterial?.diffuse.contents = UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
        pointsNode.geometry?.firstMaterial?.transparency = 1.0 //0.7
        pointsNode.geometry?.firstMaterial?.lightingModel = .constant
        pointsNode.geometry?.firstMaterial?.writesToDepthBuffer = false
        pointsNode.geometry?.firstMaterial?.readsFromDepthBuffer = true
        //pointsNode.geometry?.firstMaterial?.blendMode = SCNBlendMode.add
                    
        pointsNodeList.append(pointsNode)
        
        scene.rootNode.addChildNode(pointsNode)
        
        // animate the 3d object
        boundingBox.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 2, z: 0, duration: rotationTime)))
        for membrane in membranes{
            membrane.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 2, z: 0, duration: rotationTime)))
        }
        for pointsNode in pointsNodeList{
            pointsNode.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 2, z: 0, duration: rotationTime)))
        }
        for microtubule in microtubules{
            microtubule.geometry?.firstMaterial?.lightingModel = .constant
            microtubule.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 2, z: 0, duration: rotationTime)))
        }
        if parameters.nucleusEnabled{
            nucleus.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 2, z: 0, duration: rotationTime)))
        }
        
        //Set renderer delegate to start animation loop
        DispatchQueue.main.async {
            self.alertLabel.text = ""
            self.alertView.backgroundColor = UIColor.clear
        }
        scnView.delegate = self
        
        // Set simulation start time
        startTime = NSDate.now
        
        // Start simulation loop
        DispatchQueue.global(qos: .background).async {
            self.metalLoop()
        }
    }
    
    //MARK: - Spawners
    
    func spawnBoundingBox() -> SCNNode{
        
        var boundingBox:SCNGeometry

        boundingBox = SCNBox(width: CGFloat(2.0*parameters.cellRadius), height: CGFloat(2.0*parameters.cellRadius), length: CGFloat(2.0*parameters.cellRadius), chamferRadius: 0.0)
        boundingBox.firstMaterial?.fillMode = .lines
        boundingBox.firstMaterial?.isDoubleSided = true
        boundingBox.firstMaterial?.diffuse.contents = UIColor.white
        boundingBox.firstMaterial?.transparency = 0.05
        
        let boundingBoxNode = SCNNode(geometry: boundingBox)
        scene.rootNode.addChildNode(boundingBoxNode)
        
        return boundingBoxNode
    }
    
    func spawnAllMicrotubules() -> ([SCNNode],[SCNVector3],[Int],[simd_float3]){
        
        // Track progress of cells with completed MTs
        var completedMTsCount: Int = parameters.nMicrotubules // First cell is not computed in parallel, excluded from progress count
        var progressFinishedUpdating = true
        let startTime = NSDate.now
        
        func updateProgress(){
            let fractionCompleted = Float(completedMTsCount)/Float(parameters.nMicrotubules*parameters.nCells)
            DispatchQueue.main.async {
                self.alertLabel.text = "Generating microtubule structure of remaining cells: "
                                        + String(format: "%.2f", 100*fractionCompleted)
                                        + "% ("
                                        + formatRemainingTime(startTime: startTime, progress: fractionCompleted)
                                        + ")"
                progressFinishedUpdating = true
            }
        }
        
        // Create all-cells arrays
        var nodelist : [SCNNode] = []
        var microtubulePoints: [SCNVector3] = []
        var microtubuleNSegments: [Int] = []
        var separateMicrotubulePoints: [[simd_float3]] = []
        
        var cellsPointsNumber: [Int] = []
        
        // Add initial separator
        microtubulePointsArray.append(simd_float3(parameters.cellRadius,parameters.cellRadius,parameters.cellRadius))
                
        // Generate MTs for the first cell
                    
        DispatchQueue.main.async {
            self.alertLabel.text = "Generating microtubule structure of the first cell"
        }
        
        var cellPoints: Int = 0
        
        for _ in 0..<parameters.nMicrotubules{
            let points = generateMicrotubule(cellRadius: parameters.cellRadius, centrosomeRadius: parameters.centrosomeRadius, centrosomeLocation: parameters.centrosomeLocation, nucleusRadius: parameters.nucleusRadius, nucleusLocation: parameters.nucleusLocation)
            microtubuleNSegments.append(points.count)
            
            for point in points{
                microtubulePoints.append(point)
                microtubulePointsArray.append(simd_float3(point))
            }
            
            // Introduce separators after each MT (situated at an impossible point)
            microtubulePointsArray.append(simd_float3(parameters.cellRadius,parameters.cellRadius,parameters.cellRadius))
            
            //Update the number of MT points in the cell (including separator, +1)
            cellPoints += points.count + 1
            
            //UI configuration for the first cell (the only cell displayed on screen)
    
            let microtubuleColor = UIColor.green.withAlphaComponent(0.0).cgColor
            let geometry = SCNGeometry.lineThrough(points: points,
                                                   width: 2,
                                                   closed: false,
                                                   color: microtubuleColor)
            let node = SCNNode(geometry: geometry)
            scene.rootNode.addChildNode(node)
            nodelist.append(node)
        }
        //Update the length of each cell's MT points
        cellsPointsNumber.append(cellPoints)
        
        
        // Create a thread safe queue to write to all-cells arrays
        let threadSafeQueueForArrays = DispatchQueue(label: "Thread-safe write to arrays")
        let progressUpdateQueue = DispatchQueue(label: "Progress update queue")
        
        // Generate MTs for each cell concurrently (will use max available cores)
        DispatchQueue.concurrentPerform(iterations: parameters.nCells - 1, execute: { index in
            
            var cellPoints: Int = 0
            
            var localMicrotubulePoints: [SCNVector3] = []
            var localMicrotubuleNSegments: [Int] = []
            var localMicrotubulePointsArray: [simd_float3] = []
            var localSeparateMicrotubulePointsArray: [[simd_float3]] = []
            
            for _ in 0..<parameters.nMicrotubules{
                var localMicrotubule: [simd_float3] = []
                let points = generateMicrotubule(cellRadius: parameters.cellRadius, centrosomeRadius: parameters.centrosomeRadius, centrosomeLocation: parameters.centrosomeLocation, nucleusRadius: parameters.nucleusRadius, nucleusLocation: parameters.nucleusLocation)
                
                localMicrotubuleNSegments.append(points.count)
                
                for point in points{
                    localMicrotubule.append(simd_float3(point))
                    localMicrotubulePoints.append(point)
                    localMicrotubulePointsArray.append(simd_float3(point))
                }
                
                // Introduce separators after each MT (situated at an impossible point)
                localMicrotubulePointsArray.append(simd_float3(parameters.cellRadius,parameters.cellRadius,parameters.cellRadius))
                
                //Update the number of MT points in the cell (including separator, +1)
                cellPoints += points.count + 1
                
                // Mark the microtubule as completed and show progress
                progressUpdateQueue.async() {
                    completedMTsCount += 1
                    if progressFinishedUpdating {
                        updateProgress()
                    }
                }
                // Append microtubule
                localSeparateMicrotubulePointsArray.append(localMicrotubule)
            }
            
            // Update all-cells array with local ones safely
            threadSafeQueueForArrays.sync() {
                
                microtubulePoints.append(contentsOf: localMicrotubulePoints)
                microtubuleNSegments.append(contentsOf: localMicrotubuleNSegments)
                self.microtubulePointsArray.append(contentsOf: localMicrotubulePointsArray)
                
                // Update the length of each cell's MT points
                cellsPointsNumber.append(cellPoints)
                separateMicrotubulePoints.append(contentsOf: localSeparateMicrotubulePointsArray)
                
            }
        })
        
        thirdChildTabVC?.MTcollection = separateMicrotubulePoints
        
        DispatchQueue.main.sync {
            self.alertLabel.text = "Generating microtubule structure: Converting arrays for Metal"
        }
        
        //Add MTs to the CellID dictionary
        
        addMTToCellIDDict(cellIDDict: &cellIDDict, points: microtubulePointsArray, cellNMTPoints: cellsPointsNumber, cellRadius: parameters.cellRadius, cellsPerDimension: parameters.cellsPerDimension)
        
        //Convert MT dictionary to arrays
        
        cellIDDictToArrays(cellIDDict: cellIDDict, cellIDtoIndex: &cellIDtoIndex, cellIDtoNMTs: &cellIDtoNMTs, MTIndexArray: &indexToPoint, nCells: parameters.nCells, cellsPerDimension: parameters.cellsPerDimension, alertLabel: self.alertLabel)
                
        //Create MTLBuffers that require MT data
        initializeMetalMTs()
                
        return (nodelist,microtubulePoints,microtubuleNSegments,microtubulePointsArray)
    }
    
    func spawnCellNucleus() -> SCNNode{
        var nucleus:SCNGeometry
        // Generate nucleus as a perlin-noise biased icosphere. Low recursion level (vertex nuber) since texture will make it look good anyway
        nucleus = SCNIcosphere(radius: parameters.nucleusRadius, recursionLevel: 4, translucid: false, modulator: 0.00001, allowTexture: true)
        // Base color purple, not seen unless no image is found
        nucleus.firstMaterial?.diffuse.contents = UIColor.purple
        // Cellular nucleus texture
        nucleus.firstMaterial?.diffuse.contents = UIImage(named: "cellmembrane.png")
        
        // Create and move the SceneKit nodes
        let nucleusNode = SCNNode(geometry: nucleus)
        let nucleusAxis = SCNNode()
        nucleusAxis.addChildNode(nucleusNode)
        
        scene.rootNode.addChildNode(nucleusAxis)
        
        nucleusAxis.position = SCNVector3(x: 0, y: 0, z: 0)
        nucleusNode.position = parameters.nucleusLocation
        
        return nucleusAxis
    }
    
    //MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Compute global variables
        computeDeltaT()
        
        // initialize Metal for GPU calculations
        initializeMetal()
                
        // create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 5*parameters.cellRadius, z: 5*parameters.cellRadius)
        scene.rootNode.addChildNode(lightNode)
        
        // create and add a camera to the scene
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.focalLength = 50.0
        cameraNode.camera?.zFar = 500000
        scene.rootNode.addChildNode(cameraNode)
        
        // place the camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 7*parameters.cellRadius)
        
        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = UIColor.darkGray
        scene.rootNode.addChildNode(ambientLightNode)
        
        // set the scene to the view
        scnView.scene = scene
        
        // allows the user to manipulate the camera
        scnView.allowsCameraControl = true
        
        // show statistics such as fps and timing information
        scnView.showsStatistics = true
        
        // configure the view
        scnView.backgroundColor = UIColor.black
        scnContainer.backgroundColor = UIColor.black
                
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
        
        self.firstChildTabVC?.changenCellsText(text: String(parameters.nCells))
        self.firstChildTabVC?.changeParticlesPerCellText(text: String(parameters.nbodies/parameters.nCells))
        self.firstChildTabVC?.changenBodiesText(text: String(parameters.nbodies))
        self.firstChildTabVC?.changeMicrotubulesText(text: String(parameters.nMicrotubules))
        
        //Initialize the simulation
        DispatchQueue.global(qos: .default).async {
            self.initializeSimulation()
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
    
    //MARK: - Metal loop
    
    //Define a struct of parameters to be passed to the kernel function in Metal
    struct simulationParameters{
        var deltat_to_metal: Float;
        var cellRadius_to_metal: Float;
        var cellsPerDimension_to_metal: Int32;
        var nBodies_to_Metal: Int32;
        var nCells_to_Metal: Int32;
        var wON: Float;
        var wOFF: Float;
        var n_w: Float;
        var boundaryConditions: Int32;
        var molecularMotors: Int32;
        var stepsPerMTPoint: Int32;
        var nucleusEnabled: Bool;
        var nucleusRadius: Float;
        var nucleusLocation: simd_float3;
    }
    
    func metalUpdater() {
        
        // Create simulationParameters struct
        
        var simulationParametersObject = simulationParameters(deltat_to_metal: parameters.deltat, cellRadius_to_metal: parameters.cellRadius, cellsPerDimension_to_metal: Int32(parameters.cellsPerDimension), nBodies_to_Metal: Int32(parameters.nbodies), nCells_to_Metal: Int32(parameters.nCells), wON: parameters.wON, wOFF: parameters.wOFF, n_w: parameters.n_w, boundaryConditions: parameters.boundaryConditions, molecularMotors: parameters.molecularMotors, stepsPerMTPoint: parameters.stepsPerMTPoint, nucleusEnabled: parameters.nucleusEnabled, nucleusRadius: parameters.nucleusRadius, nucleusLocation: simd_float3(parameters.nucleusLocation))
        
        // Reset the buffers if required, wait until the buffer is not being read by the plotting functions
        if resetArrivalTimesRequired && !isBusy2 {
            
            let initializedTimeJump = [Float](repeating: 0.0, count: parameters.nbodies)
            let initializedUpdatedTimeJump = [Float](repeating: 0.0, count: parameters.nbodies)
            let initializedTimeBetweenJumps = [Float](repeating: -1.0, count: parameters.nbodies)
            
            timeLastJumpBuffer = device.makeBuffer(
                bytes: initializedTimeJump,
                length: parameters.nbodies * MemoryLayout<Float>.stride
            )
            
            updatedTimeLastJumpBuffer = device.makeBuffer(
                bytes: initializedUpdatedTimeJump,
                length: parameters.nbodies * MemoryLayout<Float>.stride
            )
            
            timeBetweenJumpsBuffer = device.makeBuffer(
                bytes: initializedTimeBetweenJumps,
                length: parameters.nbodies * MemoryLayout<Float>.stride
            )
            
            resetArrivalTimesRequired = false
        }
        
        // Update MTLBuffers thorugh compute pipeline
            
        buffer = queue?.makeCommandBuffer()
            
        // Compute kernel
        let threadsPerArray = MTLSizeMake(parameters.nbodies, 1, 1)
        //let groupsize = MTLSizeMake(computePipelineState[0]!.maxTotalThreadsPerThreadgroup,1,1)
        let groupsize = MTLSizeMake(64,1,1)
        
        let computeEncoder = buffer!.makeComputeCommandEncoder()
          
        computeEncoder?.setComputePipelineState(computePipelineState!)
        computeEncoder?.setBuffer(positionsIn, offset: 0, index: 0)
        computeEncoder?.setBuffer(positionsOut, offset: 0, index: 1)
        computeEncoder?.setBuffer(distancesBuffer, offset: 0, index: 2)
        computeEncoder?.setBuffer(timeLastJumpBuffer, offset: 0, index: 3)
        computeEncoder?.setBuffer(updatedTimeLastJumpBuffer, offset: 0, index: 4)
        computeEncoder?.setBuffer(timeBetweenJumpsBuffer, offset: 0, index: 5)
        computeEncoder?.setBuffer(oldTimeBuffer, offset: 0, index: 6)
        computeEncoder?.setBuffer(newTimeBuffer, offset: 0, index: 7)
        
        computeEncoder?.setBuffer(microtubulePointsBuffer, offset: 0, index: 8)
        computeEncoder?.setBuffer(cellIDtoIndexBuffer, offset: 0, index: 9)
        computeEncoder?.setBuffer(cellIDtoNMTsBuffer, offset: 0, index: 10)
        computeEncoder?.setBuffer(indextoPointsBuffer, offset: 0, index: 11)
        computeEncoder?.setBuffer(isAttachedInBuffer, offset: 0, index: 12)
        computeEncoder?.setBuffer(isAttachedOutBuffer, offset: 0, index: 13)
        
        computeEncoder?.setBuffer(randomSeedsInBuffer, offset: 0, index: 14)
        computeEncoder?.setBuffer(randomSeedsOutBuffer, offset: 0, index: 15)
        
        computeEncoder?.setBuffer(MTstepNumberInBuffer, offset: 0, index: 16)
        computeEncoder?.setBuffer(MTstepNumberOutBuffer, offset: 0, index: 17)
        
        computeEncoder?.setBytes(&simulationParametersObject, length: MemoryLayout<simulationParameters>.stride, index: 18)
        computeEncoder?.dispatchThreads(threadsPerArray, threadsPerThreadgroup: groupsize)
          
        computeEncoder?.endEncoding()
        buffer!.commit()
        
        // Check wether to do collision handling
        if (parameters.collisionsFlag){
                        
            buffer = queue?.makeCommandBuffer()
            let threadsPerArrayCollisions = MTLSizeMake(parameters.nCells, 1, 1)
            let verifyCollisionsEncoder = buffer!.makeComputeCommandEncoder()
            
            verifyCollisionsEncoder?.setComputePipelineState(verifyCollisionsPipelineState!)
            verifyCollisionsEncoder?.setBuffer(positionsIn, offset: 0, index: 0)
            verifyCollisionsEncoder?.setBuffer(positionsOut, offset: 0, index: 1)
            verifyCollisionsEncoder?.setBuffer(isAttachedInBuffer, offset: 0, index: 2)
            verifyCollisionsEncoder?.setBuffer(isAttachedOutBuffer, offset: 0, index: 3)
            verifyCollisionsEncoder?.setBuffer(cellIDtoOccupiedBuffer, offset: 0, index: 4)
            verifyCollisionsEncoder?.setBuffer(distancesBuffer, offset: 0, index: 5)
            
            verifyCollisionsEncoder?.setBytes(&simulationParametersObject, length: MemoryLayout<simulationParameters>.stride, index: 6)
            
            verifyCollisionsEncoder?.dispatchThreads(threadsPerArrayCollisions, threadsPerThreadgroup: groupsize)
            
            verifyCollisionsEncoder?.endEncoding()
            buffer!.commit()
            
        }else{
            swap(&positionsIn, &positionsOut)
            swap(&isAttachedInBuffer, &isAttachedOutBuffer)
        }
        
        // Swap in/out arrays
                
        //swap(&positionsIn, &positionsOut)
        swap(&timeLastJumpBuffer, &updatedTimeLastJumpBuffer)
        swap(&oldTimeBuffer, &newTimeBuffer)
        //swap(&isAttachedInBuffer, &isAttachedOutBuffer)
        swap(&randomSeedsInBuffer, &randomSeedsOutBuffer)
        swap(&MTstepNumberInBuffer, &MTstepNumberOutBuffer)
        
        // Asynchronously launch histogram computations if not already running
        
        let distances = distancesBuffer!.contents().assumingMemoryBound(to: Float.self)
        let timeJumps = timeBetweenJumpsBuffer!.contents().assumingMemoryBound(to: Float.self)
        let attachState = isAttachedInBuffer!.contents().assumingMemoryBound(to: Int32.self)
        
        if !(self.isBusy1){
            self.isBusy1 = true
            queue1.async(){
                self.secondChildTabVC?.setHistogramData1(cellRadius: parameters.cellRadius, distances: distances, nBodies: parameters.nbodies, attachState: attachState)
                DispatchQueue.main.sync {
                    self.isBusy1 = false
                }
            }
        }
        
        if !self.isBusy2 && !self.resetArrivalTimesRequired {
            self.isBusy2 = true
            queue2.async(){
                self.secondChildTabVC?.setHistogramData2(cellRadius: parameters.cellRadius, distances: timeJumps, nBodies: parameters.nbodies)
                DispatchQueue.main.sync {
                    self.isBusy2 = false
                }
            }
        }
        
        if !(self.isBusy3){
            self.isBusy3 = true
            queue3.async(){
                self.secondChildTabVC?.setHistogramData3(cellRadius: parameters.cellRadius, points: self.microtubulePoints)
                DispatchQueue.main.sync {
                    self.isBusy3 = false
                }
            }
        }
        
        if !(self.isBusy4){
            self.isBusy4 = true
            queue4.async(){
                self.secondChildTabVC?.setHistogramData4(cellRadius: parameters.cellRadius, counts: self.microtubuleNSegments)
                DispatchQueue.main.sync {
                    self.isBusy4 = false
                }
            }
        }
        
        // Every 1000 steps, clean the random numbers re-seeding them from Swift
        if !self.isBusyRandomSeed && (stepCounter % 1000 == 0) {
            self.isBusyRandomSeed = true
            queueRandomSeed.async(){
                let randomBufferToSwift = self.randomSeedsInBuffer!.contents().assumingMemoryBound(to: Float.self)
                for i in 0..<parameters.nbodies{
                    randomBufferToSwift[i] = Float.random(in: 0..<1)
                }
                DispatchQueue.main.sync {
                    self.isBusyRandomSeed = false
                }
            }
        }
        /*if stepCounter % 1000 == 0 {
            let randomBufferToSwift = self.randomSeedsInBuffer[0]!.contents().assumingMemoryBound(to: Float.self)
            for i in 0..<parameters.nbodies{
                randomBufferToSwift[i] = Float.random(in: 0..<1)
            }
        }*/
        
        stepCounter += 1
        
        // Set the global variable truePause to inform that the loop has finished if a pause was scheduled
        if self.pauseOnNextLoop {
            self.truePause = true
        }
    }
    
}

extension GameViewController: SCNSceneRendererDelegate {
    
  func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
    // Do things on SceneKit render loop
  }
    
}
