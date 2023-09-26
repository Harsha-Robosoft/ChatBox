//
//  RegistrationViewController.swift
//  ChatBox
//
//  Created by Harsha R Mundaragi  on 25/09/23.
//

import UIKit

class RegistrationViewController: UIViewController {

    @IBOutlet weak var profilePic: UIImageView!
    @IBOutlet weak var firstNameField: UITextField!
    @IBOutlet weak var lastNameField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var registerButton: UIButton!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Create account"
        view.backgroundColor = .white
        firstNameField.delegate = self
        lastNameField.delegate = self
        emailField.delegate = self
        passwordField.delegate = self
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(editImageTapped))
        profilePic.image = UIImage(systemName: "person.fill.badge.plus")
        profilePic.tintColor = .gray
        gesture.numberOfTapsRequired = 1
        gesture.numberOfTouchesRequired = 1
        profilePic.addGestureRecognizer(gesture)
        if profilePic.image == UIImage(systemName: "person.fill.badge.plus"){
            profilePic.layer.cornerRadius = 0
        }else{
            profilePic.layer.cornerRadius = 70
        }
        
    }
    
    @objc func editImageTapped(){
        print("hi")
    }
    
    @IBAction func registerButtonTapped(_ sender: Any) {
        registerButtonTapped()
    }
    
    func registerButtonTapped(){
        
        firstNameField.resignFirstResponder()
        lastNameField.resignFirstResponder()
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        
        guard let email = emailField.text,
              let password = passwordField.text,
              let firstName = firstNameField.text,
              let lastName = lastNameField.text,
              !firstName.isEmpty,
              !lastName.isEmpty,
              !email.isEmpty,
              !password.isEmpty,
              password.count >= 6 else {
            showAlert()
            return
        }
        
    }
    func showAlert(){
        let ac = UIAlertController(
            title: "Woops",
            message: "Please enter all the information correctly to register.",
            preferredStyle: .alert
        )
        ac.addAction(
            UIAlertAction(
                title: "Wokay",
                style: .cancel
            )
        )
        present(ac, animated: true)
    }
    
}

extension RegistrationViewController: UITextFieldDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == firstNameField{
            lastNameField.becomeFirstResponder()
        }else if textField == lastNameField{
            emailField.becomeFirstResponder()
        }else if textField == emailField{
            passwordField.becomeFirstResponder()
        }else if textField == passwordField{
            registerButtonTapped()
        }
        return true
    }
}
