//
//  LayerVC.swift
//  
//
//  Created by Mac-Triplei-Au on 7/14/2558 BE.
//
//

import UIKit

class LayerVC: UIViewController {
    
    var layerClient: LYRClient!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewWillDisappear(true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func sendNotification(){
        // Find users near a given location
        let myCompanyLocation = PFGeoPoint(latitude: 13.904837646718576, longitude: 100.52979811952365)
        
        // Find users near a given location
        let userQuery = PFUser.query()
        userQuery!.whereKey("location", nearGeoPoint: myCompanyLocation, withinMiles: 1)
        
        // Find devices associated with these users
        let pushQuery = PFInstallation.query()
        pushQuery!.whereKey("user", matchesQuery: userQuery!)
        
        // Send push notification to query
        let push = PFPush()
        push.setQuery(pushQuery) // Set our Installation query
        push.setMessage("You are near at my Company")
        push.sendPushInBackground()
    }
    
    @IBAction func didTapSendNotify(sender: AnyObject) {
        sendNotification()
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
