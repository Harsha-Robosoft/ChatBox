//
//  LoginViewController.swift
//  ChatBox
//
//  Created by Harsha R Mundaragi  on 25/09/23.
//

import UIKit

class LoginViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Log in"
        view.backgroundColor = .lightGray
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register", style: .done, target: self, action: #selector(presentRegisterScreen))
    }
    
    @objc func presentRegisterScreen(){
        let vc = storyboard?.instantiateViewController(withIdentifier: "RegistrationViewController") as! RegistrationViewController
        navigationController?.pushViewController(vc, animated: true)
    }

}
