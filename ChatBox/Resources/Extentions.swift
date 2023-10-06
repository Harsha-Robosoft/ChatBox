//
//  Extentions.swift
//  ChatBox
//
//  Created by Harsha R Mundaragi  on 26/09/23.
//

import Foundation
import UIKit

extension UIViewController{
    func showAlert(aleartString: String){
        let ac = UIAlertController(
            title: "Woops",
            message: aleartString,
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

extension UIView{
    public var width: CGFloat{
        return self.frame.size.width
    }
    public var height: CGFloat{
        return self.frame.size.height
    }
    public var top: CGFloat{
        return self.frame.origin.y
    }
    public var bottom: CGFloat{
        return self.frame.size.height + self.frame.origin.y
    }
    
    public var legt: CGFloat{
        return self.frame.origin.x
    }
    public var right: CGFloat{
        return self.frame.size.width + self.frame.origin.x
    }
    
}


extension Notification.Name {
    static let didLoginNotification = Notification.Name("didLoginNotification")
}
