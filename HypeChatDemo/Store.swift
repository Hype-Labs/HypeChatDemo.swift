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

import Foundation
import Hype

class Store {
   
    weak var delegate:StoreDelegate?
    private(set)var messages = [HYPMessage]()
    var instance: HYPInstance
    var isHasNewMessages: Bool = false
    var lastReadIndex: Int = 0
    
    init(instance: HYPInstance) {
    
        self.instance = instance
        lastReadIndex = 0
    }
    
    func add(_ message: HYPMessage) {
        
        messages.append(message)
        delegate?.didAdd(sender:self, message: message)
    }
    
    
    func hasNewMessages() -> Bool {
        return lastReadIndex < messages.count
    }
    
    func allMessages() -> [HYPMessage] {
        return [] + self.messages
    }
    
}
