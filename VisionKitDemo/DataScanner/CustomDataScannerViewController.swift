//
//  DataScannerViewController.swift
//  VisionKitDemo
//
//  Created by sahebroy on 05/01/24.
//

import VisionKit
import UIKit
import QKMRZParser

class CustomDataScannerViewController: UIViewController {

    let parser = QKMRZParser(ocrCorrection: true)
    let scanner = DataScannerViewController(recognizedDataTypes: [
        .barcode(symbologies: [.qr, .ean13, .pdf417 ]),
        .text(languages:["en"]),
        .text(textContentType: .telephoneNumber)
    ], qualityLevel: .balanced, recognizesMultipleItems: true, isHighFrameRateTrackingEnabled: true, isPinchToZoomEnabled: true, isGuidanceEnabled: true, isHighlightingEnabled: true)
    
    var foundMRZDoc : Document?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureDataScanner()
    }
    
    func configureDataScanner() {
        scanner.delegate = self
        present(scanner, animated: true) {
            try? self.scanner.startScanning()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? ResultViewController, let doc = foundMRZDoc {
            vc.allDocuments = [doc]
        }
    }
    
    func checkForMRZ(_ recognisedText: String) {
        var document = Document.init(image: nil, data: recognisedText, primaryLanguage: "")
        if let result = self.parser.parse(mrzString: document.data) {
            document.isDocument = result
            foundMRZDoc = document
            scanner.stopScanning()
            scanner.dismiss(animated: true) {
                self.performSegue(withIdentifier: "ResultViewControllerFromData", sender: self)
            }
        }
    }
}


extension CustomDataScannerViewController: DataScannerViewControllerDelegate {
    func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
        switch item {
        case .text(let recognisedText):
            print(recognisedText.transcript)
            print(recognisedText.observation.confidence)
            checkForMRZ(recognisedText.transcript)
        case .barcode(let recognisedBarCode):
            print(recognisedBarCode.payloadStringValue ?? "")
            print(recognisedBarCode.observation.symbology.rawValue)
            
            if let recognisedText = recognisedBarCode.payloadStringValue {
                checkForMRZ(recognisedText)
            }
            
        @unknown default:
            print("Couldnt scan---")
        }
    }
}
