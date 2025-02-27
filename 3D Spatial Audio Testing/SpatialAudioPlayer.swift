import AVFoundation
import CoreLocation
import Combine

class SpatialAudioPlayer: ObservableObject {
    
    @Published var isPlaying = false
    private let audioEnvironment = AVAudioEnvironmentNode()
    private let audioEngine = AVAudioEngine()
    private var mixerNode: AVAudioMixerNode?
    private var activePlayerNodes: [AVAudioPlayerNode] = []
    
    init() {
        setupAudioSession()
        setupAudioEngine()
        print("Current route outputs: \(AVAudioSession.sharedInstance().currentRoute.outputs.map { $0.portType })")
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            
            // Use default mode with multichannel content support
            try audioSession.setCategory(.playback, mode: .default)
            
            if #available(iOS 15.0, *) {
                // Enable spatial audio if available
                try audioSession.setSupportsMultichannelContent(true)
            }
            
            try audioSession.setActive(true)
            print("Audio session activated with category: \(audioSession.category), mode: \(audioSession.mode)")
        } catch {
            print("Failed to set up audio session: \(error.localizedDescription)")
        }
    }
    
    private func setupAudioEngine() {
        // Set up the audio engine
        let mainMixer = audioEngine.mainMixerNode
        mixerNode = AVAudioMixerNode()
        
        guard let mixerNode = mixerNode else { return }
        
        // First attach all nodes before connecting them
        audioEngine.attach(audioEnvironment)
        audioEngine.attach(mixerNode)
        
        // Configure the audio environment for better spatial audio
        audioEnvironment.renderingAlgorithm = .equalPowerPanning
        audioEnvironment.distanceAttenuationParameters.distanceAttenuationModel = .exponential
        audioEnvironment.distanceAttenuationParameters.referenceDistance = 0.5
        audioEnvironment.distanceAttenuationParameters.maximumDistance = 5.0
        
        // Now connect the nodes after they're all attached
        audioEngine.connect(audioEnvironment, to: mainMixer, format: mainMixer.outputFormat(forBus: 0))
        audioEngine.connect(mixerNode, to: audioEnvironment, format: mixerNode.outputFormat(forBus: 0))
        
        do {
            try audioEngine.start()
            print("Audio engine started successfully")
        } catch {
            print("Could not start audio engine: \(error.localizedDescription)")
        }
    }
    
    /// Plays audio from a specific direction
    /// - Parameters:
    ///   - audioURL: URL of the audio file to play
    ///   - direction: Direction in degrees (0° = North, 90° = East, 180° = South, 270° = West)
    ///   - distance: Optional distance parameter (1.0 = default distance)
    func playAudioFromDirection(audioURL: URL, direction: Double, distance: Float = 1.0) {
        guard let mixerNode = mixerNode else { return }
        
        // Convert direction to radians
        let directionRadians = direction * Double.pi / 180.0
        
        // Calculate x and y coordinates based on direction and distance
        // Using a unit circle where North is at (0,1), East at (1,0), etc.
        let x = Float(sin(directionRadians)) * distance * 2.0
        let y = Float(cos(directionRadians)) * distance * 2.0

        // Make sure the AVAudioEnvironmentNode is properly set
        audioEnvironment.outputType = .headphones  // Force headphone output mode
        audioEnvironment.renderingAlgorithm = .HRTF 
        
        // Debug positioning
        print("Playing spatial audio with position: x=\(x), y=0, z=\(y) for direction \(direction)° at distance \(distance)")
        
        do {
            // Create and configure audio player source
            let audioFile = try AVAudioFile(forReading: audioURL)
            let audioFormat = audioFile.processingFormat
            
            print("Audio format: \(audioFormat.description)")
            
            // Create player node
            let playerNode = AVAudioPlayerNode()
            audioEngine.attach(playerNode)
            audioEngine.connect(playerNode, to: mixerNode, format: audioFormat)
            activePlayerNodes.append(playerNode)
            
            // Set the position in 3D space
            // Using (x, 0, y) - keeping height (y-axis in 3D space) at 0
            audioEnvironment.listenerPosition = AVAudio3DPoint(x: 0, y: 0, z: 0)
            audioEnvironment.listenerAngularOrientation = AVAudio3DAngularOrientation(yaw: 0, pitch: 0, roll: 0)
            playerNode.position = AVAudio3DPoint(x: 4, y: 0, z: 0)
            
            // Prepare and play audio
            playerNode.scheduleFile(audioFile, at: nil) {
                // Audio finished playing callback
                DispatchQueue.main.async {
                    if let index = self.activePlayerNodes.firstIndex(of: playerNode) {
                        self.activePlayerNodes.remove(at: index)
                    }
                    self.audioEngine.detach(playerNode)
                    if self.activePlayerNodes.isEmpty {
                        self.isPlaying = false
                    }
                }
            }
            
            isPlaying = true
            playerNode.play()
            
        } catch {
            print("Error playing spatial audio: \(error.localizedDescription)")
        }
    }
    
    /// Convenience method to play audio from cardinal directions
    /// - Parameters:
    ///   - audioURL: URL of the audio file to play
    ///   - cardinalDirection: Cardinal direction (north, east, south, west)
    ///   - distance: Optional distance parameter
    func playAudioFromCardinalDirection(audioURL: URL, cardinalDirection: CardinalDirection, distance: Float = 1.0) {
        let directionDegrees: Double
        
        switch cardinalDirection {
        case .north:
            directionDegrees = 0
        case .east:
            directionDegrees = 90
        case .south:
            directionDegrees = 180
        case .west:
            directionDegrees = 270
        case .northEast:
            directionDegrees = 45
        case .southEast:
            directionDegrees = 135
        case .southWest:
            directionDegrees = 225
        case .northWest:
            directionDegrees = 315
        }
        
        playAudioFromDirection(audioURL: audioURL, direction: directionDegrees, distance: distance)
    }
    
    /// Cardinal directions enum
    enum CardinalDirection {
        case north
        case east
        case south
        case west
        case northEast
        case southEast
        case southWest
        case northWest
    }
    
    /// Stops all currently playing audio
    func stopAllAudio() {
        for playerNode in activePlayerNodes {
            playerNode.stop()
            audioEngine.detach(playerNode)
        }
        activePlayerNodes.removeAll()
        isPlaying = false
    }
    
    deinit {
        stopAllAudio()
        audioEngine.stop()
    }
}
