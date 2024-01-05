//
//  DocSave.swift
//  VisionKitDemo
//
//  Created by sahebroy on 04/01/24.
//

import Foundation
import UIKit

class DocSave {
    
    func saveImage(imageName: String, image: UIImage) {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        let fileName = imageName
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        guard let data = image.jpegData(compressionQuality: 1) else { return }
        
        //Checks if file exists, removes it if so.
        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                try FileManager.default.removeItem(atPath: fileURL.path)
                print("Removed old image")
            } catch let removeError {
                print("couldn't remove file at path", removeError)
            }
            
        }
        DispatchQueue.global().async {
            do {
                try data.write(to: fileURL)
            }
            catch {
                print(error)
            }
        }
    }
}
