//
//  HumanRectanglesViewController.swift
//  dx-arvr-poc
//
//  Created by APPLAUDO on 10/8/22.
//

import AVFoundation
import UIKit
import Vision

class HumanRectanglesViewController: UIViewController {
    
    private let captureSession = AVCaptureSession()
    private let videoDataOutput = AVCaptureVideoDataOutput()
    
    private lazy var previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
    private var humanRectanglesLayers: [CAShapeLayer] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCamera()
        captureSession.startRunning()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = view.frame
    }
    
    private func setupCamera() {
        
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .back)
        
        guard let device = deviceDiscoverySession.devices.first, let deviceInput = try? AVCaptureDeviceInput(device: device) else {
            return
        }
        
        if captureSession.canAddInput(deviceInput) {
            captureSession.addInput(deviceInput)
            setupPreview()
        }
    }
    
    private func setupPreview() {
        
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
        
        videoDataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_32BGRA)] as [String : Any]
        
        videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "cameraQueue"))
        captureSession.addOutput(videoDataOutput)
        
        let videoConnection = videoDataOutput.connection(with: .video)
        videoConnection?.videoOrientation = .portrait
    }
}

extension HumanRectanglesViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        let humanRectanglesRequest = VNDetectHumanRectanglesRequest(completionHandler: { (request: VNRequest, error: Error?) in
            DispatchQueue.main.async {
                self.humanRectanglesLayers.forEach({ drawing in drawing.removeFromSuperlayer() })
                
                if let observations = request.results as? [VNHumanObservation] {
                    self.handleHumanObservations(observations: observations)
                }
            }
        })
        
        // Capture Whole Body
        humanRectanglesRequest.upperBodyOnly = false
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: imageBuffer, orientation: .leftMirrored, options: [:])
        do {
            try imageRequestHandler.perform([humanRectanglesRequest])
        } catch {
            print(error.localizedDescription)
        }
    }
    
    private func handleHumanObservations(observations: [VNHumanObservation]) {
        for observation in observations {
            let humanRectConverted = previewLayer.layerRectConverted(fromMetadataOutputRect: observation.boundingBox)
            let humanRectanglePath = CGPath(rect: humanRectConverted, transform: nil)
            
            let boxLayer = CAShapeLayer()
            boxLayer.path = humanRectanglePath
            boxLayer.fillColor = UIColor.clear.cgColor
            boxLayer.strokeColor = UIColor.yellow.cgColor
            
            humanRectanglesLayers.append(boxLayer)
            view.layer.addSublayer(boxLayer)
        }
    }
}
