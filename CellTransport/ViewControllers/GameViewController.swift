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
    
    // MARK: - Class Properties
    
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
    var cellIDDict: [Int: [Int]] = [Int: [Int]]()
    var cellIDtoIndex: [Int32] = [] // Array to translate cellID to MT index
    var cellIDtoNMTs: [Int16] = [] // Array to translate cellID to number of MTs in that specific cell
    var indexToPoint: [Int32] = [] // Array to translate MT index to MT point position (x,y,z)
    
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

    // Control flow
    var truePause = false // Signal to kill metalLoop(), true doesn't mean isRunning is already false
    var pauseOnNextLoop = false // Wether to pause on next metalLoop() iteration
    var isRunning = false // Wether or not metalLoop() is running
    var isInitialized = false // Wether or not the simulation is initialized
    var hasUIPause = false // Wether or not the UIButton displays the simulation as paused
    
    // Main computing loop
    func metalLoop() {
        // Signal that the metalLoop has started
        isRunning = true
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
                        if elapsedTime < 1.0/120.0 {
                            let remainingTime = abs(1.0/120.0 - elapsedTime)
                            DispatchQueue.main.asyncAfter(deadline: .now() + remainingTime) {
                                self.waitingMode = false
                            }
                            self.waitingMode = true
                        }
                    }
                } else {
                    DispatchQueue.global(qos: .background).sync {
                            metalUpdater()
                    }
                }
                setBenchmarkLabel(benchmarkLabel: benchmarkLabel, startTime: startTime, steps: stepCounter)
            }
        }
        // Signal that the metalLoop has finished
        isRunning = false
    }
    
    // MARK: - UI elements
    
    @IBOutlet weak var scnContainer: UIView!
    @IBOutlet var scnView: SCNView!
    let scene = SCNScene(named: "art.scnassets/ship.scn")!
    @IBOutlet var segmentedControl: UISegmentedControl!
    @IBOutlet var containerView: UIView!
    @IBOutlet weak var sidebarWidthConstraint: NSLayoutConstraint!
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
        if scene.isPaused == true {
            scene.isPaused = false
            freezeButton.setImage(UIImage(systemName: "snow"), for: .normal)
            FrozenView.alpha = 0.0
            DispatchQueue.main.async {
                self.alertLabel.text = ""
                self.alertView.backgroundColor = UIColor.clear
            }
        } else {
            scene.isPaused = true
            freezeButton.setImage(UIImage(named: "Defrost"), for: .normal)
            FrozenView.alpha = 1.0
            DispatchQueue.main.async {
                self.alertLabel.text = "Simulation running in the background"
                self.alertView.backgroundColor = UIColor.init(cgColor: CGColor(srgbRed: 0.5, green: 0.5, blue: 0.5, alpha: 0.5))
            }
        }
    }

    @IBOutlet var pauseButton: UIButton!
    @IBAction func playPause(_ sender: Any) {
        // Reset benchmarking
        stepCounter = 0
        startTime = NSDate.now
        // Play or pause
        if pauseButton.currentImage == UIImage.init(systemName: "pause.fill") {
            pauseOnNextLoop = true
            hasUIPause = true
            pauseButton.setImage(UIImage.init(systemName: "play.fill"), for: .normal)
        } else {
            pauseOnNextLoop = false
            hasUIPause = false
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
        if slowModeButton.currentImage == UIImage.init(systemName: "hare.fill") {
            slowModeButton.setImage(UIImage.init(systemName: "tortoise.fill"), for: .normal)
            slowMode = false
        } else {
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
        // Execute code after picking an export folder with exportToFile()
        exportParametersToFile(folderURL: urls[0], filename: "Parameters")
        exportHistogramToFile(histogram: (secondChildTabVC?.getHistogramData(number: 1)) ?? [], folderURL: urls[0], filename: "Hist1")
        exportHistogramToFile(histogram: (secondChildTabVC?.getHistogramData(number: 2)) ?? [], folderURL: urls[0], filename: "Hist2")
        exportHistogramToFile(histogram: (secondChildTabVC?.getHistogramData(number: 3)) ?? [], folderURL: urls[0], filename: "Hist3")
        exportHistogramToFile(histogram: (secondChildTabVC?.getHistogramData(number: 4)) ?? [], folderURL: urls[0], filename: "Hist4")
    }
    
    @IBOutlet var topBarBackground: UIView!
    
    let rotationTime: TimeInterval = 40
    
    enum TabIndex: Int {
        case firstChildTab = 0
        case secondChildTab = 1
    }

    /// Handle invalid parameter errors
    /// - Parameter notification: Notification
    @objc func didReceiveInputError(notification: Notification) {

        // Process notification content
        var title: String?
        var message: String?
        if let dict = notification.userInfo as NSDictionary? {
            title = dict["title"] as? String
            message = dict["message"] as? String
        }

        DispatchQueue.main.async {
            let fatalAlert = FatalCrashAlertController(title: title,
                                                       message: message,
                                                       preferredStyle: .alert)
            self.present(fatalAlert, animated: true, completion: nil)
        }
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

    var currentViewController: UIViewController?
    var firstChildTabVC: ParametersViewController?
    var secondChildTabVC: GraphsViewController?
    var thirdChildTabVC: ComputeViewController?
    
    func viewControllerForSelectedSegmentIndex(_ index: Int) -> UIViewController? {
        var viewController: UIViewController?
        switch index {
        case 0:
            viewController = firstChildTabVC
        case 1:
            viewController = secondChildTabVC
        case 2:
            viewController = thirdChildTabVC
        default:
        return nil
        }
    
        return viewController
    }
    
    func displayCurrentTab(_ tabIndex: Int) {
        if let viewController = viewControllerForSelectedSegmentIndex(tabIndex) {
            
            self.addChild(viewController)
            viewController.didMove(toParent: self)
            
            viewController.view.frame = self.containerView.bounds
            self.containerView.addSubview(viewController.view)
            self.currentViewController = viewController
        }
    }

    // MARK: - Pipeline initialization
    
    func initComputePipelineState(_ device: MTLDevice) {

        // Create temporal variables so Parameters can be kept let constants
        var deltatCompileConstant: Float = Parameters.deltat
        var stepsPerMTPointCompileConstant: Int = Int(Parameters.stepsPerMTPoint)
        var cellRadiusCompileConstant: Float = Parameters.cellRadius
        var cellWidthCompileConstant: Float = Parameters.cellWidth
        var cellHeightCompileConstant: Float = Parameters.cellHeight
        var cellLengthCompileConstant: Float = Parameters.cellLength
        var cellShapeCompileConstant: Int = Int(Parameters.cellShape)
        var cellsPerDimensionCompileConstant: Int = Int(Parameters.cellsPerDimension)
        var nBodiesCompileConstant: Int = Int(Parameters.nbodies)
        var nCellsCompileConstant: Int = Int(Parameters.nCells)
        var nucleusEnabledCompileConstant: Bool = Parameters.nucleusEnabled

        // Create compute compiler constants
        let computeFunctionCompileConstants = MTLFunctionConstantValues()
        computeFunctionCompileConstants.setConstantValue(&deltatCompileConstant, type: .float, index: 0)
        computeFunctionCompileConstants.setConstantValue(&stepsPerMTPointCompileConstant, type: .int, index: 1)
        computeFunctionCompileConstants.setConstantValue(&cellRadiusCompileConstant, type: .float, index: 2)
        computeFunctionCompileConstants.setConstantValue(&cellWidthCompileConstant, type: .float, index: 3)
        computeFunctionCompileConstants.setConstantValue(&cellHeightCompileConstant, type: .float, index: 4)
        computeFunctionCompileConstants.setConstantValue(&cellLengthCompileConstant, type: .float, index: 5)
        computeFunctionCompileConstants.setConstantValue(&cellShapeCompileConstant, type: .int, index: 6)
        computeFunctionCompileConstants.setConstantValue(&cellsPerDimensionCompileConstant, type: .int, index: 7)
        computeFunctionCompileConstants.setConstantValue(&nBodiesCompileConstant, type: .int, index: 8)
        computeFunctionCompileConstants.setConstantValue(&nCellsCompileConstant, type: .int, index: 9)
        computeFunctionCompileConstants.setConstantValue(&nucleusEnabledCompileConstant, type: .bool, index: 10)
        
        // Compile functions using current constants
        guard let compute = try? library.makeFunction(name: "compute", constantValues: computeFunctionCompileConstants) else {
            NSLog("Failed to compile compute function")
            return
        }
        guard let verifyCollisions = try? library.makeFunction(name: "verifyCollisions", constantValues: computeFunctionCompileConstants) else {
            NSLog("Failed to compile verifyCollisions function")
            return
        }

        // Set the pipeline states for both functions
        computePipelineState = try? device.makeComputePipelineState(function: compute)
        verifyCollisionsPipelineState = try? device.makeComputePipelineState(function: verifyCollisions)
        
    }

    // MARK: - Initialization

    func initializeMetal() {
        device = MTLCreateSystemDefaultDevice()
        queue = device.makeCommandQueue()
        library = device.makeDefaultLibrary()
        initComputePipelineState(device)
        
        // Create [Float] lists to populate buffers
        
        let initializedTimeJump = [Float](repeating: 0.0, count: Parameters.nbodies)
        let initializedUpdatedTimeJump = [Float](repeating: 0.0, count: Parameters.nbodies)
        let initializedTimeBetweenJumps = [Float](repeating: -1.0, count: Parameters.nbodies)
        
        // Initialize buffers and populate those of them that need it
        
        distancesBuffer = device.makeBuffer(
            length: Parameters.nbodies * MemoryLayout<Float>.stride
        )
        
        timeLastJumpBuffer = device.makeBuffer(
            bytes: initializedTimeJump,
            length: Parameters.nbodies * MemoryLayout<Float>.stride
        )
        
        updatedTimeLastJumpBuffer = device.makeBuffer(
            bytes: initializedUpdatedTimeJump,
            length: Parameters.nbodies * MemoryLayout<Float>.stride
        )
        
        timeBetweenJumpsBuffer = device.makeBuffer(
            bytes: initializedTimeBetweenJumps,
            length: Parameters.nbodies * MemoryLayout<Float>.stride
        )

        var randomSeeds: [Float] = []
        while randomSeeds.count != Parameters.nbodies {
            let number = Float.random(in: 0 ..< 1)
            randomSeeds.append(number)
        }
        randomSeedsInBuffer = device.makeBuffer(
            bytes: randomSeeds,
            length: Parameters.nbodies * MemoryLayout<Float>.stride
        )
        randomSeedsOutBuffer = device.makeBuffer(
            bytes: randomSeeds,
            length: Parameters.nbodies * MemoryLayout<Float>.stride
        )
        
    }
    
    func initializeMetalMTs() {

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
            length: max(1, indexToPoint.count) * MemoryLayout<Int32>.stride
        )
        
        let isAttachedIn: [Int32] = [Int32](repeatElement(-1, count: Parameters.nbodies))
        
        isAttachedInBuffer = device.makeBuffer(
            bytes: isAttachedIn,
            length: isAttachedIn.count * MemoryLayout<Int32>.stride
        )
        
        isAttachedOutBuffer = device.makeBuffer(
            bytes: isAttachedIn,
            length: isAttachedIn.count * MemoryLayout<Int32>.stride
        )
        
        let stepNumbers = [Int32](repeatElement(0, count: Parameters.nbodies))
        
        MTstepNumberInBuffer = device.makeBuffer(
            bytes: stepNumbers,
            length: Parameters.nbodies * MemoryLayout<Int32>.stride
        )
        MTstepNumberOutBuffer = device.makeBuffer(
            bytes: stepNumbers,
            length: Parameters.nbodies * MemoryLayout<Int32>.stride
        )
        
        // Not strictly MT related, but useful to have  cellIDtoIndex.count available
        
        let cellIDtoOccupied = [Int32](repeating: 0, count: cellIDtoNMTs.count)
                
        cellIDtoOccupiedBuffer = device.makeBuffer(
            bytes: cellIDtoOccupied,
            length: cellIDtoOccupied.count * MemoryLayout<Int32>.stride
        )
        
    }
    
    func initializeSimulation() {
        // Spawn the bounding box
        DispatchQueue.main.async {
            self.alertLabel.text = "Drawing bounding box"
            self.alertView.backgroundColor = UIColor.init(cgColor: CGColor(srgbRed: 0.5, green: 0.5, blue: 0.5, alpha: 0.5))
        }
        let boundingBoxNode = spawnBoundingBox()
        scene.rootNode.addChildNode(boundingBoxNode)
        
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
        if Parameters.nucleusEnabled {
            nucleus = spawnCellNucleus()
            scene.rootNode.addChildNode(nucleus)
        }
        
        // Spawn the microtubules
        DispatchQueue.main.async {
            self.alertLabel.text = "Generating microtubule structure"
        }

        let microtubuleSpawner = MicrotubuleSpawner(alertLabel: alertLabel,
                                                    scene: scene,
                                                    computeTabViewController: thirdChildTabVC)
        let (microtubules,
             microtubulePointsReturned,
             microtubuleNSegmentsReturned,
             microtubulePointsArrayReturned) = microtubuleSpawner.spawnAllMicrotubules(microtubulePointsArray: &microtubulePointsArray,
                                                                                       cellIDDict: &cellIDDict,
                                                                                       cellIDtoIndex: &cellIDtoIndex,
                                                                                       cellIDtoNMTs: &cellIDtoNMTs,
                                                                                       indexToPoint: &indexToPoint)

        microtubulePoints = microtubulePointsReturned
        microtubuleNSegments = microtubuleNSegmentsReturned
        microtubulePointsArray = microtubulePointsArrayReturned

        // Create MTLBuffers that require MT data
        initializeMetalMTs()

        // Compute initial mtPoint distances
        for microtubulePoint in microtubulePoints {
            microtubuleDistances.append(sqrt(microtubulePoint.x*microtubulePoint.x
                                                + microtubulePoint.y*microtubulePoint.y
                                                + microtubulePoint.z*microtubulePoint.z))
        }
        self.secondChildTabVC?.setHistogramData3(cellRadius: Parameters.cellRadius, points: microtubulePoints)
        
        // Spawn particles
        DispatchQueue.main.async {
            self.alertLabel.text = "Initializing all particle positions"
        }
        var pointsNodeList: [SCNNode] = []
        
        let meshData = MetalMeshDeformable.initializePoints(device,
                                                            nbodies: Parameters.nbodies,
                                                            nBodiesPerCell: Parameters.nbodies/Parameters.nCells,
                                                            cellRadius: Parameters.cellRadius)
        positionsIn = meshData.vertexBuffer1
        positionsOut = meshData.vertexBuffer2
        
        let pointsNode = SCNNode(geometry: meshData.geometry)
        pointsNode.geometry?.firstMaterial?.diffuse.contents = UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
        pointsNode.geometry?.firstMaterial?.transparency = 1.0 // 0.7
        pointsNode.geometry?.firstMaterial?.lightingModel = .constant
        pointsNode.geometry?.firstMaterial?.writesToDepthBuffer = false
        pointsNode.geometry?.firstMaterial?.readsFromDepthBuffer = true
        // pointsNode.geometry?.firstMaterial?.blendMode = SCNBlendMode.add
                    
        pointsNodeList.append(pointsNode)
        
        scene.rootNode.addChildNode(pointsNode)
        
        // Animate the 3d object
        boundingBoxNode.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 2, z: 0, duration: rotationTime)))
        for membrane in membranes {
            membrane.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 2, z: 0, duration: rotationTime)))
        }
        for pointsNode in pointsNodeList {
            pointsNode.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 2, z: 0, duration: rotationTime)))
        }
        for microtubule in microtubules {
            microtubule.geometry?.firstMaterial?.lightingModel = .constant
            microtubule.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 2, z: 0, duration: rotationTime)))
        }
        if Parameters.nucleusEnabled {
            nucleus.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 2, z: 0, duration: rotationTime)))
        }
        
        // Set renderer delegate to start animation loop
        DispatchQueue.main.async {
            self.alertLabel.text = ""
            self.alertView.backgroundColor = UIColor.clear
        }
        scnView.delegate = self
        
        // Set simulation start time
        startTime = NSDate.now

        // Signal that simulation has been initialized
        isInitialized = true

        // Disable truePause unless the UI is displaying the play button so metalLoop() can start
        if hasUIPause {
            truePause = true
        } else {
            truePause = false
        }

        // Check that the compute and verify collisions pipelines have been created successfully

        guard computePipelineState != nil else {
            DispatchQueue.main.async {
                let fatalAlert = FatalCrashAlertController(title: "Fatal error",
                                                           message: "Failed to compile compute GPU function",
                                                           preferredStyle: .alert)
                self.present(fatalAlert, animated: true, completion: nil)
            }
            return
        }

        guard verifyCollisionsPipelineState != nil else {
            DispatchQueue.main.async {
                let fatalAlert = FatalCrashAlertController(title: "Fatal error",
                                                           message: "Failed to compile collisions GPU function",
                                                           preferredStyle: .alert)
                self.present(fatalAlert, animated: true, completion: nil)
            }
            return
        }

        // Reset simulation time
        Parameters.time = 0

        // Start simulation loop
        DispatchQueue.global(qos: .default).async {
            self.metalLoop()
        }
    }

    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Compute global variables
        computeDeltaT()

        // Initialize tabs viewcontrollers
        let firstChildTabStoryboard = UIStoryboard(name: "ParametersViewController", bundle: nil)
        self.firstChildTabVC = firstChildTabStoryboard.instantiateViewController(withIdentifier: "ParametersViewController")
            as? ParametersViewController
        self.firstChildTabVC?.mainController = self

        self.secondChildTabVC = self.storyboard?.instantiateViewController(withIdentifier: "GraphsViewController") as? GraphsViewController

        self.thirdChildTabVC = self.storyboard?.instantiateViewController(withIdentifier: "ComputeViewController") as? ComputeViewController

        // Initialize Metal for GPU calculations
        initializeMetal()
                
        // Create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 5*Parameters.cellRadius, z: 5*Parameters.cellRadius)
        scene.rootNode.addChildNode(lightNode)
        
        // Create and add a camera to the scene
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.focalLength = 50.0
        cameraNode.camera?.zFar = 500000
        scene.rootNode.addChildNode(cameraNode)
        
        // Place the camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 7*Parameters.cellRadius)
        
        // Create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = UIColor.darkGray
        scene.rootNode.addChildNode(ambientLightNode)
        
        // Set the scene to the view
        scnView.scene = scene
        
        // Allows the user to manipulate the camera
        scnView.allowsCameraControl = true
        
        // Show statistics such as fps and timing information
        scnView.showsStatistics = true
        
        // Configure the view
        scnView.backgroundColor = UIColor.black
        scnContainer.backgroundColor = UIColor.black
                
        // Finish UI configuration
        
        let blurEffect = UIBlurEffect(style: .systemThickMaterial)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = self.topBarBackground.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        topBarBackground.addSubview(blurEffectView)
        
        buttonContainerView.layer.cornerRadius = 7.5
        alertView.layer.cornerRadius = 7.5
        alertView.backgroundColor = UIColor.clear
        
        segmentedControl.selectedSegmentIndex = TabIndex.firstChildTab.rawValue
        displayCurrentTab(TabIndex.firstChildTab.rawValue)

        segmentedControl.isSelected = true

        // UI changes for macOS
        if UIDevice.current.userInterfaceIdiom == .mac {
            sidebarWidthConstraint.constant = 300 // May be configured to be narrower in the future
        }

        // Register for notifications from parameter input errors
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didReceiveInputError(notification:)),
                                               name: .inputErrorNotification,
                                               object: nil)
        
        // Initialize the simulation
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

    // MARK: - Functions

    func restartSimulation(timeout: Int = 10) {
        // Check that the simulation has been initialized
        guard isInitialized else { return }
        // Signal initialization as not completed before restart
        isInitialized = false
        // Signal metalLoop to pause
        truePause = true
        // Wait, timeout if too much time passes
        let startTime = Int(Date.timeIntervalSinceReferenceDate)
        while isRunning {
            let currentTime = Int(Date.timeIntervalSinceReferenceDate)
            if  (currentTime - startTime) > timeout {
                return
            }
        }
        // Clear all graphs
        secondChildTabVC?.clearAllGraphs(self)
        // Clear the scene
        scene.rootNode.enumerateChildNodes { (node, _) in
            node.removeFromParentNode()
        }
        // Reset MT arrays and dicts
        microtubuleDistances = []
        microtubulePoints = []
        microtubuleNSegments = []
        microtubulePointsArray = []
        cellIDDict = [Int: [Int]]()
        cellIDtoIndex = []
        cellIDtoNMTs = []
        indexToPoint = []
        // Apply new parameter values
        applyNewParameters()
        // Notify ParametersViewController of the changes
        firstChildTabVC?.reloadParameters()
        // Restart simulation
        initializeMetal()
        initializeSimulation()
    }
    
    // MARK: - Metal loop
    
    // Define a struct of parameters to be passed to the kernel function in Metal
    struct SimulationParameters {
        var wON: Float32
        var wOFF: Float
        var n_w: Float
        var boundaryConditions: Int32
        var molecularMotors: Int32
        var nucleusRadius: Float
        var nucleusLocation: simd_float3
        var time: Float
    }
    
    func metalUpdater() {
        
        // Create simulationParameters struct
        
        var simulationParametersObject = SimulationParameters(wON: Parameters.wON,
                                                              wOFF: Parameters.wOFF,
                                                              n_w: Parameters.n_w,
                                                              boundaryConditions: Parameters.boundaryConditions,
                                                              molecularMotors: Parameters.molecularMotors,
                                                              nucleusRadius: Parameters.nucleusRadius,
                                                              nucleusLocation: simd_float3(Parameters.nucleusLocation),
                                                              time: Parameters.time)
        
        // Reset the buffers if required, wait until the buffer is not being read by the plotting functions
        if resetArrivalTimesRequired && !isBusy2 {
            
            let initializedTimeJump = [Float](repeating: 0.0, count: Parameters.nbodies)
            let initializedUpdatedTimeJump = [Float](repeating: 0.0, count: Parameters.nbodies)
            let initializedTimeBetweenJumps = [Float](repeating: -1.0, count: Parameters.nbodies)
            
            timeLastJumpBuffer = device.makeBuffer(
                bytes: initializedTimeJump,
                length: Parameters.nbodies * MemoryLayout<Float>.stride
            )
            
            updatedTimeLastJumpBuffer = device.makeBuffer(
                bytes: initializedUpdatedTimeJump,
                length: Parameters.nbodies * MemoryLayout<Float>.stride
            )
            
            timeBetweenJumpsBuffer = device.makeBuffer(
                bytes: initializedTimeBetweenJumps,
                length: Parameters.nbodies * MemoryLayout<Float>.stride
            )
            
            resetArrivalTimesRequired = false
        }
        
        // Update MTLBuffers thorugh compute pipeline
            
        buffer = queue?.makeCommandBuffer()
            
        // Compute kernel
        let threadsPerArray = MTLSizeMake(Parameters.nbodies, 1, 1)
        let groupsize = MTLSizeMake(computePipelineState!.maxTotalThreadsPerThreadgroup, 1, 1)
        // let groupsize = MTLSizeMake(64, 1, 1)
        
        let computeEncoder = buffer!.makeComputeCommandEncoder()
          
        computeEncoder?.setComputePipelineState(computePipelineState!)

        computeEncoder?.setBuffer(positionsIn, offset: 0, index: 0)
        computeEncoder?.setBuffer(positionsOut, offset: 0, index: 1)
        computeEncoder?.setBuffer(distancesBuffer, offset: 0, index: 2)
        computeEncoder?.setBuffer(timeLastJumpBuffer, offset: 0, index: 3)
        computeEncoder?.setBuffer(updatedTimeLastJumpBuffer, offset: 0, index: 4)
        computeEncoder?.setBuffer(timeBetweenJumpsBuffer, offset: 0, index: 5)
        computeEncoder?.setBuffer(microtubulePointsBuffer, offset: 0, index: 6)
        computeEncoder?.setBuffer(cellIDtoIndexBuffer, offset: 0, index: 7)
        computeEncoder?.setBuffer(cellIDtoNMTsBuffer, offset: 0, index: 8)
        computeEncoder?.setBuffer(indextoPointsBuffer, offset: 0, index: 9)
        computeEncoder?.setBuffer(isAttachedInBuffer, offset: 0, index: 10)
        computeEncoder?.setBuffer(isAttachedOutBuffer, offset: 0, index: 11)
        computeEncoder?.setBuffer(randomSeedsInBuffer, offset: 0, index: 12)
        computeEncoder?.setBuffer(randomSeedsOutBuffer, offset: 0, index: 13)
        computeEncoder?.setBuffer(MTstepNumberInBuffer, offset: 0, index: 14)
        computeEncoder?.setBuffer(MTstepNumberOutBuffer, offset: 0, index: 15)
        
        computeEncoder?.setBytes(&simulationParametersObject, length: MemoryLayout<SimulationParameters>.stride, index: 16)
        computeEncoder?.dispatchThreads(threadsPerArray, threadsPerThreadgroup: groupsize)
          
        computeEncoder?.endEncoding()
        buffer!.commit()
        
        // Check wether to do collision handling
        if Parameters.collisionsFlag {
                        
            buffer = queue?.makeCommandBuffer()
            let threadsPerArrayCollisions = MTLSizeMake(Parameters.nCells, 1, 1)
            let verifyCollisionsEncoder = buffer!.makeComputeCommandEncoder()
            
            verifyCollisionsEncoder?.setComputePipelineState(verifyCollisionsPipelineState!)
            verifyCollisionsEncoder?.setBuffer(positionsIn, offset: 0, index: 0)
            verifyCollisionsEncoder?.setBuffer(positionsOut, offset: 0, index: 1)
            verifyCollisionsEncoder?.setBuffer(isAttachedInBuffer, offset: 0, index: 2)
            verifyCollisionsEncoder?.setBuffer(isAttachedOutBuffer, offset: 0, index: 3)
            verifyCollisionsEncoder?.setBuffer(cellIDtoOccupiedBuffer, offset: 0, index: 4)
            verifyCollisionsEncoder?.setBuffer(distancesBuffer, offset: 0, index: 5)
            
            verifyCollisionsEncoder?.setBytes(&simulationParametersObject, length: MemoryLayout<SimulationParameters>.stride, index: 6)
            
            verifyCollisionsEncoder?.dispatchThreads(threadsPerArrayCollisions, threadsPerThreadgroup: groupsize)
            
            verifyCollisionsEncoder?.endEncoding()
            buffer!.commit()
            
        } else {
            swap(&positionsIn, &positionsOut)
            swap(&isAttachedInBuffer, &isAttachedOutBuffer)
        }
        
        // Swap in/out arrays
                
        swap(&timeLastJumpBuffer, &updatedTimeLastJumpBuffer)
        swap(&randomSeedsInBuffer, &randomSeedsOutBuffer)
        swap(&MTstepNumberInBuffer, &MTstepNumberOutBuffer)

        // Update simulation time

        Parameters.time += Parameters.deltat / Float(Parameters.stepsPerMTPoint)

        // Asynchronously launch histogram computations if not already running
        
        let distances = distancesBuffer!.contents().assumingMemoryBound(to: Float.self)
        let timeJumps = timeBetweenJumpsBuffer!.contents().assumingMemoryBound(to: Float.self)
        let attachState = isAttachedInBuffer!.contents().assumingMemoryBound(to: Int32.self)
        
        if !self.isBusy1 {
            self.isBusy1 = true
            queue1.async {
                self.secondChildTabVC?.setHistogramData1(cellRadius: Parameters.cellRadius,
                                                         distances: distances,
                                                         nBodies: Parameters.nbodies,
                                                         attachState: attachState)
                DispatchQueue.main.sync {
                    self.isBusy1 = false
                }
            }
        }
        
        if !self.isBusy2 && !self.resetArrivalTimesRequired {
            self.isBusy2 = true
            queue2.async {
                self.secondChildTabVC?.setHistogramData2(cellRadius: Parameters.cellRadius, distances: timeJumps, nBodies: Parameters.nbodies)
                DispatchQueue.main.sync {
                    self.isBusy2 = false
                }
            }
        }
        
        if !self.isBusy3 {
            self.isBusy3 = true
            queue3.async {
                self.secondChildTabVC?.setHistogramData3(cellRadius: Parameters.cellRadius, points: self.microtubulePoints)
                DispatchQueue.main.sync {
                    self.isBusy3 = false
                }
            }
        }
        
        if !self.isBusy4 {
            self.isBusy4 = true
            queue4.async {
                self.secondChildTabVC?.setHistogramData4(cellRadius: Parameters.cellRadius, counts: self.microtubuleNSegments)
                DispatchQueue.main.sync {
                    self.isBusy4 = false
                }
            }
        }
        
        // Every 1000 steps, clean the random numbers re-seeding them from Swift
        if !self.isBusyRandomSeed && (stepCounter % 1000 == 0) {
            self.isBusyRandomSeed = true
            queueRandomSeed.async {
                let randomBufferToSwift = self.randomSeedsInBuffer!.contents().assumingMemoryBound(to: Float.self)
                for i in 0..<Parameters.nbodies {
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

    // MARK: - Other
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        DispatchQueue.main.async {
            let fatalAlert = FatalCrashAlertController(title: "Low memory",
                                                       message: "The application is running out of memory. "
                                                       + "Try lowering the number of cells or particles",
                                                       preferredStyle: .alert)
            self.present(fatalAlert, animated: true, completion: nil)
        }
    }
    
}

extension GameViewController: SCNSceneRendererDelegate {
    
  func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
    // Do things on SceneKit render loop
  }
    
}
