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

class ChatViewController: UIViewController, UITableViewDataSource, StoreDelegate{
    
    private var _store:Store?
    
    var store: Store? {
        
        set {
            _store = newValue
            _store?.delegate = self
        }
        
        get {
            return _store;
        }
    }
    
    @IBOutlet weak var instanceIdentifier: UILabel!
    @IBOutlet weak var messageDisplay: UITableView!
    @IBOutlet weak var textView: UITextField!
    @objc(keyboardWillHideWithNotification:)
    
    @IBAction func didTapSendButton(_ sender: Any) {
        
        let text: String = textView.text!
        
        if (text.count) > 0 {
            
            // When sending content there must be some sort of protocol that both parties
            // understand. In this case, we simply send the text encoded in UTF8. The data
            // must be decoded when received, using the same encoding.
            let data: Data? = text.data(using: String.Encoding.utf8)
            
            let message: HYPMessage? = HYP.send(data, to: store?.instance)
            
            // Clear the input view
            textView.text = ""
            
            // Adding the message to the store updates the table view
            store?.add(message!)
        }
    }
    
    func didAdd(sender: Store, message: HYPMessage) {
        
        // Reloads the data and scrolls the table to the bottom. The UX for this is not
        // very good if there are not enough messags to fill the table, but it's nice
        // otherwise.
        messageDisplay.reloadData()
        messageDisplay.scrollToRow(at: IndexPath(row: (self.store?.allMessages().count)! - 1, section: 0), at: .bottom, animated: true)
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        messageDisplay.dataSource = self
    }
   
    override func viewDidAppear(_ animated: Bool) {
        
        // Sets all messages as read
        store?.lastReadIndex = store!.allMessages().count
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {

        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return store!.allMessages().count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Table view cells are reused and should be dequeued using a cell identifier.
        let cellIdentifier = "MessageTableViewCell"
        
        var cell:UITableViewCell? = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        
        let message: HYPMessage? = (store?.allMessages()[indexPath.row])
        
        if cell == nil {

            cell = MessageTableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: cellIdentifier, message: message!)
        }
        else {
            (cell as? MessageTableViewCell)?.message = message
        }
        
        // Initialize the cell
        (cell as? MessageTableViewCell)?.textView.text =  (NSString(data: (message?.data)!, encoding: String.Encoding.utf8.rawValue)! as String)
        
        return cell!
    }
    
    @IBAction func didRecognizeTapGesture(_ sender: Any) {
        textView.resignFirstResponder()
    }

    @objc func keyboardWillShow(notification: NSNotification) {
        
        let info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        UIView.animate(withDuration: 0.1, animations: { () -> Void in
            var f: CGRect = self.view.frame
            f.origin.y = -keyboardFrame.size.height
            self.view.frame = f
        })
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        UIView.animate(withDuration: 0.3, animations: {() -> Void in
            var f: CGRect = self.view.frame
            f.origin.y = 0.0
            self.view.frame = f
        })
    }
}
