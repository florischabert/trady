//
//  SearchViewController.swift
//  Trady
//
//  Created by Floris Chabert on 3/24/16.
//  Copyright © 2016 Floris Chabert. All rights reserved.
//

import UIKit

class SearchViewController: UITableViewController, UISearchResultsUpdating {

    var symbols: [YahooClient.SearchResult] = []

    var app: AppDelegate {
        return (UIApplication.sharedApplication().delegate as! AppDelegate)
    }

    var searchController: UISearchController!

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = self

        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self

        searchController.dimsBackgroundDuringPresentation = false

        searchController.searchBar.sizeToFit()
        tableView.tableHeaderView = searchController.searchBar

        definesPresentationContext = true

        title = "Follow a symbol"
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .Subtitle, reuseIdentifier: "ResultCell")
        cell.textLabel?.text = symbols[indexPath.row].symbol
        cell.detailTextLabel?.text = symbols[indexPath.row].name
        return cell
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return symbols.count
    }

    func updateSearchResultsForSearchController(searchController: UISearchController) {
        if let searchText = searchController.searchBar.text {
            if !searchText.isEmpty {
                UIApplication.sharedApplication().networkActivityIndicatorVisible = true

                YahooClient.search(searchText) { symbols in
                    self.symbols = symbols
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    self.tableView.reloadData()
                }
            }
            else {
                symbols = []
                tableView.reloadData()
            }
        }
    }
}