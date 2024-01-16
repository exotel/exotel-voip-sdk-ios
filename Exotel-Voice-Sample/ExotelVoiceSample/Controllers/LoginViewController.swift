/*
 * Copyright (c) 2022 Exotel Techcom Pvt Ltd
 * All rights reserved
 */

import UIKit
import DropDown
import ExotelVoice

class LoginViewController: UIViewController, UITextViewDelegate {
    @IBOutlet weak var userIDTextView: UITextView!
    @IBOutlet weak var userIDTextViewHeight: NSLayoutConstraint!
    @IBOutlet weak var displayNameTextView: UITextView!
    @IBOutlet weak var displayNameTextViewHeight: NSLayoutConstraint!
    @IBOutlet weak var passwordTF: UITextField!
    @IBOutlet weak var accountTextView: UITextView!
    
    @IBOutlet weak var AdvanceSettingLable: UIButton!
    @IBOutlet weak var accountSID_Label: UILabel!
    @IBOutlet weak var hostname_Label: UILabel!
    @IBOutlet weak var advSettingViewHeight: NSLayoutConstraint!
    @IBOutlet weak var Adv_SettingView: UIView!
    @IBOutlet weak var hostnameTextView: UITextView!
    @IBOutlet weak var passwordToggleBtn: UIButton!
    var iconClick = false
    var advSettingBool = false
    let TAG = "LoginViewController"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        userIDTextView.delegate = self
        userIDTextView.tag = 1
        advSettingViewHeight.constant = 0
        
        accountSID_Label.isHidden = true
        hostname_Label.isHidden = true
        displayNameTextView.isHidden = true
        
        // Do any additional setup after loading the view.
        userIDTextView.delegate = self
        displayNameTextView.delegate = self
        accountTextView.delegate = self
        hostnameTextView.delegate = self
        userIDTextView.adjustUITextViewHeight()
        userIDTextViewHeight.constant = userIDTextView.frame.size.height
        displayNameTextView.adjustUITextViewHeight()
        displayNameTextViewHeight.constant = displayNameTextView.frame.size.height
        accountTextView.adjustUITextViewHeight()
        hostnameTextView.adjustUITextViewHeight()
        UITextField.appearance().tintColor = #colorLiteral(red: 1, green: 0.2509803922, blue: 0.5058823529, alpha: 1)
        UITextView.appearance().tintColor = #colorLiteral(red: 1, green: 0.2509803922, blue: 0.5058823529, alpha: 1)
        
        userIDTextView.autocapitalizationType = .none
        displayNameTextView.autocapitalizationType = .none
        passwordTF.autocapitalizationType = .none
        accountTextView.autocapitalizationType = .none
        hostnameTextView.autocapitalizationType = .none
        
        if UserDefaults.standard.string(forKey: UserDefaults.Keys.isLoggedIn.rawValue) == "true" {
            userIDTextView.text = UserDefaults.standard.string(forKey: UserDefaults.Keys.subscriberName.rawValue) ?? ""
            displayNameTextView.text = UserDefaults.standard.string(forKey: UserDefaults.Keys.displayName.rawValue) ?? ""
            accountTextView.text = UserDefaults.standard.string(forKey: UserDefaults.Keys.accountSID.rawValue) ?? ""
            hostnameTextView.text = UserDefaults.standard.string(forKey: UserDefaults.Keys.bellatrixHostName.rawValue) ?? ""
            passwordTF.text = UserDefaults.standard.string(forKey: UserDefaults.Keys.password.rawValue) ?? ""
            
            let userName = userIDTextView.text ?? ""
            let password = passwordTF.text ?? ""
            let hostName = hostnameTextView.text ?? ""
            let accountSID = accountTextView.text ?? ""
            let displayName = displayNameTextView.text ?? ""
            
            if !userName.isEmpty && !password.isEmpty && !hostName.isEmpty && !accountSID.isEmpty {
                if Connectivity.isConnectedToInternet() {
                    ApplicationUtils.svprogressHudShow(title: "Loading...", view: self)
                    ApplicationUtils.login(username: userName, password: password, hostname: hostName, accountSid: accountSID, displayName: displayName, viewController: self)
                } else {
                    ApplicationUtils.alert(message: "CHECK_INTERNET_CONNECTION", view: self)
                }
            }
        } else {
            UserDefaults.standard.set(userIDTextView.text, forKey: UserDefaults.Keys.subscriberName.rawValue)
            UserDefaults.standard.set(displayNameTextView.text, forKey: UserDefaults.Keys.displayName.rawValue)
            UserDefaults.standard.set(passwordTF.text, forKey: UserDefaults.Keys.password.rawValue)
            UserDefaults.standard.set(accountTextView.text, forKey: UserDefaults.Keys.accountSID.rawValue)
            UserDefaults.standard.set(hostnameTextView.text, forKey: UserDefaults.Keys.bellatrixHostName.rawValue)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        statusBarColorChange()
        NotificationCenter.default.addObserver(self, selector: #selector(self.onInitializationFailure), name: Notification.Name(rawValue: initFailedKey), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onInitializationSuccess), name: Notification.Name(rawValue: initSuccessKey), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onAuthenticationFailure), name: Notification.Name(rawValue: authFailedKey), object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: initSuccessKey), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: initFailedKey), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: authFailedKey), object: nil)
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if textView.tag == 1 {
            displayNameTextView.text = userIDTextView.text
        }
        userIDTextView.adjustUITextViewHeight()
        userIDTextViewHeight.constant = userIDTextView.frame.size.height
        displayNameTextView.adjustUITextViewHeight()
        displayNameTextViewHeight.constant = displayNameTextView.frame.size.height
        accountTextView.adjustUITextViewHeight()
        hostnameTextView.adjustUITextViewHeight()
    }
    
    @IBAction func passowrdToggleBtnAction(_ sender: UIButton) {
        if(iconClick == true) {
            passwordTF.isSecureTextEntry = true
            passwordToggleBtn.setImage(UIImage(named: "hideEye"), for: .normal)
            iconClick = false
        } else {
            passwordTF.isSecureTextEntry = false
            passwordToggleBtn.setImage(UIImage(named: "openEye"), for: .normal)
            iconClick = true
        }
    }
    
    @objc func onInitializationFailure(_ notifcation: NSNotification) {
        let error = notifcation.userInfo?["payload"] as? ExotelVoiceError
        VoiceAppLogger.debug(TAG: TAG, message: "Initialization Failure: \(error?.getErrorMessage() ?? "error")")
        ApplicationUtils.svprogressHudDismiss(view: self)
        var errMsg = error?.getErrorMessage()
        if error?.getErrorType() == .MISSING_PERMISSION {
            errMsg = missingMicrophonePermissionStr
        }
        ApplicationUtils.alert(message: errMsg ?? "Unknown Error in Initialization", view: self)
    }
    
    @objc func onInitializationSuccess(_ notification: NSNotification) {
        VoiceAppLogger.debug(TAG: TAG, message: "Initialization success.")
        ApplicationUtils.svprogressHudDismiss(view: self)
        DispatchQueue.main.async {
            let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let dailScreenVC = storyBoard.instantiateViewController(withIdentifier: "HomeViewController") as! HomeViewController
            self.navigationController?.pushViewController(dailScreenVC, animated: false)
        }
    }
    
    @objc func onAuthenticationFailure(notification: NSNotification) {
        let error: ExotelVoiceError = (notification.object as? ExotelVoiceError)!
        let errorMessage = ErrorType.enumToString(errorType: error.getErrorType()) + " : " + error.getErrorMessage()
        ApplicationUtils.alert(message: "Authentication Failure: \(errorMessage)" , view: self)
    }
    
    @IBAction func loginBtnAction(_ sender: UIButton) {
        self.view.endEditing(true)
        if userIDTextView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true {
            ApplicationUtils.alert(message: "Please Enter User Name", view: self)
        } else if displayNameTextView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true {
            ApplicationUtils.alert(message: "Please Enter Display Name", view: self)
        } else if passwordTF.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true {
            ApplicationUtils.alert(message: "Please Enter Password", view: self)
        } else if accountTextView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true {
            ApplicationUtils.alert(message: "Please Enter Account SID", view: self)
        } else if hostnameTextView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true {
            ApplicationUtils.alert(message: "Please Enter Hostname", view: self)
        } else {
            if !hostnameTextView.text.hasPrefix("http://") && !hostnameTextView.text.hasPrefix("https://") {
                ApplicationUtils.alert(message: "Hostname is not valid", view: self)
            } else {
                if Connectivity.isConnectedToInternet() {
                    let userName = userIDTextView.text ?? ""
                    let password = passwordTF.text ?? ""
                    let hostName = hostnameTextView.text ?? ""
                    let accountSID = accountTextView.text ?? ""
                    let displayName = displayNameTextView.text ?? ""
                    
                    UserDefaults.standard.set(userName, forKey: UserDefaults.Keys.subscriberName.rawValue)
                    UserDefaults.standard.set(password, forKey: UserDefaults.Keys.password.rawValue)
                    UserDefaults.standard.set(hostName, forKey: UserDefaults.Keys.bellatrixHostName.rawValue)
                    UserDefaults.standard.set(accountSID, forKey: UserDefaults.Keys.accountSID.rawValue)
                    UserDefaults.standard.set(displayName, forKey: UserDefaults.Keys.displayName.rawValue)
                    
                    ApplicationUtils.svprogressHudShow(title: "Loading...", view: self)
                    ApplicationUtils.login(username: userName, password: password, hostname: hostName, accountSid: accountSID, displayName: displayName, viewController: self)
                } else {
                    ApplicationUtils.alert(message: "CHECK_INTERNET_CONNECTION", view: self)
                }
            }
        }
    }
    
    @IBAction func advanceSettingAction(_ sender: UIButton) {
        if advSettingBool == true {
            advSettingViewHeight.constant = 247
            advSettingBool = false
            accountSID_Label.isHidden = false
            hostname_Label.isHidden = false
            displayNameTextView.isHidden = false
            AdvanceSettingLable.setImage(UIImage(named: "showAdvView"), for: .normal)
        } else {
            advSettingViewHeight.constant = 0
            advSettingBool = true
            accountSID_Label.isHidden = true
            hostname_Label.isHidden = true
            displayNameTextView.isHidden = true
            AdvanceSettingLable.setImage(UIImage(named: "hideAdvView"), for: .normal)
        }
        Adv_SettingView.layoutIfNeeded()
    }
}
