//
//  Document.swift
//  VisionKitDemo
//
//  Created by sahebroy on 04/01/24.
//

import Foundation
import UIKit
import QKMRZParser

struct Document {
    let image: UIImage?
    var data: String
    var primaryLanguage: String
    var isDocument: QKMRZResult?
}

