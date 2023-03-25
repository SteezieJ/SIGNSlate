//
//  VCSetupSession.swift
//  SIGNSlate
//
//  Created by Stefanie Joubert on 2022/9/23.
//

import UIKit
import AVFoundation


extension LatingViewController {
    
    public func setupAVSession() throws {
        
        //setup front and back for ratations
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: devicePosition) else {
            throw AppError.captureSessionSetup(
                  reason: "Could not find a front facing camera."
                )
        }
        device.set(frameRate: 15)
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
    func updateCamera() {
        captureSession?.stopRunning()
        if devicePosition == .back {
            devicePosition = .front
        } else {
            devicePosition = .back
        }
        do {
            try setupAVSession()
        } catch {
            print(error.localizedDescription)
        }
        cameraView.previewLayer.session = captureSession
        cameraView.previewLayer.videoGravity = .resizeAspectFill
        captureSession?.startRunning()
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
