//
//  VCSetupSession.swift
//  SIGNSlate
//
//  Created by Sanjay Thakkar on 2022/9/23.
//

import UIKit
import AVFoundation


extension LatingViewController {
    
    public func setupAVSession() throws {
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            throw AppError.captureSessionSetup(
                  reason: "Could not find a front facing camera."
                )
        }
        device.set(frameRate: 30)
        guard let deviceInput = try? AVCaptureDeviceInput(device: device) else {
            throw AppError.captureSessionSetup(
                  reason: "Could not create video device input."
                )
        }
        
        let session = AVCaptureSession()
        session.beginConfiguration()
        session.sessionPreset = .high
        
        guard session.canAddInput(deviceInput) else {
            throw AppError.captureSessionSetup(
                  reason: "Could not add video device input to the session"
                )
        }
        session.addInput(deviceInput)
        
        let dataOutput = AVCaptureVideoDataOutput()
        //dataOutput.alwaysDiscardsLateVideoFrames = true
        if session.canAddOutput(dataOutput) {
            session.addOutput(dataOutput)
            dataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        } else {
            throw AppError.captureSessionSetup(
                  reason: "Could not add video data output to the session"
                )
        }
        for eachCo in dataOutput.connections {
            eachCo.videoOrientation = .portrait
        }
        session.commitConfiguration()
        captureSession = session
    }
}
enum AppError: Error {
  case captureSessionSetup(reason: String)
}
extension AVCaptureDevice {
    func set(frameRate: Double) {
    guard let range = activeFormat.videoSupportedFrameRateRanges.first,
        range.minFrameRate...range.maxFrameRate ~= frameRate
        else {
            print("Requested FPS is not supported by the device's activeFormat !")
            return
    }

    do { try lockForConfiguration()
        activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: Int32(frameRate))
        activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: Int32(frameRate))
        unlockForConfiguration()
    } catch {
        print("LockForConfiguration failed with error: \(error.localizedDescription)")
    }
  }
}
