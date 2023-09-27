//
//  ProfileViewController.swift
//  ChatBox
//
//  Created by Harsha R Mundaragi  on 25/09/23.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit

class ProfileViewController: UIViewController {
    
    let data = ["Sign out"]

    @IBOutlet weak var tableView01: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView01.delegate = self
        tableView01.dataSource = self
    }


}

extension ProfileViewController: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        cell?.textLabel?.text = data[indexPath.row]
        return cell ?? UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        
        let ac = UIAlertController(title: "Are sure want to logout?", message: nil, preferredStyle: .actionSheet)
        ac.addAction(UIAlertAction(title: "Cancel", style: .default))
        ac.addAction(UIAlertAction(title: "Sign out", style: .destructive, handler: { [weak self] _ in
            
            guard let strongSelf = self else{
                return
            }
            
                // logging out from Facebook
            
            FBSDKLoginKit.LoginManager().logOut()
            
            do{
                try FirebaseAuth.Auth.auth().signOut()
                let vc = strongSelf.storyboard?.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
                let nav = UINavigationController(rootViewController: vc)
                nav.modalPresentationStyle = .fullScreen
                strongSelf.present(nav, animated: true)
            }catch{
                print("error while sign out")
            }
        }))
        present(ac, animated: true)
    }
    
}
