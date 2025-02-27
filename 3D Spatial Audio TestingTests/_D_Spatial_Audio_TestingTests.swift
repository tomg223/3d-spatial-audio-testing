//
//  _D_Spatial_Audio_TestingTests.swift
//  3D Spatial Audio TestingTests
//
//  Created by Tom Gansa on 2/20/25.
//

import XCTest
@testable import _D_Spatial_Audio_Testing

final class SpatialAudioTestingTests: XCTestCase {
    var audioPlayer: SpatialAudioPlayer!
    
    override func setUpWithError() throws {
        audioPlayer = SpatialAudioPlayer()
    }
    
    override func tearDownWithError() throws {
        audioPlayer.stopAllAudio()
        audioPlayer = nil
    }
    
    func testSpatialAudioPlayerInitialization() throws {
        XCTAssertNotNil(audioPlayer)
    }
}
