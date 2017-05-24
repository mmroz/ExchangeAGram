//
//  ProfileViewController.swift
//  ExchangeAGram
//
//  Created by Mark Mroz on 2017-05-22.
//  Copyright © 2017 MarkMroz. All rights reserved.
//

import UIKit

class ProfileViewController: UIViewController, FBLoginViewDelegate {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var fbLoginView: FBLoginView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fbLoginView.delegate = self
        self.fbLoginView.readPermissions = ["public_profile", "publish_actions"]
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func mapViewButtonTapped(_ sender: UIButton) {
        performSegue(withIdentifier: "mapSegue", sender: nil)
    }
    
    func loginViewShowingLogged(inUser loginView: FBLoginView!) {
        profileImageView.isHidden = false
        nameLabel.isHidden = false
    }
    
    func loginViewFetchedUserInfo(_ loginView: FBLoginView!, user: FBGraphUser!) {
        print(user)
        
        nameLabel.text = user.name
        let userImageURL : NSString = "https://graph.facebook.com/\(user.objectID!)/picture?type=large" as NSString
        let urlStr : NSString = userImageURL.addingPercentEscapes(using: String.Encoding.utf8.rawValue)! as NSString
        let searchURL : NSURL = NSURL(string: urlStr as String)!
        

        let imageData = NSData(contentsOf: searchURL as URL)
        
        if let imageContents = imageData {
            let image = UIImage(data: imageContents as Data)
            profileImageView.image = image
        } else {
            print("Unable to find Image for user named: " + "\(user.name)")
            profileImageView.image = UIImage(named: "Placeholder")
        }

        
    }
    
    func loginViewShowingLoggedOutUser(_ loginView: FBLoginView!) {
        profileImageView.isHidden = true
        nameLabel.isHidden = true
    }
    
    func loginView(_ loginView: FBLoginView!, handleError error: Error!) {
         print("Error: \(error.localizedDescription)")
    }

}
