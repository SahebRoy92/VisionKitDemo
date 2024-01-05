//
//  AllActionsViewController.swift
//  VisionKitDemo
//
//  Created by sahebroy on 04/01/24.
//

import Foundation
import UIKit


enum AllActionTableViewSection: String, CaseIterable, Hashable{
    case allActions = "All Actions"
}

class AllActionsViewController : UIViewController {
    
    private var allActions = [AllActionsModel]()
    
    
    private lazy var tableViewDataSource: AllActionDataSource = {
        let dataSource = AllActionDataSource(tableView: tableView) { tableView, indexPath, item in
            guard let cell = tableView.dequeueReusableCell(withIdentifier: AllActionTableViewCell.identifier) as? AllActionTableViewCell else {
                return AllActionTableViewCell(style: .default, reuseIdentifier: AllActionTableViewCell.identifier)
            }
            cell.updateWithModel(self.allActions[indexPath.row])
            return cell
        }
        return dataSource
    }()
        
    lazy var tableView: UITableView = {
        let tableview = UITableView()
        tableview.register(AllActionTableViewCell.self, forCellReuseIdentifier: AllActionTableViewCell.identifier)
        tableview.delegate = self
        tableview.translatesAutoresizingMaskIntoConstraints = false
        return tableview
    }()
    
    override func viewDidLoad() {
        addTableview()
        getValues()
    }
    
    func addTableview() {
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: tableView, attribute: .leadingMargin, relatedBy: .equal, toItem: view, attribute: .leadingMargin, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: tableView, attribute: .trailingMargin, relatedBy: .equal, toItem: view, attribute: .trailingMargin, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: tableView, attribute: .topMargin, relatedBy: .equal, toItem: view, attribute: .topMargin, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: tableView, attribute: .bottomMargin, relatedBy: .equal, toItem: view, attribute: .bottomMargin, multiplier: 1.0, constant: 0)
        ])
    }
    
    func getValues() {
        allActions = ([
            AllActionsModel(title: "Document Scan",action: .doc),
            AllActionsModel(title: "Data Scan",action: .data),
            AllActionsModel(title: "Face Detection",action: .faceDetec)
        ])
        populate()
    }
    
    
    func populate() {
        var snapshot = NSDiffableDataSourceSnapshot<AllActionTableViewSection, AnyHashable>()
            defer {
                tableViewDataSource.apply(snapshot)
            }
        snapshot.appendSections([.allActions])
        snapshot.appendItems(allActions, toSection: .allActions)
    }
    
    class AllActionDataSource: UITableViewDiffableDataSource<AllActionTableViewSection, AnyHashable> {
        override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
            return snapshot().sectionIdentifiers[section].rawValue
        }
    }
}



extension AllActionsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let action = allActions[indexPath.row]
        if action.action == .doc {
            self.performSegue(withIdentifier: "DocumentScanner", sender: self)
        } else if action.action == .data{
            self.performSegue(withIdentifier: "CustomDataScannerViewController", sender: self)
        } else if action.action == .faceDetec {
            self.performSegue(withIdentifier: "FaceDetectionViewController", sender: self)
        }
    }
}


struct AllActionsModel : Hashable {
    let title: String
    let action: Action
    
    enum Action {
        case doc
        case data
        case faceDetec
    }
}


class AllActionTableViewCell: UITableViewCell {
    static let identifier = "AllActionTableViewCell"
    
    lazy var label: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        addLabel()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addLabel() {
        if label.superview != nil { return }
        contentView.addSubview(label)
        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: label, attribute: .centerY, relatedBy: .equal, toItem: contentView, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: label, attribute: .leading, relatedBy: .equal, toItem: contentView, attribute: .leadingMargin, multiplier: 1.0, constant: 25)
        ])
    }
    
    
    func updateWithModel(_ model: AllActionsModel) {
        label.text = model.title
    }
}
