//
//  NewConversationTableViewCell.swift
//  ChatBox
//
//  Created by Harsha R Mundaragi  on 05/10/23.
//

import UIKit
import SDWebImage

class NewConversationTableViewCell: UITableViewCell {
    
    static let identifier = "NewConversationTableViewCell"

    private let userImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = 35
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    private let userNameLbl: UILabel = {
        let nameLbl = UILabel()
        nameLbl.font = .systemFont(ofSize: 21, weight: .semibold)
        return nameLbl
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(userImageView)
        contentView.addSubview(userNameLbl)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        userImageView.frame = CGRect(x: 10,
                                     y: 10,
                                     width: 70,
                                     height: 70)
        userNameLbl.frame = CGRect(x: userImageView.right + 10,
                                     y: 20,
                                   width: contentView.width - 20 - userImageView.width,
                                   height: 50)
        
    }
    
    public func configure(with model: SearchResult){
        self.userNameLbl.text = model.name
        let path = "image/\(model.email)_profile_picture.png"
        StorageManager.shared.downloadImageURLForProfile(for: path, completion: { [weak self] result in
            switch result{
            case .success(let url):
                DispatchQueue.main.async {
                    self?.userImageView.sd_setImage(with: url)
                }
            case .failure(let error):
                print("error while getting profile url: \(error)")
            }
        })
    }
    
}
