//
//  NewConversationViewController.swift
//  ChatBox
//
//  Created by Harsha R Mundaragi  on 25/09/23.
//

import UIKit
import JGProgressHUD

class NewConversationViewController: UIViewController {

    public var completion: ((SearchResult) -> Void)?
    
    private let spinner = JGProgressHUD(style: .dark)
    private var users = [[String: String]]()
    private var hasFetched = false
    private var results = [SearchResult]()
    
    let searchBar: UISearchBar = {
        let search = UISearchBar()
        search.placeholder = "Search for users...."
        return search
    }()
    
    let tableView: UITableView = {
       let table = UITableView()
        table.register(NewConversationTableViewCell.self,
                       forCellReuseIdentifier: NewConversationTableViewCell.identifier)
        return table
    }()
    
    let noUserLbl: UILabel = {
        let lbl = UILabel()
        lbl.text = "No user found!"
        lbl.textAlignment = .center
        lbl.textColor = .gray
        lbl.font = .systemFont(ofSize: 21, weight: .medium)
        return lbl
    }()
    
    let cellName = NewConversationTableViewCell.identifier
    
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
        tableView.isHidden = true
        searchBar.delegate = self
        setUpTableView()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
        noUserLbl.frame = CGRect(x: (UIScreen.main.bounds.width / 2) - (view.width - 40) / 2 ,
                                 y: (view.height - 200) / 2,
                                 width: view.width - 40,
                                 height: 200)
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
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellName) as? NewConversationTableViewCell
        cell?.configure(with: results[indexPath.row])
        return cell ?? UITableViewCell()
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let newConversationWith = results[indexPath.row]
        
        dismiss(animated: true, completion: { [weak self] in
            self?.completion?(newConversationWith)
        })
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
    
    
}

extension NewConversationViewController: UISearchBarDelegate{
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text , !text.replacingOccurrences(of: " ", with: "").isEmpty else{
            
            return
        }
        
        results.removeAll()
        spinner.show(in: view, animated: true)
        self.searchUser(query: text)
    }
    
    
    
    func searchUser(query: String){
      // Check is array has firebase results
        if hasFetched{
            // if it does. filter
            filterUsers(with: query)
        }else{
            //if it not. fetch and filter
            DatabaseManager.shared.fetchAllUser(completion: { [weak self] result in
                switch result{
                    
                case .success(let userCollection):
                    self?.users = userCollection
                    self?.hasFetched = true
                    self?.filterUsers(with: query)
                case .failure(let error):
                    print(error)
                }
                
            })
        }
    }
    
    func filterUsers(with term: String){
        // filtering
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String , hasFetched else {
            
            return
        }
        
        let safeEmail = DatabaseManager.safeEmail(email: currentUserEmail)
        
        let result: [SearchResult] = self.users.filter({
            
            guard let email = $0["email"],
                  email != safeEmail,
                  let name = $0["name"]?.lowercased() else{
                return false
            }
            return name.hasPrefix(term.lowercased())
        }).compactMap({
            guard let email = $0["email"],
                  let name = $0["name"] else{
                return nil
            }
            return SearchResult(name: name, email: email)
        })
        
        self.results = result
        self.updateUI()
    }
    
    func updateUI(){
        // updating UI
        self.spinner.dismiss()
        if results.isEmpty{
            self.noUserLbl.isHidden = false
            self.tableView.isHidden = true
        }else{
            self.noUserLbl.isHidden = true
            self.tableView.isHidden = false
            self.tableView.reloadData()
        }
    }
    
}


struct SearchResult{
    let name: String
    let email: String
}
