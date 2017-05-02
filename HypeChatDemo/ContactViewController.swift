//
// The MIT License (MIT)
// Copyright (c) 2016 Hype Labs Ltd
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is furnished to do
// so, subject to the following conditions:
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

class ContactViewController:  UITableViewController, HYPStateObserver, HYPNetworkObserver, HYPMessageObserver{
 
    // The stores object keeps track of message storage associated with each instance (peer)
    var stores = [String: Store]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Request Hype to start when the view loads. If this is successful the table
        // should start displaying other peers soon. Notice that it's OK to request the
        // framework to start if it's already running, so this method can be called
        // several times.
        requestHypeToStart()
    }
    
    func requestHypeToStart() {
        
        // notifications for lifecycle events being triggered by the Hype framework. These
        // events include starting and stopping, as well as some error handling.
        HYP.instance().add(self as HYPStateObserver)
        
        // Network observer notifications include other devices entering and leaving the
        // network. When a device is found all observers get a -hype:didFindInstance:
        // notification, and when they leave -hype:didLoseInstance:error: is triggered instead.
        HYP.instance().add(self as HYPNetworkObserver)
        
        // Message notifications indicate when messages are sent (not available yet) or fail
        // to be sent. Notice that a message being sent does not imply that it has been
        // delivered, only that it has left the device. If considering mesh networking,
        // in which devices will be forwarding content for each other, a message being
        // means that its contents have been flushed out of the output stream, but not
        // that they have reached their destination. This, in turn, is what acknowledgements
        // are used for, but those have not yet available.
        HYP.instance().add(self as HYPMessageObserver)
        
        // Requesting Hype to start is equivalent to requesting the device to publish
        // itself on the network and start browsing for other devices in proximity. If
        // everything goes well, the -hypeDidStart: delegate method gets called, indicating
        // that the device is actively participating on the network. The 00000000 realm is
        // reserved for test apps, so it's not recommended that apps are shipped with it.
        // For generating a realm go to https://hypelabs.io, login, access the dashboard
        // under the Apps section and click "Create New App". The resulting app should
        // display a realm number. Copy and paste that here.
        HYP.instance().start(options: [HYPOptionRealmKey:"00000000"])
    }
    
    func hypeDidStart(_ hype: HYP!) {
        
        // At this point, the device is actively participating on the network. Other devices
        // (instances) can be found at any time and the domestic (this) device can be found
        // by others. When that happens, the two devices should be ready to communicate.
        print("Hype started!")
    }
    
    func hypeDidStop(_ hype: HYP!, error: Error!) {
        
        // The framework has stopped working for some reason. If it was asked to do so (by
        // calling -stop) the error parameter is nil. If, on the other hand, it was forced
        // by some external means, the error parameter indicates the cause. Common causes
        // include the user turning the Bluetooth and/or Wi-Fi adapters off. When the later
        // happens, you shouldn't attempt to start the Hype services again. Instead, the
        // framework triggers a -hypeDidBecomeReady: delegate method if recovery from the
        // failure becomes possible.
        print("Hype stoped [\(String(describing: error?.localizedDescription))]")
    }
    
    func hypeDidFailStarting(_ hype: HYP!, error: Error!) {
        
        // Hype couldn't start its services. Usually this means that all adapters (Wi-Fi
        // and Bluetooth) are not on, and as such the device is incapable of participating
        // on the network. The error parameter indicates the cause for the failure. Attempting
        // to restart the services is futile at this point. Instead, the implementation should
        // wait for the framework to trigger a -hypeDidBecomeReady: notification, indicating
        // that recovery is possible, and start the services then.
        print("Hype failed starting [\(String(describing: error?.localizedDescription))]")
        
    }
    
    func hypeDidBecomeReady(_ hype: HYP!) {
        
        // This Hype delegate event indicates that the framework believes that it's capable
        // of recovering from a previous start failure. This event is only triggered once.
        // It's not guaranteed that starting the services will result in success, but it's
        // known to be highly likely. If the services are not needed at this point it's
        // possible to delay the execution for later, but it's not guaranteed that the
        // recovery conditions will still hold by then.
        requestHypeToStart()
    }
    
    func hype(_ hype: HYP!, didFind instance: HYPInstance!) {
        
        DispatchQueue.main.async {
            
            // Hype instances that are participating on the network are identified by a full
            // UUID, composed by the vendor's realm followed by a unique identifier generated
            // for each instance.
            print("Found instance: \(instance.stringIdentifier)")
            
            // Instances should be strongly kept by some data structure. Their identifiers
            // are useful for keeping track of which instances are ready to communicate.
            
            self.stores.updateValue(Store (instance: instance), forKey: instance.stringIdentifier)
            
            // Reloading the table reflects the change
            self.tableView.reloadData()
        }
    }
    
    func hype(_ hype: HYP!, didLose instance: HYPInstance!, error: Error!) {
        
        DispatchQueue.main.async {
            
            // An instance being lost means that communicating with it is no longer possible.
            // This usually happens by the link being broken. This can happen if the connection
            // times out or the device goes out of range. Another possibility is the user turning
            // the adapters off, in which case not only are all instances lost but the framework
            // also stops with an error.
            print("Lost instance: \(instance.stringIdentifier) [\(String(describing: error.localizedDescription))]")
            
            // Cleaning up is always a good idea. It's not possible to communicate with instances
            // that were previously lost.
            self.stores.removeValue(forKey: instance.stringIdentifier)
            
            // Reloading the table reflects the change
            self.tableView.reloadData()
        }
    }
    
    func hype(_ hype: HYP!, didReceive message: HYPMessage!, from fromInstance: HYPInstance!) {
        
        DispatchQueue.main.async {
            
            print("Got a message from: \(fromInstance.stringIdentifier)")
            
            let store = self.stores[fromInstance.stringIdentifier]
            
            // Storing the message triggers a reload update in the chat view controller
            store?.add(message)
            
            // The data is reloaded so the green circle indicator is shown for contacts that have new
            // messages. Reloading is probably an overkill, but the point is to maintain focus on how
            // the framework works.
            self.tableView.reloadData()
        }
    }
    
    func hype(_ hype: HYP!, didFailSendingMessage messageInfo: HYPMessageInfo!, to toInstance: HYPInstance!, error: Error!) {
        
        // Sending messages can fail for a lot of reasons, such as the adapters
        // (Bluetooth and Wi-Fi) being turned off by the user while the process
        // of sending the data is still ongoing. The error parameter describes
        // the cause for the failure.
        print("Failed to send message: \(UInt(messageInfo.identifier)) [\(error.localizedDescription)]")
        
    }
    
    func hype(_ hype: HYP!, didSendMessage messageInfo: HYPMessageInfo!, to toInstance: HYPInstance!, progress: Float, complete: Bool) {
        
        // A message being "sent" indicates that it has been written to the output
        // streams. However, the content could still be buffered for output, so it
        // has not necessarily left the device. This is useful to indicate when a
        // message is being processed, but it does not indicate delivery by the
        // destination device.
        print("Message being sent: \(progress)")
    }
    
    func hype(_ hype: HYP!, didDeliverMessage messageInfo: HYPMessageInfo!, to toInstance: HYPInstance!, progress: Float, complete: Bool) {
        
        // A message being delivered indicates that the destination device has
        // acknowledge reception. If the "done" argument is true, then the message
        // has been fully delivered and the content is available on the destination
        // device. This method is useful for implementing progress bars.
        print("Message being delivered: \(progress)")
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.stores.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
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
        (cell as? ContactTableViewCell)?.details.text = "Description not available";
        (cell as? ContactTableViewCell)?.contentIndicator.isHidden = !store.hasNewMessages();
 
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tableView.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        let vc: ChatViewController? = (segue.destination as! ChatViewController)
        
        // Pass the store along when the segue executes
        vc?.store = (sender as! ContactTableViewCell).store!
        vc?.instanceIdentifier?.text = vc?.store?.instance.stringIdentifier
    }
}
