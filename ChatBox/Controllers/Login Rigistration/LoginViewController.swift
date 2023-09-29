//
//  LoginViewController.swift
//  ChatBox
//
//  Created by Harsha R Mundaragi  on 25/09/23.
//

import UIKit
import FirebaseAuth
import FBSDKCoreKit
import FBSDKLoginKit
import JGProgressHUD

class LoginViewController: UIViewController {
    
    let spinner = JGProgressHUD(style: .dark)
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var emailField: UITextField!
    
    @IBOutlet weak var passwordField: UITextField!
    
    @IBOutlet weak var loginButton: UIButton!
    let facebookLoginButton = FBLoginButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Log in"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register", style: .done, target: self, action: #selector(presentRegisterScreen))
        emailField.delegate = self
        passwordField.delegate = self
        facebookLoginButton.frame = CGRect(x: scrollView.frame.width / 2 - 157, y:  loginButton.bottom + 120 , width: 314, height: 52)
        facebookLoginButton.permissions = ["public_profile", "email"]
        view.addSubview(facebookLoginButton)
        facebookLoginButton.delegate = self
    }
    
    @objc func presentRegisterScreen(){
        let vc = storyboard?.instantiateViewController(withIdentifier: "RegistrationViewController") as! RegistrationViewController
        navigationController?.pushViewController(vc, animated: true)
    }
    
    
    
    @IBAction func logIntapped(_ sender: Any) {
        
        spinner.show(in: view)
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
            dismissSpinner()
            return
        }
        
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password, completion: { [weak self] signInResult, error in
            guard let strongSelf = self else{
                
                return
            }
            
            guard let result = signInResult, error == nil else {
                print("failed to save user data in firebase ")
                strongSelf.dismissSpinner()
                return
            }
            let user = result.user
            UserDefaults.standard.set(email, forKey: "email")
            strongSelf.dismissSpinner()
            strongSelf.navigationController?.dismiss(animated: true)
        })
        
    }
    
    func dismissSpinner(){
        DispatchQueue.main.async {
            self.spinner.dismiss(animated: true)
        }
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

extension LoginViewController: LoginButtonDelegate{
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginKit.FBLoginButton) {
        // no code here
    }
    
    func loginButton(_ loginButton: FBSDKLoginKit.FBLoginButton, didCompleteWith result: FBSDKLoginKit.LoginManagerLoginResult?, error: Error?) {
        
        // here getting token from FB
        guard let token = result?.token?.tokenString else {
            print("user failerd to login with face book")
            return
        }
        
        // first we need to get the user email and user name and need to check if user is already logged in with this email
        
        let faceBookRequest = FBSDKLoginKit.GraphRequest(graphPath: "me",
                                                         parameters: ["fields" : "email, first_name, last_name, picture.type(large)"],
                                                         tokenString: token,
                                                         version: nil,
                                                         httpMethod: .get)
        // here we get the user data from FB
        
        faceBookRequest.start(completion: { connection, results, error in
            guard let result = results as? [String: Any], error == nil else {
                print("failed to make FB graph request")
                return
            }
            // here we are taking the user name and email
            guard let firstName = result["first_name"] as? String,
                  let lastName = result["last_name"] as? String,
                  let email = result["email"] as? String,
                  let picture = result["picture"] as? [String: Any],
                  let data = picture["data"] as? [String: Any],
                  let pictureUrl = data["url"] as? String else{
                print("Failed to get email, first_name, last_name, data and image url name from FB")
                return
            }
            
            UserDefaults.standard.set(email, forKey: "email")
            
            // here we are checking if user already exist with this email
            
            DatabaseManager.shared.userExits(with: email, completion: { exist in
                if !exist{
                    let chatUser = ChapAppUser(firstName: firstName,
                                               lastName: lastName,
                                               email: email)
                    // if not exist we are saving the user data to the data base
                    DatabaseManager.shared.insertUser(with: chatUser){ success in
                        if success{
                            // uploading the profile picture to firebase storage
                            
                            guard let url = URL(string: pictureUrl) else{
                                return
                            }
                            
                            print("Downloading data from facebook image")
                            
                            URLSession.shared.dataTask(with: url, completionHandler: { data, _, _ in
                                guard let data = data else{
                                    print("Failed to get data from image")
                                    return
                                }
                                print("get the data from image, uploading....")
                                let fileName = chatUser.profilePictureFileName
                                StorageManager.shared.uploadProfilePicture(with: data, fileName: fileName, completion: { result in
                                    switch result{
                                    case.success(let downloadUrl):
                                        UserDefaults.standard.setValue(downloadUrl, forKey: "profile_picture_url")
                                        print(downloadUrl)
                                    case .failure(let error):
                                        print("storage manager: \(error)")
                                    }
                                })
                                print("Uploaded FB image to firebase...")
                                
                            }).resume()
                        }else{
                            
                        }
                    }
                }
            })
            
            // here from Facebook credential trying to login to firebase
            let credential = FacebookAuthProvider.credential(withAccessToken: token)
            FirebaseAuth.Auth.auth().signIn(with: credential, completion: { [weak self] signInResult, error in
                guard let strongSelf = self else{
                    
                    return
                }
                guard signInResult != nil, error == nil else{
                    print("facebook credential login failed, MFA[Multi factor authentication] may be needed.")
                    return
                }
                
                print("Successfully logged in using Face book")
                strongSelf.navigationController?.dismiss(animated: true)
            })
        })
    }
}
