//
//  AppDelegate.swift
//  Fellow
//
//  Created by Mac-Triplei-Au on 7/6/2558 BE.
//  Copyright (c) 2558 Mac-Triplei-Au. All rights reserved.
//



import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate{

    var window: UIWindow?
    
    var lastViewController: AnyObject?
    
    var getUserInfo: [NSObject : AnyObject] = [:]
    
    let ParseAppIDString: String = "QvrS99pSLUBnS3UiYlPDCL2BeP0riwYz1OncSCp7"
    let ParseClientKeyString: String = "BsWsJoRXsIFPRXi5E2UQ2aa1BaXDKFZJjfRFhjm8"
    
    var layerClient : LYRClient!

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        //setupParse
        setupParse()
        PFFacebookUtils.initializeFacebookWithApplicationLaunchOptions(launchOptions)
        
        let userNotificationTypes = (UIUserNotificationType.Alert |  UIUserNotificationType.Badge |  UIUserNotificationType.Sound);
        
        let settings = UIUserNotificationSettings(forTypes: userNotificationTypes, categories: nil)
        application.registerUserNotificationSettings(settings)
        application.registerForRemoteNotifications()
        
        // Extract the notification data
        if let notificationPayload = launchOptions?[UIApplicationLaunchOptionsRemoteNotificationKey] as? NSDictionary {
            NotificationOpenLayerView()
        }
        
        //Initializes a LYRClient object
        var urlLayerAppID = NSURL(string: "layer:///apps/staging/b6217282-23a6-11e5-8729-77a47d007ada")
        layerClient = LYRClient(appID: urlLayerAppID)
        
        // Tells LYRClient to establish a connection with the Layer service
        layerClient.connectWithCompletion { (success, error) -> Void in
            if (success){
                println("Client is connected!")
            }else{
                println("Layer error \(error)")
            }
        }
        // Show View Controller
//        let rootViewController = self.window?.rootViewController
//        
//        let mainStoryboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
//        var VC = mainStoryboard.instantiateViewControllerWithIdentifier("ViewController") as! ViewController
//        VC.layerClient = self.layerClient
//        self.window!.rootViewController = UINavigationController(rootViewController: VC)
//        self.window!.makeKeyAndVisible()
        
        
        return true
    }
    
    func application(application: UIApplication,
        openURL url: NSURL,
        sourceApplication: String?,
        annotation: AnyObject?) -> Bool {
            return FBSDKApplicationDelegate.sharedInstance().application(
                application,
                openURL: url,
                sourceApplication: sourceApplication,
                annotation: annotation)
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        // Store the deviceToken in the current Installation and save it to Parse
        let installation = PFInstallation.currentInstallation()
        installation.setDeviceTokenFromData(deviceToken)
        installation.saveInBackground()
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        self.getUserInfo = userInfo
        completionHandler(UIBackgroundFetchResult.NewData)
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        // Extract the notification data
        
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        FBSDKAppEvents.activateApp()
        
        if self.getUserInfo.count != 0{
            NotificationOpenLayerView()
        }
        
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func setupParse() {
        // Enable Parse local data store for user persistence
        Parse.enableLocalDatastore()
        Parse.setApplicationId(ParseAppIDString, clientKey: ParseClientKeyString)
        
        // Set default ACLs
        let defaultACL: PFACL = PFACL()
        defaultACL.setPublicReadAccess(true)
        PFACL.setDefaultACL(defaultACL, withAccessForCurrentUser: true)
    }
    
    func NotificationOpenLayerView(){
        var token : dispatch_once_t = 0
        dispatch_once(&token) { () -> Void in
            
            let childViews = self.window?.rootViewController?.childViewControllers
            
            let rootViewController = self.window?.rootViewController as! UINavigationController
            
            let mainStoryboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            var VC = mainStoryboard.instantiateViewControllerWithIdentifier("ViewController") as! ViewController
            
            let navController = UINavigationController(rootViewController: VC) as UINavigationController
            
            var chatListVC : ConversationListViewController = ConversationListViewController(layerClient: self.layerClient)
            
            if !(childViews!.last!.isKindOfClass(ConversationListViewController)) {
                rootViewController.pushViewController(chatListVC, animated: true)
            }
            
            
            self.getUserInfo = [:]
        }
    }


}

