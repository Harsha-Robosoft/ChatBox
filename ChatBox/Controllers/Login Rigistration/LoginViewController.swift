//
//  LoginViewController.swift
//  ChatBox
//
//  Created by Harsha R Mundaragi  on 25/09/23.
//

import UIKit
import FirebaseAuth

class LoginViewController: UIViewController {
    
    @IBOutlet weak var emailField: UITextField!
    
    @IBOutlet weak var passwordField: UITextField!
    
    @IBOutlet weak var loginButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Log in"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register", style: .done, target: self, action: #selector(presentRegisterScreen))
        emailField.delegate = self
        passwordField.delegate = self
    }
    
    @objc func presentRegisterScreen(){
        let vc = storyboard?.instantiateViewController(withIdentifier: "RegistrationViewController") as! RegistrationViewController
        navigationController?.pushViewController(vc, animated: true)
    }
    
    

    @IBAction func logIntapped(_ sender: Any) {
        
        loginButtonTapped()
    }
    
    func loginButtonTapped(){
        
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        
        guard let email = emailField.text,
              let password = passwordField.text,
              !email.isEmpty, !password.isEmpty,
              password.count >= 6 else {
            showAlert(aleartString: "Please enter all the information correctly to login")
            return
        }
        
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password, completion: { [weak self] signInResult, error in
            guard let result = signInResult, error == nil else {
                
                return
            }
            let user = result.user
            print(user)
            self?.navigationController?.dismiss(animated: true)
        })
        
    }
}

extension LoginViewController: UITextFieldDelegate{
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailField{
            passwordField.becomeFirstResponder()
        }else if textField == passwordField{
            loginButtonTapped()
        }
        return true
    }
    
}
