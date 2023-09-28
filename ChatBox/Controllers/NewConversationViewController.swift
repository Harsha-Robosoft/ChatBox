//
//  NewConversationViewController.swift
//  ChatBox
//
//  Created by Harsha R Mundaragi  on 25/09/23.
//

import UIKit

class NewConversationViewController: UIViewController {

    let searchBar: UISearchBar = {
        let search = UISearchBar()
        search.placeholder = "Search for users...."
        return search
    }()
    
    let tableView: UITableView = {
       let table = UITableView()
        table.register(UITableViewCell.self,
                       forCellReuseIdentifier: "newConversationCell")
        return table
    }()
    
    let noUserLbl: UILabel = {
        let lbl = UILabel()
        lbl.text = "No conversation!"
        lbl.textAlignment = .center
        lbl.textColor = .gray
        lbl.font = .systemFont(ofSize: 21, weight: .medium)
        return lbl
    }()
    
    let cellName = "newConversationCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        navigationController?.navigationBar.topItem?.titleView = searchBar
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel",
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(dismissViewTapped))
        searchBar.becomeFirstResponder() 
        view.addSubview(tableView)
        view.addSubview(noUserLbl)
        noUserLbl.isHidden = true
        setUpTableView()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
    }

    func setUpTableView(){
        tableView.delegate = self
        tableView.dataSource = self
    }
    @objc func dismissViewTapped(){
        dismiss(animated: true)
    }
    
}

extension NewConversationViewController: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellName)
        cell?.textLabel?.text = "hello"
        return cell ?? UITableViewCell()
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        print("new chat")
        dismissViewTapped()
    }
    
    
}

extension NewConversationViewController: UISearchBarDelegate{
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        print("hi")
    }
}
