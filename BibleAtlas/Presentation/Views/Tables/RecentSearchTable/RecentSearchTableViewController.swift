//
//  RecentSearchTableView.swift
//  BibleAtlas
//
//  Created by 배성연 on 4/24/25.
//

import UIKit

class RecentSearchTableViewController: UITableViewController {
    private var searches: [String] = [];
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: RecentSearchTableViewCell.identifier, for: indexPath) as? RecentSearchTableViewCell else {
            return UITableViewCell()
        }

        cell.setText(text: searches[indexPath.row])
        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searches.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80;
    }
    
    func setSearches(searches:[String]){
        self.searches = searches
    }

}
