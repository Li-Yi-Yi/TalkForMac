//
//  ViewController.swift
//  TalkClient
//
//  Created by 吳淑菁 on 2017/9/6.
//
//

import Cocoa
import RxSwift
import RxCocoa
import AppKit

class ViewController: NSViewController {

    var disposeBag = DisposeBag()
    
    @IBOutlet var testLogin: NSButton!
    @IBOutlet var userName: NSTextField!
    @IBOutlet var userPassword: NSTextField!
    
    var xmppManager: IMXMPPManager!

    override func viewDidLoad() {
        super.viewDidLoad()

        
        self.xmppManager = IMXMPPManager.sharedXmppManager
        self.xmppManager.failHandler = {(message) -> Void in
            //IMProgressHUD.im_showErrorWithStatus(string: message!)
            
            self.showPrompt(prompt:  message!)
        }
        
        self.xmppManager.successHandler = { (userProfile) -> Void in
            IMSessionManager.sharedSessionManager.login(userProfile: userProfile)
        }

        
        testLogin.rx.tap.subscribe(onNext:{ [weak self] _ in
            
            guard let strongSelf = self else{return}
            if strongSelf.userName!.stringValue.isEmpty || strongSelf.userPassword!.stringValue.isEmpty {
                strongSelf.showPrompt(prompt:  "请输入用户名和密码")
                return
            }
            let name = strongSelf.userName!.stringValue
            let pass = strongSelf.userPassword!.stringValue
            
            IMXMPPManager.sharedXmppManager.loginWithuserName(userName: name, password: pass, isLogined: false)
        
        }).disposed(by: disposeBag)

        
    }
    
    

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    
    
}

extension ViewController {
    
    static func freshController() -> ViewController {
        let storyboard = NSStoryboard (name: "Main", bundle: nil)
        
        guard let viewcontroller = storyboard.instantiateController(withIdentifier: "regular") as? ViewController
            else {
                fatalError("regularVC not found? - Check storyboard")
        }
        return viewcontroller
    }
}


