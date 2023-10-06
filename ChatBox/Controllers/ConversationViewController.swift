//
//  ViewController.swift
//  ChatBox
//
//  Created by Harsha R Mundaragi  on 25/09/23.
//

import UIKit
import FirebaseAuth
import JGProgressHUD

struct Conversation{
    let id: String
    let name: String
    let otherUserEmail: String
    let latestMessage: LatestMessage
}

struct LatestMessage{
    let date: String
    let text: String
    let isRed: Bool
}

class ConversationViewController: UIViewController {

    
    private var loginObserver: NSObjectProtocol?
    let spinner = JGProgressHUD(style: .dark)
    private var conversations = [Conversation]()
    let tableView: UITableView = {
       let table = UITableView()
        table.register(ConversationTableViewCell.self,
                       forCellReuseIdentifier: ConversationTableViewCell.identifier)
        return table
    }()
    
    let cellName = ConversationTableViewCell.identifier
    
    let noConversationLbl: UILabel = {
        let lbl = UILabel()
        lbl.text = "No conversation!"
        lbl.textAlignment = .center
        lbl.textColor = .gray
        lbl.font = .systemFont(ofSize: 21, weight: .medium)
        return lbl
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose,
                                                            target: self,
                                                            action: #selector(createNewChatTapped))
        view.backgroundColor = .gray
        view.addSubview(tableView)
        view.addSubview(noConversationLbl)
        setUpTableView()
        tableView.isHidden = true
        noConversationLbl.isHidden = true
        fetchConversation()
        startListeningForConversation()
        
        loginObserver = NotificationCenter.default.addObserver(forName: .didLoginNotification,
                                               object: nil,
                                               queue: .main,
                                               using: { [weak self] _ in
            self?.startListeningForConversation()
        })
        
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkForSigIn()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
    }
    
    
    private func startListeningForConversation(){
        
        if let obserVer = loginObserver{
            NotificationCenter.default.removeObserver(obserVer)
        }
        
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(email: email)
        DatabaseManager.shared.getAllTheConversations(for: safeEmail, completion: { [weak self] result in
            switch result {
            case .success(let conversations):
                guard !conversations.isEmpty else{
                    print("empty")
                    return
                }
                print(conversations.count)
                self?.conversations = conversations
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
            case .failure(let error):
                print("failed to get conversation: \(error)")
            }
        })
    }
    
    @objc func createNewChatTapped(){
        let vc = NewConversationViewController()
        vc.completion = { [weak self] result in
            print(result)
            self?.createNewConversation(result: result)
        }
        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true)
    }
    
    private func createNewConversation(result: SearchResult){
        
        let name = result.name
        let email = result.email
        let vc = ChatViewController(with: email, id: nil)
        vc.isNewConversation = true
        vc.navigationItem.largeTitleDisplayMode = .never
        vc.hidesBottomBarWhenPushed = true
        vc.title = name
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func checkForSigIn(){
        if FirebaseAuth.Auth.auth().currentUser == nil{
            let vc = storyboard?.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: false)
        }
    }
    
    func setUpTableView(){
        tableView.delegate = self
        tableView.dataSource = self
    }

    func fetchConversation(){
        tableView.isHidden = false
    }
}


extension ConversationViewController: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let mode = conversations[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: cellName) as? ConversationTableViewCell
        cell?.configure(with: mode)
        cell?.accessoryType = .disclosureIndicator
        return cell ?? UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let mode = conversations[indexPath.row]
        let vc = ChatViewController(with: mode.otherUserEmail, id: mode.id)
        vc.navigationItem.largeTitleDisplayMode = .never
        vc.title = mode.name
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
}
