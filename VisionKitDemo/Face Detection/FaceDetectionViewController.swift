//
//  FaceDetectionViewController.swift
//  VisionKitDemo
//
//  Created by sahebroy on 05/01/24.
//

import Foundation
import AVFoundation
import UIKit
import Vision

class FaceDetectionViewController: UIViewController {
    private let captureSession = AVCaptureSession()
    private lazy var previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private var drawings: [CAShapeLayer] = []
    
    
    override func viewDidLoad() {
        addFrontCameraInput()
        showCameraFeed()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        getCameraFrames()
        DispatchQueue.global().async {
            self.captureSession.startRunning()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        DispatchQueue.global().async {
            self.captureSession.stopRunning()
        }
    }
    
    
    private func addFrontCameraInput() {
        guard let device = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTrueDepthCamera],
            mediaType: .video,
            position: .front).devices.first else {
            fatalError("")
        }
        let cameraInput = try! AVCaptureDeviceInput(device: device)
        self.captureSession.addInput(cameraInput)
    }
    
    
    private func addBackCameraInput() {
        guard let device = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTrueDepthCamera],
            mediaType: .video,
            position: .back).devices.first else {
            fatalError("")
        }
        let cameraInput = try! AVCaptureDeviceInput(device: device)
        self.captureSession.addInput(cameraInput)
    }
    
    
    private func showCameraFeed() {
        self.previewLayer.videoGravity = .resizeAspectFill
        self.view.layer.addSublayer(self.previewLayer)
        self.previewLayer.frame = self.view.frame
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.previewLayer.frame = self.view.frame
    }
    
    private func getCameraFrames() {
        self.videoDataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_32BGRA)] as [String : Any]
        self.videoDataOutput.alwaysDiscardsLateVideoFrames = true
        self.videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera_frame_processing_queue"))
        self.captureSession.addOutput(self.videoDataOutput)
        guard let connection = self.videoDataOutput.connection(with: AVMediaType.video),
              connection.isVideoOrientationSupported else { return }
        connection.videoOrientation = .portrait
    }
    
    
    private func detectFace(in image: CVPixelBuffer) {
        let faceDetectionRequest = VNDetectFaceLandmarksRequest(completionHandler: { (request: VNRequest, error: Error?) in
            DispatchQueue.main.async {
                if let results = request.results as? [VNFaceObservation] {
                    self.handleFaceDetectionResults(results)
                } else {
                    self.clearDrawings()
                }
            }
        })
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: image, orientation: .leftMirrored, options: [:])
        try? imageRequestHandler.perform([faceDetectionRequest])
    }
    
    
    private func handleFaceDetectionResults(_ observedFaces: [VNFaceObservation]) {
        
        self.clearDrawings()
        let facesBoundingBoxes: [CAShapeLayer] = observedFaces.flatMap({ (observedFace: VNFaceObservation) -> [CAShapeLayer] in
            let faceBoundingBoxOnScreen = self.previewLayer.layerRectConverted(fromMetadataOutputRect: observedFace.boundingBox)
            let faceBoundingBoxPath = CGPath(rect: faceBoundingBoxOnScreen, transform: nil)
            let faceBoundingBoxShape = CAShapeLayer()
            faceBoundingBoxShape.path = faceBoundingBoxPath
            faceBoundingBoxShape.fillColor = UIColor.clear.cgColor
            faceBoundingBoxShape.strokeColor = UIColor.green.cgColor
            var newDrawings = [CAShapeLayer]()
            newDrawings.append(faceBoundingBoxShape)
            if let landmarks = observedFace.landmarks {
                newDrawings = newDrawings + self.drawFaceFeatures(landmarks, screenBoundingBox: faceBoundingBoxOnScreen)
            }
            return newDrawings
        })
        facesBoundingBoxes.forEach({ faceBoundingBox in self.view.layer.addSublayer(faceBoundingBox) })
        self.drawings = facesBoundingBoxes
    }
    
    private func clearDrawings() {
        self.drawings.forEach({ drawing in drawing.removeFromSuperlayer() })
    }
    
    private func drawFaceFeatures(_ landmarks: VNFaceLandmarks2D, screenBoundingBox: CGRect) -> [CAShapeLayer] {
        var faceFeaturesDrawings: [CAShapeLayer] = []
        if let leftEye = landmarks.leftEye {
            let eyeDrawing = self.drawEye(leftEye, screenBoundingBox: screenBoundingBox)
            faceFeaturesDrawings.append(eyeDrawing)
        }
        if let rightEye = landmarks.rightEye {
            let eyeDrawing = self.drawEye(rightEye, screenBoundingBox: screenBoundingBox)
            faceFeaturesDrawings.append(eyeDrawing)
        }
        
        if let leftEyebrow = landmarks.leftEyebrow{
            let eyeBrowDrawing = self.drawEye(leftEyebrow, screenBoundingBox: screenBoundingBox)
            faceFeaturesDrawings.append(eyeBrowDrawing)
        }
        
        if let RightEyebrow = landmarks.rightEyebrow{
            let eyeBrowDrawing = self.drawEye(RightEyebrow, screenBoundingBox: screenBoundingBox)
            faceFeaturesDrawings.append(eyeBrowDrawing)
        }
        
        if let nose = landmarks.nose{
            let noseDrawing = self.drawEye(nose, screenBoundingBox: screenBoundingBox)
            faceFeaturesDrawings.append(noseDrawing)
        }
        
        if let innerLip = landmarks.innerLips{
            let lip = self.drawEye(innerLip, screenBoundingBox: screenBoundingBox)
            faceFeaturesDrawings.append(lip)
        }
        
        if let outerLip = landmarks.outerLips{
            let lip = self.drawEye(outerLip, screenBoundingBox: screenBoundingBox)
            faceFeaturesDrawings.append(lip)
        }
        
        if let leftPupil = landmarks.leftPupil{
            let pupil = self.drawEye(leftPupil, screenBoundingBox: screenBoundingBox)
            faceFeaturesDrawings.append(pupil)
        }
        
        if let RightPupil = landmarks.rightPupil{
            let pupil = self.drawEye(RightPupil, screenBoundingBox: screenBoundingBox)
            faceFeaturesDrawings.append(pupil)
        }
        
        
        return faceFeaturesDrawings
    }
    
    private func drawEye(_ eye: VNFaceLandmarkRegion2D, screenBoundingBox: CGRect) -> CAShapeLayer {
        let eyePath = CGMutablePath()
        let eyePathPoints = eye.normalizedPoints
            .map({ eyePoint in
                CGPoint(
                    x: eyePoint.y * screenBoundingBox.height + screenBoundingBox.origin.x,
                    y: eyePoint.x * screenBoundingBox.width + screenBoundingBox.origin.y)
            })
        
        let newLayer = CAShapeLayer()
        newLayer.strokeColor = UIColor.blue.cgColor
        newLayer.lineWidth = 4.0
        var newVertices = eyePathPoints
        
        newVertices.remove(at: newVertices.count - 1)
        
        eyePath.addLines(between: eyePathPoints)
        eyePath.closeSubpath()
        
        let triangleLayer = CAShapeLayer()
        triangleLayer.path = eyePath
        triangleLayer.strokeColor = UIColor.red.cgColor
        triangleLayer.lineWidth = 1.0
        triangleLayer.lineDashPattern = [5,5]
        triangleLayer.fillColor = UIColor.clear.cgColor
        triangleLayer.backgroundColor = UIColor.clear.cgColor
        triangleLayer.strokeColor = UIColor.white.withAlphaComponent(0.5).cgColor
        return triangleLayer
    }
    
}
extension FaceDetectionViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection) {
            
            guard let frame = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                debugPrint("unable to get image from sample buffer")
                return
            }
            print("frame")
            self.detectFace(in: frame)
        }
}
