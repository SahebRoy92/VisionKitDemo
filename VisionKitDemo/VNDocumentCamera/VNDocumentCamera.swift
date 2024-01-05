import UIKit
import VisionKit
import Vision
import QKMRZParser
import NaturalLanguage

class VNDocumentCamera: UIViewController {

    let recognizer = NLLanguageRecognizer()
    var req : VNRecognizeTextRequest!
    let parser = QKMRZParser(ocrCorrection: true)
    
    lazy var startCamera : UIButton = {
       let button = UIButton()
        button.setTitle("Start Document Scanning", for: .normal)
        button.addTarget(self, action: #selector(startCameraAction), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
        
    
    let textRecognitionWorkQueue = DispatchQueue(label: "RecognitionQueue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
    let dispatchGroup = DispatchGroup()
    var allScannedDocument = [Document]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addScannerButton()
    }

    override func viewWillDisappear(_ animated: Bool) {
        allScannedDocument.removeAll()
    }
    
    func addScannerButton() {
        view.addSubview(startCamera)
        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: startCamera, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: startCamera, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1.0, constant: 0)
        
        ])
    }
    
    @objc func startCameraAction() {
        let scannerViewController = VNDocumentCameraViewController()
        scannerViewController.delegate = self
        present(scannerViewController, animated: true)
    }
    
    func performTextRecognition(_ fileName: String, image: UIImage) -> VNRecognizeTextRequest {
        req = VNRecognizeTextRequest { request, error in
            if let error = error {
                print("ERROR: \(error)")
                return
            }

            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    print("Error: \(error! as NSError)")
                    return
                }
            var fileStr = ""
                for currentObservation in observations {
                    let topCandidate = currentObservation.topCandidates(1)
                    if let recognizedText = topCandidate.first {
                        if recognizedText.confidence > 0.9 {
                            fileStr += recognizedText.string
                            fileStr += "\n"
                        }
                    }
                }
            
            self.recognizer.processString(fileStr)
            var primLanguage: String = ""
            if let language = self.recognizer.dominantLanguage {
                primLanguage = language.rawValue
                print("Predominantly has \(language.rawValue) language")
                print("Data \(fileStr)")
            } else {
                print("Language not recognized")
            }
            
            let fillColor: UIColor = UIColor.yellow.withAlphaComponent(0.3)
            let result = image.visualization(observations: observations, color: fillColor)
            
            
            var document = Document.init(image: result, data: fileStr, primaryLanguage: primLanguage)
            if let result = self.parser.parse(mrzString: document.data) {
                document.isDocument = result
            }
            self.allScannedDocument.append(document)
            self.dispatchGroup.leave()
        }
        req.recognitionLevel = .accurate
        req.automaticallyDetectsLanguage = true
        req.usesLanguageCorrection = true
        
        return req
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? ResultViewController {
            vc.allDocuments = allScannedDocument
        }
    }
    
}

extension VNDocumentCamera : VNDocumentCameraViewControllerDelegate {
    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        controller.dismiss(animated: true)
    }
    
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
        print(error.localizedDescription)
        controller.dismiss(animated: true)
    }
    
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        for index in 0..<scan.pageCount {
            let image = scan.imageOfPage(at: index)
            let fileName = Date.timestamp

            let requests = [performTextRecognition(fileName, image: image)]
            dispatchGroup.enter()
            textRecognitionWorkQueue.async {
                guard let img = image.cgImage else {return}
                let handler = VNImageRequestHandler(cgImage: img, options: [:])
                try? handler.perform(requests)
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            controller.dismiss(animated: true) {
                self.performSegue(withIdentifier: "ResultViewController", sender: self)
            }
        }
    }
}
