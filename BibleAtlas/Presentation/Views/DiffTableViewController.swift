//
//  DiffTableViewController.swift
//  BibleAtlas
//
//  Created by 배성연 on 3/3/25.
//

import UIKit

class DiffTableViewController: UITableViewController {
    
    var diffCodes:[DiffCode] = []
        
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
    }


    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return diffCodes.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: DiffTableViewCell.identifier, for: indexPath) as? DiffTableViewCell else {
            return UITableViewCell()
        }
        
        cell.configure(diffCode: diffCodes[indexPath.row])

        
        return cell
    }
    
//    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return 80;
//    }
    

    func setDiffCodes(diffCodes:[DiffCode]){
        self.diffCodes = diffCodes
    }

  
    
}
