//
//  DataScannerViewController.swift
//  VisionKitDemo
//
//  Created by sahebroy on 05/01/24.
//

import VisionKit
import UIKit
import QKMRZParser
import NaturalLanguage

class CustomDataScannerViewController: UIViewController {
    var roundBoxMappings: [UUID: UIView] = [:]
    let parser = QKMRZParser(ocrCorrection: true)
    let scanner = DataScannerViewController(recognizedDataTypes: [
        .barcode(symbologies: [.qr, .ean13, .pdf417 ]),
        .text(languages:["en-US","en-UK"])
    ], qualityLevel: .balanced, recognizesMultipleItems: true, isHighFrameRateTrackingEnabled: true, isPinchToZoomEnabled: true, isGuidanceEnabled: true, isHighlightingEnabled: true)
    
    var foundMRZDoc : Document?
    var customisOn = true
    
    lazy var startCamera : UIButton = {
       let button = UIButton()
        button.setTitle("Start Data Scanning", for: .normal)
        button.addTarget(self, action: #selector(startCameraAction), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    
    lazy var customHighlight : UISwitch = {
       let sw = UISwitch()
        sw.isOn = true
        sw.addTarget(self, action: #selector(toggleCustomHighlight), for: .valueChanged)
        sw.translatesAutoresizingMaskIntoConstraints = false
        return sw
    }()
    
    lazy var lbl : UILabel = {
       let label = UILabel()
        label.text = "Custom Highlight Toggle"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var stack : UIStackView = {
       let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 25
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addScannerButton()
    }
    
    @objc func toggleCustomHighlight() {
        customisOn = customHighlight.isOn
    }
    
    @objc func startCameraAction() {
        scanner.delegate = self
        present(scanner, animated: true) {
            try? self.scanner.startScanning()
        }
    }
    
    func addScannerButton() {
        view.addSubview(startCamera)
        view.addSubview(stack)
        stack.addArrangedSubview(customHighlight)
        stack.addArrangedSubview(lbl)
        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: startCamera, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: startCamera, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: stack, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: stack, attribute: .top, relatedBy: .equal, toItem: startCamera, attribute: .bottom, multiplier: 1.0, constant: 20)
        
        ])
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

    func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
        processAddedItems(items: addedItems)
    }
    
    func dataScanner(_ dataScanner: DataScannerViewController, didRemove removedItems: [RecognizedItem], allItems: [RecognizedItem]) {
        processRemovedItems(items: removedItems)
    }
    
    func dataScanner(_ dataScanner: DataScannerViewController, didUpdate updatedItems: [RecognizedItem], allItems: [RecognizedItem]) {
        processUpdatedItems(items: updatedItems)
    }
    
    func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
        processItem(item: item)
    }
    
    func processAddedItems(items: [RecognizedItem]) {
        for item in items {
            processItem(item: item)
        }
    }
    
    func processRemovedItems(items: [RecognizedItem]) {
        for item in items {
            removeRoundBoxFromItem(item: item)
        }
    }
    
    func processUpdatedItems(items: [RecognizedItem]) {
        for item in items {
            updateRoundBoxToItem(item: item)
        }
    }
    
    func processItem(item: RecognizedItem) {
        switch item {
        case .text(let text):
            print("Text Observation - \(text.observation)")
            print("Text transcript - \(text.transcript)")
            if customisOn {
                let frame = getRoundBoxFrame(item: item)
                // Adding the round box overlay to detected text
                addRoundBoxToItem(frame: frame, text: text.transcript, item: item)
                checkForMRZ(text.transcript)
            }
            
        case .barcode(let barcode):
            let frame = getRoundBoxFrame(item: item)
            addRoundBoxToItem(frame: frame, text: barcode.payloadStringValue ?? "", item: item)
            break
        @unknown default:
            print("Should not happen")
        }
    }
    
    func addRoundBoxToItem(frame: CGRect, text: String, item: RecognizedItem) {
        //let roundedRectView = RoundRectView(frame: frame)
        let roundedRectView = HighlightView(frame: frame)
        roundedRectView.setText(text: text)
        scanner.overlayContainerView.addSubview(roundedRectView)
        roundBoxMappings[item.id] = roundedRectView
    }
    
    func removeRoundBoxFromItem(item: RecognizedItem) {
        if let roundBoxView = roundBoxMappings[item.id] {
            if roundBoxView.superview != nil {
                roundBoxView.removeFromSuperview()
                roundBoxMappings.removeValue(forKey: item.id)
            }
        }
    }
    
    func updateRoundBoxToItem(item: RecognizedItem) {
        if let roundBoxView = roundBoxMappings[item.id] {
            if roundBoxView.superview != nil {
                let frame = getRoundBoxFrame(item: item)
                roundBoxView.frame = frame
            }
        }
    }
    
    func getRoundBoxFrame(item: RecognizedItem) -> CGRect {
        let frame = CGRect(
            x: item.bounds.topLeft.x,
            y: item.bounds.topLeft.y,
            width: abs(item.bounds.topRight.x - item.bounds.topLeft.x) + 15,
            height: abs(item.bounds.topLeft.y - item.bounds.bottomLeft.y) + 15
        )
        return frame
    }
}

class HighlightView: UIView {
    let label = UILabel()
    let cornerRadius: CGFloat = 5.0
    let padding: CGFloat = 5
    var text: String = ""
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        // Configure the label
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 10)
        label.textAlignment = .left
        label.numberOfLines = 0
        label.text = text
        label.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(label)
        
        // Add constraints for the label
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: padding),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -padding)
        ])
        
        // Configure the background
        backgroundColor = .red
        layer.cornerRadius = cornerRadius
        layer.opacity = 0.60
    }
    
    func setText(text: String) {
        label.text = text
        setNeedsDisplay()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
