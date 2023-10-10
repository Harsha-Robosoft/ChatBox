//
//  ProfileViewController.swift
//  ChatBox
//
//  Created by Harsha R Mundaragi  on 25/09/23.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import SDWebImage

final class ProfileViewController: UIViewController {
    
    var dataTa = [ProfileViewModel]()

    @IBOutlet weak var tableView01: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        dataTa.append(ProfileViewModel(viewModelType: .info,
                                       title: "Name: \(UserDefaults.standard.value(forKey: "name") as? String ?? "No Name")",
                                     handler: nil))
        dataTa.append(ProfileViewModel(viewModelType: .info,
                                       title: "Email: \(UserDefaults.standard.value(forKey: "email") as? String ?? "No email")",
                                     handler: nil))
        dataTa.append(ProfileViewModel(viewModelType: .logout, title: "Log Out", handler: { [weak self] in
            
            let ac = UIAlertController(title: "Are sure want to logout?", message: nil, preferredStyle: .actionSheet)
            ac.addAction(UIAlertAction(title: "Cancel", style: .default))
            ac.addAction(UIAlertAction(title: "Sign out", style: .destructive, handler: { [weak self] _ in
                
                guard let strongSelf = self else{
                    return
                }
                
                UserDefaults.standard.setValue(nil, forKey: "email")
                UserDefaults.standard.setValue(nil, forKey: "name")
                
                
                //MARK: - Log out from Facebook
                
                FBSDKLoginKit.LoginManager().logOut()
                
                //MARK: - Log out from google
                
                let firebaseAuth = Auth.auth()
                do {
                  try firebaseAuth.signOut()
                } catch let signOutError as NSError {
                  print("Error signing out: %@", signOutError)
                }
                
                //MARK: - Log out from firebase
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
            self?.present(ac, animated: true)
        }))
        tableView01.register(ProfileTableViewCell.self, forCellReuseIdentifier: ProfileTableViewCell.identifier)
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
                                        width: view.width,
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
        
        StorageManager.shared.downloadImageURLForProfile(for: path, completion: { result in
            switch result{
            case .success(let url):
                imageView.sd_setImage(with: url)
            case .failure(let failString):
                print(failString)
            }
            
        })
        
        return headerView
    }

}

extension ProfileViewController: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataTa.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let viewModel = dataTa[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ProfileTableViewCell.identifier) as? ProfileTableViewCell
        cell?.setUp(with: viewModel)
        return cell ?? UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        dataTa[indexPath.row].handler?()
    }
    
}


class ProfileTableViewCell: UITableViewCell {
    static let identifier = "ProfileTableViewCell"
    
    public func setUp(with viewModel: ProfileViewModel){
        textLabel?.text = viewModel.title
        
        switch viewModel.viewModelType{
        case .info:
            textLabel?.textAlignment = .left
            textLabel?.textColor = .black
            selectionStyle = .none
        case .logout:
            textLabel?.textColor = .red
            textLabel?.textAlignment = .center
        }
    }
}
