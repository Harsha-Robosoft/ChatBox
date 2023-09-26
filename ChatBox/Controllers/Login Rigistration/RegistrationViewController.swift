//
//  RegistrationViewController.swift
//  ChatBox
//
//  Created by Harsha R Mundaragi  on 25/09/23.
//

import UIKit
import FirebaseAuth

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
        presentPhotoActionSheet()
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
        
        FirebaseAuth.Auth.auth().createUser(withEmail: email, password: password, completion: { [weak self] signUpResult, error in
            guard let result = signUpResult, error == nil else {
                
                return
            }
            let user = result.user
            print(user)
            self?.navigationController?.dismiss(animated: true)
        })
        
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


extension RegistrationViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    func presentPhotoActionSheet(){
        let ac = UIAlertController(title: "Profile picture.", message: "How would you like to select a picture?", preferredStyle: .actionSheet)
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        ac.addAction(UIAlertAction(title: "Take picture", style: .default, handler: { [weak self] _ in
            self?.presentCamera()
        }))
        ac.addAction(UIAlertAction(title: "Select picture", style: .default, handler: { [weak self] _ in
            self?.presentPhotoPicker()
        }))
        present(ac, animated: true)
    }
    
    func presentCamera(){
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true)
    }
    
    func presentPhotoPicker(){
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let selectedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage else{
            picker.dismiss(animated: true)
            return
        }
        profilePic.image = selectedImage
        profilePic.layer.cornerRadius = 70
        picker.dismiss(animated: true)
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
}
