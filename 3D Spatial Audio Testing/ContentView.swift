//
//  ContentView.swift
//  3D Spatial Audio Testing
//
//  Created by Tom Gansa on 2/20/25.
//



// File: 3D Spatial Audio Testing/ContentView.swift

import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var audioPlayer = SpatialAudioPlayer()
    @State private var selectedTestSound: TestSound = .voice
    
    enum TestSound: String, CaseIterable, Identifiable {
        case voice = "Voice"
        case beep = "Beep"
        case piano = "Piano"
        
        var id: String { self.rawValue }
        
        var filename: String {
            switch self {
            case .voice: return "voice_test"
            case .beep: return "beep_test"
            case .piano: return "piano_test"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 25) {
            Text("3D Spatial Audio Testing")
                .font(.largeTitle)
                .padding()
            
            //compass
            ZStack {
                // bg circle
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                    .frame(width: 280, height: 280)
                
                // buttons for each cardinal direction
                ForEach(0..<8) { index in
                    let angle = Double(index) * 45.0
                    let direction = getDirectionForAngle(angle)
                    
                    Button(action: {
                        playFromDirection(direction)
                    }) {
                        Text(getDirectionLabel(angle))
                            .padding(10)
                            .background(Circle().fill(Color.blue.opacity(0.2)))
                            .frame(width: 45, height: 45)
                    }
                    .disabled(audioPlayer.isPlaying)
                    .position(
                        x: 140 + 110 * sin(angle * .pi / 180),
                        y: 140 - 110 * cos(angle * .pi / 180)
                    )
                }
                
                // stop curr audio button
                Button(action: {
                    audioPlayer.stopAllAudio()
                }) {
                    Label("Stop", systemImage: "stop.fill")
                        .padding()
                        .background(Circle().fill(Color.red.opacity(0.2)))
                }
                .disabled(!audioPlayer.isPlaying)
            }
            .frame(height: 300)
            
            //sound selector
            Picker("Test Sound", selection: $selectedTestSound) {
                ForEach(TestSound.allCases) { sound in
                    Text(sound.rawValue).tag(sound)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .padding()
    }
    
    private func getDirectionLabel(_ angle: Double) -> String {
        switch angle {
        case 0: return "N"
        case 45: return "NE"
        case 90: return "E"
        case 135: return "SE"
        case 180: return "S"
        case 225: return "SW"
        case 270: return "W"
        case 315: return "NW"
        default: return ""
        }
    }
    
    private func getDirectionForAngle(_ angle: Double) -> SpatialAudioPlayer.CardinalDirection {
        switch angle {
        case 0: return .north
        case 45: return .northEast
        case 90: return .east
        case 135: return .southEast
        case 180: return .south
        case 225: return .southWest
        case 270: return .west
        case 315: return .northWest
        default: return .north
        }
    }
    
    private func playFromDirection(_ direction: SpatialAudioPlayer.CardinalDirection) {
        let filename = selectedTestSound.filename
        let url = Bundle.main.url(forResource: filename, withExtension: "mp3")
        print("Looking for audio file: \(filename).mp3, found: \(url != nil)")
        
        if let audioURL = url {
            audioPlayer.playAudioFromCardinalDirection(audioURL: audioURL, cardinalDirection: direction)
        } else {
            print("Error: Could not find audio file: \(filename).mp3")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
