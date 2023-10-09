//
//  ViewController.swift
//  ChatBox
//
//  Created by Harsha R Mundaragi  on 25/09/23.
//

import UIKit
import FirebaseAuth
import JGProgressHUD

final class ConversationViewController: UIViewController {
    
    private var loginObserver: NSObjectProtocol?
    let spinner = JGProgressHUD(style: .dark)
    private var conversations = [Conversation]()
    let tableView: UITableView = {
       let table = UITableView()
        table.register(ConversationTableViewCell.self,
                       forCellReuseIdentifier: ConversationTableViewCell.identifier)
        table.isHidden = true
        return table
    }()
    
    let cellName = ConversationTableViewCell.identifier
    
    let noConversationLbl: UILabel = {
        let lbl = UILabel()
        lbl.text = "No conversation!"
        lbl.textAlignment = .center
        lbl.textColor = .gray
        lbl.isHidden = true
        lbl.font = .systemFont(ofSize: 21, weight: .medium)
        return lbl
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose,
                                                            target: self,
                                                            action: #selector(createNewChatTapped))
        view.addSubview(tableView)
        view.addSubview(noConversationLbl)
        setUpTableView()
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
        noConversationLbl.frame = CGRect(x: 10,
                                         y: (view.height - 100) / 2,
                                         width: view.width - 20,
                                         height: 100)
    }
    
    
    private func startListeningForConversation(){
        
        if let obserVer = loginObserver{
            NotificationCenter.default.removeObserver(obserVer)
        }
        
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(email: email)
        print("fetching the conversations")
        DatabaseManager.shared.getAllTheConversations(for: safeEmail, completion: { [weak self] result in
            switch result {
            case .success(let conversations):
                guard !conversations.isEmpty else{
                    print("failed to fetch conversations")
                    self?.tableView.isHidden = true
                    self?.noConversationLbl.isHidden = false
                    return
                }
                print("fetching conversations completed...")
                self?.tableView.isHidden = false
                self?.noConversationLbl.isHidden = true
                self?.conversations = conversations
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
            case .failure(let error):
                self?.tableView.isHidden = true
                self?.noConversationLbl.isHidden = false
                print("failed to get conversation: \(error)")
            }
        })
    }
    
    @objc func createNewChatTapped(){
        let vc = NewConversationViewController()
        vc.completion = { [weak self] result in
            
            let currentConversations = self?.conversations
            
            if let targetConversation = currentConversations?.first(where: {
                $0.otherUserEmail == DatabaseManager.safeEmail(email: result.email)
            }){
                let vc = ChatViewController(with: targetConversation.otherUserEmail, id: targetConversation.id)
                vc.isNewConversation = false
                vc.navigationItem.largeTitleDisplayMode = .never
                vc.hidesBottomBarWhenPushed = true
                vc.title = targetConversation.name
                self?.navigationController?.pushViewController(vc, animated: true)
            }else{
                self?.createNewConversation(result: result)
            }
        }
        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true)
    }
    
    private func createNewConversation(result: SearchResult){
        
        let name = result.name
        let email = DatabaseManager.safeEmail(email: result.email)
        
        // check in database if conversation with these two exists
        // if does, reuse conversation id
        //otherwise user existing code
        
        DatabaseManager.shared.conversationExists(with: email, completion: { [weak self] result in
            switch result{
            case .success(let conversationId):
                print("continuing the conversation with deleted user")
                let vc = ChatViewController(with: email, id: conversationId)
                vc.isNewConversation = false
                vc.navigationItem.largeTitleDisplayMode = .never
                vc.hidesBottomBarWhenPushed = true
                vc.title = name
                self?.navigationController?.pushViewController(vc, animated: true)
            case .failure(_):
                print("creating a truly new conversation")
                let vc = ChatViewController(with: email, id: nil)
                vc.isNewConversation = true
                vc.navigationItem.largeTitleDisplayMode = .never
                vc.hidesBottomBarWhenPushed = true
                vc.title = name
                self?.navigationController?.pushViewController(vc, animated: true)
            }
        })
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
        let model = conversations[indexPath.row]
        openConversation(model)
    }
    
    func openConversation(_ model: Conversation){
        let vc = ChatViewController(with: model.otherUserEmail, id: model.id)
        vc.navigationItem.largeTitleDisplayMode = .never
        vc.title = model.name
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        .delete
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete{
            tableView.beginUpdates()
            let convoId = conversations[indexPath.row].id
            DatabaseManager.shared.deleteConversation(conversationId: convoId, completion: { success in
                if success{
                    print("deleted convo from firebase and also local")
                    
                }else{
                    print(" failed to deleted convo from firebase and also local")
                    tableView.endUpdates()
                    return
                }
            })
            conversations.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .left)
            tableView.endUpdates()
        }
    }
}
