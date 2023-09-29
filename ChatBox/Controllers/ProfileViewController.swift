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
        tableView01.tableHeaderView = createTableHeader()
    }

    func createTableHeader() -> UIView?{
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else{
            return nil
        }
        
        let safeEmail = DatabaseManager.safeEmail(email: email)
        let fileName = safeEmail + "_profile_picture.png"
        
        let path = "image/" + fileName
        
        let headerView = UIView(frame: CGRect(x: 0,
                                        y: 0,
                                        width: self.view.width,
                                        height: 300))
        headerView.backgroundColor = .lightGray
        let imageView = UIImageView(frame: CGRect(x: (headerView.width - 150) / 2,
                                                  y: 75,
                                                  width: 150,
                                                  height: 150))
        
        imageView.contentMode = .scaleAspectFill
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = 75
        imageView.layer.borderWidth = 3
        imageView.layer.borderColor = UIColor.white.cgColor
        headerView.addSubview(imageView)
        
        StorageManager.shared.downloadImageURLForProfile(for: path, completion: { [weak self] result in
            switch result{
            case .success(let url):
                self?.downloadImage(for: imageView, url: url)
            case .failure(let failString):
                print(failString)
            }
            
        })
        
        return headerView
    }
    
    func downloadImage(for imageView: UIImageView, url: URL){
        URLSession.shared.dataTask(with: url, completionHandler: { data, urlResponce, error in
            guard let data = data, error == nil else {
                return
            }
            
            DispatchQueue.main.async {
                let image = UIImage(data: data)
                imageView.image = image
            }
        }).resume()
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
