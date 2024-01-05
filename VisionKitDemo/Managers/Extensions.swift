
import Foundation
import UIKit
import Vision

extension Date {
    static var timestamp: String {
        get {
            return String(Date().timeIntervalSince1970 * 1000)
        }
    }
}

extension Array {
    func subArray(withSize n: Int) -> [Element] {
        precondition(n >= 0 && n <= count)
        return (0..<n).map { self[($0 * count + count/2)/n] }
    }
}

extension String {
    func loadImageFromDiskWith() -> UIImage? {
        
        let documentDirectory = FileManager.SearchPathDirectory.documentDirectory
        let userDomainMask = FileManager.SearchPathDomainMask.userDomainMask
        let paths = NSSearchPathForDirectoriesInDomains(documentDirectory, userDomainMask, true)
        
        if let dirPath = paths.first {
            let imageUrl = URL(fileURLWithPath: dirPath).appendingPathComponent(self)
            let image = UIImage(contentsOfFile: imageUrl.path)
            return image
            
        }
        
        return nil
    }
}

extension UIImage {
    func visualization(observations: [VNDetectedObjectObservation], color: UIColor) -> UIImage {
        var transform = CGAffineTransform.identity
            .scaledBy(x: 1, y: -1)
            .translatedBy(x: 1, y: -self.size.height)
        transform = transform.scaledBy(x: self.size.width, y: self.size.height)

        UIGraphicsBeginImageContextWithOptions(self.size, true, 0.0)
        let context = UIGraphicsGetCurrentContext()

        self.draw(in: CGRect(origin: .zero, size: self.size))
        context?.saveGState()

        context?.setLineWidth(2)
        context?.setLineJoin(CGLineJoin.round)
        context?.setStrokeColor(UIColor.black.cgColor)
        context?.setFillColor(color.cgColor)

        observations.forEach { observation in
            let bounds = observation.boundingBox.applying(transform)
            context?.addRect(bounds)
        }

        context?.drawPath(using: CGPathDrawingMode.fillStroke)
        context?.restoreGState()
        let resultImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resultImage!
    }
}
