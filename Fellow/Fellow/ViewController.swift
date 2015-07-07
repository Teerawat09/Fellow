//
//  ViewController.swift
//  Fellow
//
//  Created by Mac-Triplei-Au on 7/6/2558 BE.
//  Copyright (c) 2558 Mac-Triplei-Au. All rights reserved.
//

import UIKit

class ViewController: UIViewController, FBSDKLoginButtonDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let pointX = self.view.frame.size.width / 2
        let pointY = self.view.frame.size.height * 0.75
        
        if (FBSDKAccessToken.currentAccessToken() != nil)
        {
            // User is already logged in, do work such as go to next view controller.
            
            //
            /* Or Show Logout Button
            let loginView : FBSDKLoginButton = FBSDKLoginButton()
            self.view.addSubview(loginView)
            loginView.center = CGPointMake(pointX, pointY)
            loginView.readPermissions = ["public_profile", "email", "user_friends","user_likes"]
            loginView.delegate = self

            self.returnUserLikesData()
            */
        }
        else
        {
            //ดำเนินการสร้างปุ่ม FB Login
            let loginView : FBSDKLoginButton = FBSDKLoginButton()
            self.view.addSubview(loginView)
            loginView.center = CGPointMake(pointX, pointY)
            loginView.readPermissions = ["public_profile", "email", "user_friends","user_likes"]
            loginView.delegate = self
        }
    }
    
    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {
        println("User Logged In")
        
        if ((error) != nil)
        {
            // Process error
        }
        else if result.isCancelled {
            // Handle cancellations
        }
        else {
            // If you ask for multiple permissions at once, you
            // should check if specific permissions missing
            if result.grantedPermissions.contains("email")
            {
                // Do work
            }
        }
    }
    
    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
//        code
    }
    
    func returnUserData()
    {
        //function ทำการอ่านข้อมูลเบื้องต้น
        let graphRequest : FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me", parameters: nil)
        graphRequest.startWithCompletionHandler({ (connection, result, error) -> Void in
            
            if ((error) != nil)
            {
                // Process error
                println("Error: \(error)")
            }
            else
            {
                println("fetched user: \(result)")
                let userName : NSString = result.valueForKey("name") as! NSString
                println("User Name is: \(userName)")
                let userEmail : NSString = result.valueForKey("email") as! NSString
                println("User Email is: \(userEmail)")
            }
        })
    }
    
    func returnUserLikesData()
    {
        //function  ทำการอ่านข้อมูล Like
        let graphRequest : FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me/likes?fields=name&limit=100", parameters: nil)
        graphRequest.startWithCompletionHandler({ (connection, result, error) -> Void in
            
            if ((error) != nil)
            {
                // Process error
                println("Error: \(error)")
            }
            else
            {
                let likesData : NSArray = result.valueForKey("data") as! NSArray
                
                var likesListName = [String]()
                for likeItemName in likesData {
                    let values: NSDictionary = likeItemName as! NSDictionary
                    likesListName.append(values.valueForKey("name") as! String)
                }
                println("likeList\(likesListName)")
            }
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

