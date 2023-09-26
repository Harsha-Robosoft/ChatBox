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
