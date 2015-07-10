//
//  ViewController.swift
//  Fellow
//
//  Created by Mac-Triplei-Au on 7/6/2558 BE.
//  Copyright (c) 2558 Mac-Triplei-Au. All rights reserved.
//

import UIKit

class ViewController: UIViewController , PFLogInViewControllerDelegate, CLLocationManagerDelegate{
    
    var permissions = [ "public_profile", "email", "user_friends","user_likes"]
    var dict : NSDictionary!
    var logInController = PFLogInViewController()
    var locationManager:CLLocationManager!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.locationManager = CLLocationManager()
        locationManager.requestAlwaysAuthorization()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startMonitoringSignificantLocationChanges()
        
        
        logInController.delegate = self
    }
    
    func locationManager(manager: CLLocationManager!,   didUpdateLocations locations: [AnyObject]!) {
        var locValue:CLLocationCoordinate2D = manager.location.coordinate
        println("locations = \(locValue.latitude) \(locValue.longitude)")
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        var currentUser = PFUser.currentUser()
        if currentUser != nil {
            //Insert UserInfo into Parse
            updateUserLocation()
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
            //deleteUserLikeList(currentUser)
            FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "id, first_name, last_name, email"]).startWithCompletionHandler({ (connection, result, error) -> Void in
                if (error == nil){
                    self.dict = result as! NSDictionary
                    var userInfoObject = PFObject(className: "UserInfo")
                    userInfoObject["UserLoginID"] = currentUser.objectId
                    userInfoObject["FacebookID"] = self.dict.valueForKey("id")
                    userInfoObject["first_name"] = self.dict.valueForKey("first_name")
                    userInfoObject["last_name"] = self.dict.valueForKey("last_name")
                    userInfoObject["email"] = self.dict.valueForKey("email")
                    
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)){
                        
                        let FacebookID: AnyObject? = userInfoObject["FacebookID"]
                        
                        var query  = PFQuery(className: "UserInfo")
                        query.whereKey("FacebookID", equalTo: FacebookID!)
                        
                        var findObject: AnyObject? = query.findObjects()
                        
                        dispatch_async(dispatch_get_main_queue()) {
                            //Has findOject been recorded in ClassUserInfo?
                            if let findObj: AnyObject = findObject{
                                if findObj.count <= 0 {
                                    userInfoObject.save()
                                }else{
                                    //User has been recorded in class UserInfo
//                                    println("findObject = \(findObject!.count) meaning UserInfo has been recorded")
                                    
                                }
                                self.updateUserLocation()
                                self.saveFBLikeList()
                                
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
                        
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)){
                            
                            var query  = PFQuery(className: "Like")
                            query.whereKey("name", equalTo: dataItem )
                            var findObject: AnyObject? = query.findObjects()
                            
                            dispatch_async(dispatch_get_main_queue()) {
                                //Has findOject been recorded in ClassUserInfo?
                                if let findObj: AnyObject = findObject{
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
                    
                    if PFUser.currentUser() != nil {
                        self.saveUserLikeList(PFUser.currentUser()!)
                    }
                    
                }
            })
            
        }else{
            //User not has currentAccessToken
        }
    }
    
    func saveManualLikeList() {
        
    }
    
    func saveUserLikeList(currentUser: PFUser) {
        
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
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)){
                            var query  = PFQuery(className: "Like")
                            query.whereKey("name", equalTo: dataItem )
                            var findObjects = query.findObjects() as! [PFObject]
                            for findItem in findObjects {
                                
                                dispatch_async(dispatch_get_main_queue()) {
                                    //Has findOject been recorded in ClassUserInfo?
                                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)){
                                        var query  = PFQuery(className: "UserLike")
                                        query.whereKey("LikeID", equalTo: findItem.objectId! )
                                        var findObjects = query.findObjects() as! [PFObject]
                                        if findObjects.count == 0 {
                                            dispatch_async(dispatch_get_main_queue()) {
                                                var UserLikeObject = PFObject(className: "UserLike")
                                                UserLikeObject["UserID"] = currentUser.objectId
                                                UserLikeObject["LikeID"] = findItem.objectId
                                            
                                                UserLikeObject.save()
                                            }
                                        }
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
    
    func updateUserLocation() {
        var query = PFQuery(className:"UserLocation")
        query.whereKey("UserID", equalTo: PFUser.currentUser()!.objectId!)
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)){

            var findObjects = query.findObjects() as! [PFObject]
            
            dispatch_async(dispatch_get_main_queue(),{
                if findObjects.count <= 0 {
                    var newObj = PFObject(className: "UserLocation")
                    newObj["UserID"] = PFUser.currentUser()!.objectId!
                    newObj["GeoPoint"] = PFGeoPoint(latitude: self.locationManager.location.coordinate.latitude,longitude: self.locationManager.location.coordinate.longitude)
                    newObj.saveInBackground()
                }else{
                    query.getObjectInBackgroundWithId(findObjects[0].objectId!) {
                        (PFobj: PFObject?, error: NSError?) -> Void in
                        if error != nil {
                            println(error)
                        } else if let PFobj = PFobj {
                            PFobj["UserID"] = PFUser.currentUser()!.objectId!
                            PFobj["GeoPoint"] = PFGeoPoint(latitude: self.locationManager.location.coordinate.latitude,longitude: self.locationManager.location.coordinate.longitude)
                            PFobj.saveInBackground()
                        }
                    }
                }
                
            })
            
        }
    }
    
    func deleteUserLikeList(currentUser: PFUser) {
        var query = PFQuery(className: "UserLike")
        query.whereKey("UserID", equalTo: currentUser.objectId!)
        var findObjects = query.findObjects() as! [PFObject]
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)){
            for findItem in findObjects {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    findItem.delete()
                    
                })
            }
        }
    }
    
    // func เพื่อใช้ในการหาค่า Array ซ้ำ
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
            }else{
                println(error)
            }
        }
    }
}

