//
// MIT License
//
// Copyright (C) 2018 HypeLabs Inc.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

import UIKit
import Hype

class ContactViewController:  UIViewController, UITableViewDelegate, UITableViewDataSource, HYPStateObserver, HYPNetworkObserver, HYPMessageObserver {

    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var hypeInstancesTextField: UITextField!
    @IBOutlet weak var hypeAnnouncementLabel: UILabel!
    
    // The stores object keeps track of message storage associated with each instance (peer)
    var stores = [String: Store]()
    var announcement: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.announcement = UIDevice.current.name
        self.hypeAnnouncementLabel.text = "Device: " + announcement

        // If Hype starts successfully, the table should start displaying peers soon
        requestHypeToStart()
    }

    func requestHypeToStart() {

        // Add self as an Hype observer
        HYP.add(self as HYPStateObserver)
        HYP.add(self as HYPNetworkObserver)
        HYP.add(self as HYPMessageObserver)
        
        HYP.setAnnouncement(self.announcement.data(using: .utf8))
        
        // Generate an app identifier in the HypeLabs dashboard (https://hypelabs.io/apps/),
        // by creating a new app. Copy the given identifier here.
        HYP.setAppIdentifier("{{app_identifier}}")

        HYP.start()
        
        // Update the text label
        self.updateHypeInstancesLabel()
    }

    func hypeDidStart() {

        NSLog("Hype started!")
    }

    func hypeDidStopWithError(_ error: HYPError!) {

        let description:String! = error == nil ? "" : error.description
        NSLog("Hype stopped [%@]", description)
    }

    func hypeDidFailStartingWithError(_ error: HYPError!) {

        NSLog("Hype failed starting [%@]", error.description)
        
        let errorMessage : String = "Description: " + (error.description as String) + "\nReason:" + (error.reason as String)  + "\nSuggestion:" + (error.suggestion as String)
        let alert = UIAlertController(title: "Hype failed starting", message: errorMessage, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    func hypeDidBecomeReady() {

        NSLog("Hype is ready")

        // Where're here due to a failed start request, try again
        requestHypeToStart()
    }

    func hypeDidChangeState()
    {
        
        NSLog("Hype state changed to [%d] (Idle=0, Starting=1, Running=2, Stopping=3)", HYP.state().rawValue)
    }
    
    func shouldResolveInstance(_ instance: HYPInstance!) -> Bool
    {
        // This method can be used to decide whether an instance is interesting
        return true
    }

    func hypeDidFind(_ instance: HYPInstance!) {

        NSLog("Hype found instance: %@", instance.stringIdentifier)
        
        // Resolve instances that matter
        if shouldResolveInstance(instance) {
            HYP.resolve(instance)
        }
    }

    func hypeDidLose(_ instance: HYPInstance!, error: HYPError!) {

        DispatchQueue.main.async {

            let description:String! = error == nil ? "" : error.description
            NSLog("Hype Lost instance: %@ [%@]", instance.stringIdentifier, description)

            // Clean up
            self.removeFromResolvedInstancesDict(instance)
        }
    }

    func hypeDidResolve(_ instance: HYPInstance!)
    {
        NSLog("Hype resolved instance: %@", instance.stringIdentifier)
        
        // This device is now capable of communicating
        addToResolvedInstancesDict(instance)
    }

    func hypeDidFailResolving(_ instance: HYPInstance!, error: HYPError!)
    {
        let description:String! = error == nil ? "" : error.description
        NSLog("Hype failed resolving instance: %@ [%@]", instance.stringIdentifier, description)
    }

    func hypeDidReceive(_ message: HYPMessage!, from fromInstance: HYPInstance!) {

        DispatchQueue.main.async {

            NSLog("Hype got a message from: %@", fromInstance.stringIdentifier)

            let store = self.stores[fromInstance.stringIdentifier]

            // Storing the message triggers a reload update in the chat view controller
            store?.add(message, isMessageReceived: true)

            // The data is reloaded so the green circle indicator is shown for contacts that have new
            // messages. Reloading is probably an overkill, but the point is to maintain focus on how
            // the framework works.
            self.tableView.reloadData()
        }
    }

    func hypeDidFailSendingMessage(_ messageInfo: HYPMessageInfo!, to toInstance: HYPInstance!, error: HYPError!) {

        NSLog("Hype failed to send message: %d [%@]", UInt(messageInfo.identifier), error.description)
    }

    func hypeDidSendMessage(_ messageInfo: HYPMessageInfo!, to toInstance: HYPInstance!, progress: Float, complete: Bool) {

        NSLog("Hype is sending a message: %f", progress)
    }

    func hypeDidDeliverMessage(_ messageInfo: HYPMessageInfo!, to toInstance: HYPInstance!, progress: Float, complete: Bool) {

        NSLog("Hype delivered a message: %f", progress)
    }
    
    func hypeDidRequestAccessToken(withUserIdentifier userIdentifier: UInt) -> String!
    {
        return "{{access_token}}"
    }

    func addToResolvedInstancesDict(_ instance: HYPInstance)
    {
        DispatchQueue.main.async {
            self.stores.updateValue(Store (instance: instance), forKey: instance.stringIdentifier)

            // Reloading the table reflects the change
            self.tableView.reloadData()
            self.updateHypeInstancesLabel()

        }
    }

    func removeFromResolvedInstancesDict(_ instance: HYPInstance)
    {
        DispatchQueue.main.async {
            self.stores.removeValue(forKey: instance.stringIdentifier)

            // Reloading the table reflects the change
            self.tableView.reloadData()
            self.updateHypeInstancesLabel()
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.stores.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        // Table view cells are reused and should be dequeued using a cell identifier.
        let cellIdentifier = "ContactTableViewCell"

        var cell:UITableViewCell? = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)

        let store = Array(stores.values)[indexPath.row]

        if cell == nil {
            cell = ContactTableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: cellIdentifier, store: store)
        }
        else {
            (cell as? ContactTableViewCell)?.store = store
        }

        // Configure the cell to display information from the found instance. The description is
        // a feature that has not yet been made available by the framework, which consists of
        // each peer putting an "announcement" on the network that helps identifying the
        // running instance.
        (cell as? ContactTableViewCell)?.displayName.text = store.instance.stringIdentifier
        (cell as? ContactTableViewCell)?.contentIndicator.isHidden = !store.hasNewMessages()
        if (store.instance.announcement != nil) {
            (cell as? ContactTableViewCell)?.details.text = String(data: store.instance.announcement, encoding: .utf8)
        }
        else {
            (cell as? ContactTableViewCell)?.details.text = ""; // if no announcement is specified nothing is shown
        }

        return cell!
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }

    override func viewWillAppear(_ animated: Bool) {
        tableView.reloadData()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        let vc: ChatViewController? = (segue.destination as! ChatViewController)

        // Pass the store along when the segue executes
        vc?.store = (sender as! ContactTableViewCell).store!
        
        if (vc?.store?.instance.announcement != nil) {
            vc?.instanceAnnouncement?.text = String(data: (vc!.store!.instance.announcement)!, encoding: .utf8)
        }
        else {
            vc?.instanceAnnouncement?.text = "" // if no announcement is specified nothing is shown
        }
    }
    
    func updateHypeInstancesLabel()
    {
        if (self.stores.count == 0) {
            self.hypeInstancesTextField.text = "No Hype Devices Found"
        }
        else {
            self.hypeInstancesTextField.text = "Hype Devices Found: " + String(self.stores.count)
        }
    }
}
