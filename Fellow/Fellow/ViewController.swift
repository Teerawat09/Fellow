//
//  ViewController.swift
//  Fellow
//
//  Created by Mac-Triplei-Au on 7/6/2558 BE.
//  Copyright (c) 2558 Mac-Triplei-Au. All rights reserved.
//

import UIKit

class ViewController: UIViewController , PFLogInViewControllerDelegate{
    
    var permissions = [ "public_profile", "email", "user_friends","user_likes"]
    var dict : NSDictionary!
    var logInController = PFLogInViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        logInController.delegate = self
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        
        var currentUser = PFUser.currentUser()
        if currentUser != nil {
            //Insert UserInfo into Parse
            saveUserInfo(currentUser!)
        } else {
            // Show the signup or login screen
            showPFLoginViewController()
        }
    }
    
    func logInViewController(logInController: PFLogInViewController, didLogInUser user: PFUser) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func showPFLoginViewController(){
        // Show the signup or login screen
//        var logInController = PFLogInViewController()
        logInController.fields = (PFLogInFields.Facebook)
        logInController.facebookPermissions = permissions
        self.presentViewController(logInController, animated:true, completion:nil)
    }
    
    func saveUserInfo(currentUser: PFUser){
        // Do stuff with the user
        if((FBSDKAccessToken.currentAccessToken()) != nil){
            FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "id, first_name, last_name, email"]).startWithCompletionHandler({ (connection, result, error) -> Void in
                if (error == nil){
                    self.dict = result as! NSDictionary
                    var userInfoObject = PFObject(className: "UserInfo")
                    userInfoObject["UserLoginID"] = currentUser.objectId
                    userInfoObject["FacebookID"] = self.dict.valueForKey("id")
                    userInfoObject["first_name"] = self.dict.valueForKey("first_name")
                    userInfoObject["last_name"] = self.dict.valueForKey("last_name")
                    userInfoObject["email"] = self.dict.valueForKey("email")
                    userInfoObject.pinInBackground()
                    
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)){
                        
                        let FacebookID: AnyObject? = userInfoObject["FacebookID"]
                        
                        var query  = PFQuery(className: "UserInfo")
                        query.whereKey("FacebookID", equalTo: FacebookID!)
                        
                        var findObject: AnyObject? = query.findObjects()
                        
                        dispatch_async(dispatch_get_main_queue()) {
                            //Has findOject been recorded in ClassUserInfo?
                            if let findObj: AnyObject = findObject{
                                if findObj.count <= 0 {
                                    userInfoObject.saveInBackground()
                                    self.saveFBLikeList()
                                }else{
                                    //User has been recorded in class UserInfo
//                                    println("findObject = \(findObject!.count) meaning UserInfo has been recorded")
                                    self.saveFBLikeList()
                                }
                            }
                        }
                    }
                }
            })
            
        }else{
            //User not has currentAccessToken
        }
        
    }
    
    //inner func saveFBLikeList
    func saveFBLikeList(){
        if((FBSDKAccessToken.currentAccessToken()) != nil){
            
            FBSDKGraphRequest(graphPath: "me/likes?pretty=0&limit=999", parameters: nil).startWithCompletionHandler({ (connection, result, error) -> Void in
                if (error == nil){
                    self.dict = result as! NSDictionary
                    var dataList: NSArray? = self.dict.valueForKey("data") as? NSArray
                    
                    var likeListName:[NSString] = []
                    
                    for item in dataList!{
                        likeListName.append( (item["name"] as! NSString).lowercaseString )
                    }
                    
                    likeListName = self.uniq(likeListName)
                    
                    for dataItem in likeListName {
                        var likeObject = PFObject(className: "Like")
                        likeObject["name"] = dataItem
                        likeObject.pinInBackground()
                        
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)){
                            
                            var query  = PFQuery(className: "Like")
                            query.whereKey("name", equalTo: dataItem )
                            
                            var findObject: AnyObject? = query.findObjects()
                            
                            dispatch_async(dispatch_get_main_queue()) {
                                //Has findOject been recorded in ClassUserInfo?
                                if let findObj: AnyObject = findObject{
                                    println("count: \(findObj.count) name: \(likeObject)")
                                    if findObj.count <= 0 {
                                        
                                        likeObject.save()
                                    }else{
                                        //User has been recorded in class UserInfo
//                                        println("findObject = \(findObject!.count) meaning UserInfo has been recorded")
                                    }
                                }
                                
                            }
                        }
                    }
                }
            })
            
        }else{
            //User not has currentAccessToken
        }
    }
    
    func saveManualLikeList(){
        
    }
    
    func uniq<S : SequenceType, T : Hashable where S.Generator.Element == T>(source: S) -> [T] {
        var buffer = [T]()
        var added = Set<T>()
        for elem in source {
            if !added.contains(elem) {
                buffer.append(elem)
                added.insert(elem)
            }
        }
        return buffer
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func didTapFacebookConnect(sender: AnyObject) {
        PFUser.logOutInBackgroundWithBlock { ( error:NSError?) -> Void in
            if error == nil {
                self.showPFLoginViewController()
            }
        }
        
    }
}

