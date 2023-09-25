//
//  ViewController.swift
//  ChatBox
//
//  Created by Harsha R Mundaragi  on 25/09/23.
//

import UIKit

class ConversationViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .gray
        // Do any additional setup after loading the view.
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let isLoggedIn = UserDefaults.standard.bool(forKey: "logged_in")
        if !isLoggedIn{
            let vc = storyboard?.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: false)
        }
    }


}

