//
//  ResultViewController.swift
//  VisionKitDemo
//
//  Created by sahebroy on 05/01/24.
//

import Foundation
import UIKit

class ResultViewController: UIViewController {
    
    var currentDocument: Document?
    
    @IBOutlet weak var docImage: UIImageView!
    
    @IBOutlet weak var lblLanguage: UILabel!
    
    @IBOutlet weak var docString: UILabel!
    
    @IBOutlet weak var btnNext: UIButton!
    
    @IBOutlet weak var btnPrev: UIButton!
    
    var allDocuments = [Document]()
    
    let dateFormatter = DateFormatter()
    
    var currentDocIndex = 0
    
    
    override func viewDidLoad() {
        configureButtons()
        dateFormatter.dateFormat = "DDD-MM-YYYY"
        currentDocument = allDocuments[currentDocIndex]
        populate()
    }
    
    func configureButtons() {
        btnPrev.isHidden = true
        if allDocuments.count > 1 {
            btnNext.isHidden = false
        } else {
            btnNext.isHidden = true
        }
    }
    
    
    @IBAction func nextDocAction(_ sender: Any) {
        if currentDocIndex == allDocuments.count - 1 {
            btnNext.isHidden = true
        }
        btnPrev.isHidden = false
        currentDocIndex += 1
        currentDocument = allDocuments[currentDocIndex]
        populate()
    }
    
    @IBAction func prevDocAction(_ sender: Any) {
        if currentDocIndex == 0 {
            btnPrev.isHidden = true
        }
        currentDocIndex -= 1
        currentDocument = allDocuments[currentDocIndex]
        populate()
    }
    
    
    
    @IBAction func autoCorrectAction(_ sender: Any) {
        
    }
    
    
    func populate() {
        guard let document = currentDocument else {return}
        if let doc = document.isDocument {
            lblLanguage.text = "Document: \(doc.documentType)"
            var documentStr = ""
            documentStr = "Name - \(doc.givenNames) \n LastName - \(doc.surnames) \n Doc Number - \(doc.documentNumber)\n Country Code - \(doc.countryCode)"
            
            if let expiryDate = doc.expiryDate {
                let expStr = dateFormatter.string(from: expiryDate)
                documentStr += "\n Expiry Date -\(expStr)"
            }
            
            if let dob = doc.birthdate {
                let docStr = dateFormatter.string(from: dob)
                documentStr += "\n DOB -\(docStr)"
            }
            
            if let gender = doc.sex {
                documentStr += "\n Gender -\(gender)"
            }
            docString.text = documentStr

        } else {
            lblLanguage.text = "Language: \(document.primaryLanguage)"
            docString.text = document.data

        }
        docImage.image = document.image
    }
}
