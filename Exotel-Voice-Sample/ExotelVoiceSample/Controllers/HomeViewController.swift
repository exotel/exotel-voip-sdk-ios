/*
 * Copyright (c) 2022 Exotel Techcom Pvt Ltd
 * All rights reserved
 */

import UIKit
import DropDown
import ExotelVoice

class HomeViewController: UIViewController, UITextViewDelegate {
    @IBOutlet weak var userNameLbl: UILabel!
    @IBOutlet weak var initStausLbl: UILabel!
    @IBOutlet weak var dialBottomLine: UILabel!
    @IBOutlet weak var contactBottomLine: UILabel!
    @IBOutlet weak var contactHideView: UIView!
    @IBOutlet weak var contactTableView: UITableView!
    @IBOutlet weak var recentCallsBottomLine: UILabel!
    @IBOutlet weak var recentCallsHideView: UIView!
    @IBOutlet weak var recentCallsTableView: UITableView!
    @IBOutlet weak var blurView: UIView!
    @IBOutlet weak var dialToTextView: UITextView!
    @IBOutlet weak var reportPrblmView: UIView!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var descriptionTextViewHeight: NSLayoutConstraint!
    @IBOutlet weak var callFeedbackView: UIView!
    @IBOutlet weak var ratingLbl: UILabel!
    @IBOutlet weak var issuesLbl: UILabel!
    @IBOutlet weak var dropFrameView: UIView!
    @IBOutlet weak var dialTabLable: UILabel!
    @IBOutlet weak var contactsTabLable: UILabel!
    @IBOutlet weak var recentCallsTabLable: UILabel!
    @IBOutlet weak var menuBtn: UIButton!
    @IBOutlet weak var scrollView_ToDial: UIScrollView!
    @IBOutlet weak var ToDialView: UIView!
    @IBOutlet weak var whatsappButton: UIButton!
    @IBOutlet weak var contactSearchBar: UISearchBar!
    
    private let TAG = "HomeViewController"
    private let DAY_IN_MS: Double = 1000 * 60 * 60 * 24;
    private let UPLOAD_LOG_NUM_DAYS: Int = 7;
    private let dropDown = DropDown()
    private let databaseHelper = DatabaseHelper.shared
    private var recentCallsData: [RecentCallDetails] = [RecentCallDetails]()
    private var destinationNumber: String = ""
    private var contactGrouparray:[sectionData]?
    private var searchContactGrouparray:[sectionData]? = []
    private var is_special:Bool = false
    private var isSearchingContact:Bool = false;
    let refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        VoiceAppLogger.debug(TAG: TAG, message: "Home View Controller loaded")
        
        userNameLbl.text = UserDefaults.standard.string(forKey: UserDefaults.Keys.subscriberName.rawValue)
        
        blurView.isHidden = true
        callFeedbackView.isHidden = true
        reportPrblmView.isHidden = true
        
        descriptionTextView.delegate = self
        descriptionTextView.adjustUITextViewHeight()
        descriptionTextViewHeight.constant = 40
        
        dialToTextView.autocapitalizationType = .none
        dialToTextView.text = ""
        
        whatsappButton.isHidden = true; // hide whatspp call button
        
        recentCallsTableView.delegate = self
        recentCallsTableView.dataSource = self
        recentCallsTableView.estimatedRowHeight = 60
        recentCallsTableView.rowHeight = UITableView.automaticDimension
        
        contactTableView.delegate = self
        contactTableView.dataSource = self
        contactTableView.estimatedRowHeight = 60
        contactTableView.rowHeight = UITableView.automaticDimension
        contactSearchBar.delegate = self;
        
        loadDefaultHomeView()
        updateStatus()
        checkAndDisplayToastMessage()
        setupGestures()
        VoiceAppLogger.zipOlderLogs()
        refreshControl.addTarget(self, action: #selector(self.refresh(_:)), for: .valueChanged)
        contactTableView.addSubview(refreshControl)
    }
    
    @objc func refresh(_ sender: AnyObject) {
        contactTabBtnAction()
        contactTableView.reloadData()
        refreshControl.endRefreshing()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        statusBarColorChange()
        updateStatus()
        checkAndDisplayToastMessage()
        loadDefaultHomeView()
        dialToTextView.text = ""
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.onIncomingCall), name: Notification.Name(rawValue: incomingCallKey), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onCallInitiated), name: Notification.Name(rawValue: initiateCallKey), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onAuthenticationFailure), name: Notification.Name(rawValue: authFailedKey), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onUploadLogSuccess), name: Notification.Name(rawValue: uploadLogSuccess), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onUploadLogFailure), name: Notification.Name(rawValue: uploadLogFailure), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateStatus(notification:)), name: Notification.Name(rawValue: statusUpdate), object: nil)
        
        let longGesture = UILongPressGestureRecognizer(target: self, action: #selector(longPressGesture))
        longGesture.minimumPressDuration = 1
        menuBtn.addGestureRecognizer(longGesture)
        ApplicationUtils.setIsReadyToReceiveCalls(flag: true)
    }
    
    @objc func longPressGesture() {
        showToast(message: "More Options", font: UIFont.systemFont(ofSize: 14))
    }
    
    override func viewDidAppear(_ animated: Bool) {
        updateStatus()
        checkAndDisplayToastMessage()
        loadDefaultHomeView()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: incomingCallKey), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: initiateCallKey), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: authFailedKey), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: uploadLogSuccess), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: uploadLogFailure), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: statusUpdate), object: nil)
        
        for recognizer in menuBtn.gestureRecognizers ?? [] {
            menuBtn.removeGestureRecognizer(recognizer)
        }
    }
    
    func loadDefaultHomeView() {
        dialBottomLine.isHidden = false
        dialTabLable.textColor = .white
        
        contactBottomLine.isHidden = true
        contactHideView.isHidden = true
        contactsTabLable.textColor = .lightGray
        
        recentCallsBottomLine.isHidden = true
        recentCallsHideView.isHidden = true
        recentCallsTabLable.textColor = .lightGray
    }
    
    @objc func updateStatus(notification: NSNotification) {
        self.updateStatus()
    }
    
    func updateStatus() {
        let voiceAppStatus = VoiceAppService.shared.getCurrentStatus()
        DispatchQueue.main.async {
            let voiceAppStateString = UserDefaults.standard.string(forKey: UserDefaults.Keys.voiceAppState.rawValue)
            let statusMessage = voiceAppStatus.getMessage()
            var voiceAppState = VoiceAppState.STATUS_NOT_INITIALIZED
            if voiceAppStateString == "" {
                voiceAppState = voiceAppStatus.getState()
            } else {
                voiceAppState = VoiceAppState.enumFromString(voiceAppState: voiceAppStateString ?? "")
            }
            
            let deviceTokenStateString = UserDefaults.standard.string(forKey: UserDefaults.Keys.deviceTokenState.rawValue)
            let deviceTokenState =  DeviceTokenState.enumFromString(deviceTokenState: deviceTokenStateString ?? "")
            
            VoiceAppLogger.debug(TAG: self.TAG, message: "updateStatus: VoiceAppState:  \(String(describing: voiceAppStateString)) DeviceTokenState:  \(String(describing: deviceTokenStateString))")
            
            if (VoiceAppState.STATUS_READY == voiceAppState)
                && DeviceTokenState.DEVICE_TOKEN_SEND_SUCCESS == deviceTokenState {
                self.initStausLbl.text = voiceAppStateString ?? statusMessage
                self.initStausLbl.textColor = UIColor.green
            } else if (VoiceAppState.STATUS_READY != voiceAppState) {
                self.initStausLbl.text = voiceAppStateString ?? statusMessage
                self.initStausLbl.textColor = UIColor.red
            } else if (DeviceTokenState.DEVICE_TOKEN_SEND_SUCCESS != deviceTokenState) {
                self.initStausLbl.text = voiceAppStateString ?? statusMessage
                self.initStausLbl.textColor = UIColor.red
            }
        }
    }
    
    func checkAndDisplayToastMessage() {
        let toastMessage = UserDefaults.standard.string(forKey: UserDefaults.Keys.toastMessage.rawValue) ?? ""
        if !toastMessage.isEmpty {
            self.showToast(message: toastMessage, font: .systemFont(ofSize: 15.0))
        } else {
            VoiceAppLogger.debug(TAG: TAG, message: "No toast message to display")
        }
        UserDefaults.standard.set("", forKey: UserDefaults.Keys.toastMessage.rawValue)
        UserDefaults.standard.synchronize()
    }
    
    @objc func onIncomingCall(notification: NSNotification) {
        let call: Call = (notification.object as? Call)!
        
        ApplicationUtils.getCallContext(remoteId: call.getCallDetails().getRemoteId())
        
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
//        CallKitUtils.displayIncomingCall(handle: call.getCallDetails().getRemoteId())
        let incomingVC = storyBoard.instantiateViewController(withIdentifier: "IncomingCallViewController") as! IncomingCallViewController
        destinationNumber = call.getCallDetails().getRemoteId()
        UserDefaults.standard.set(destinationNumber, forKey: UserDefaults.Keys.lastDialedNumber.rawValue)
        incomingVC.caller_id = destinationNumber
        incomingVC.context = call.getContextMessage()
        self.navigationController?.pushViewController(incomingVC, animated: true)
    }
    
    @objc func onAuthenticationFailure(notification: NSNotification) {
        let error: ExotelVoiceError = (notification.object as? ExotelVoiceError)!
        let errorMessage = error.getErrorMessage()
        VoiceAppLogger.debug(TAG: TAG, message: ErrorType.enumToString(errorType: error.getErrorType()) + " : " + errorMessage)
        DispatchQueue.main.async {
            self.showToast(message: errorMessage, font: .systemFont(ofSize: 15.0))
        }
    }
    
    @objc func onUploadLogSuccess(notification: NSNotification) {
        VoiceAppLogger.debug(TAG: TAG, message: "Uploaded logs successfully")
        DispatchQueue.main.async {
            self.showToast(message: "Successfully reported", font: .systemFont(ofSize: 15.0))
        }
    }
    
    @objc func onUploadLogFailure(notification: NSNotification) {
        let error: ExotelVoiceError = (notification.object as? ExotelVoiceError)!
        let errorMessage = error.getErrorMessage()
        VoiceAppLogger.debug(TAG: TAG, message: ErrorType.enumToString(errorType: error.getErrorType()) + " : " + errorMessage)
        DispatchQueue.main.async {
            self.showToast(message: errorMessage, font: .systemFont(ofSize: 15.0))
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        descriptionTextView.adjustUITextViewHeight()
        descriptionTextViewHeight.constant = descriptionTextView.frame.size.height
    }
    
    @IBAction func dialTabBtnAction(_ sender: UIButton) {
        VoiceAppLogger.debug(TAG: TAG, message: "Dial tab selected")
        loadDefaultHomeView()
    }
    
    @IBAction func contactTabBtnAction(_ sender: UIButton) {
        VoiceAppLogger.debug(TAG: TAG, message: "Contacts tab selected")
        contactTabBtnAction()
    }
    
    func contactTabBtnAction() {
        dialBottomLine.isHidden = true
        dialTabLable.textColor = .lightGray
        
        contactBottomLine.isHidden = false
        contactHideView.isHidden = false
        contactsTabLable.textColor = .white
        getContactList()
        
        recentCallsBottomLine.isHidden = true
        recentCallsHideView.isHidden = true
        recentCallsTabLable.textColor = .lightGray
    }
    
    @IBAction func recentCallsTabBtnAction(_ sender: UIButton) {
        VoiceAppLogger.debug(TAG: TAG, message: "Recent Calls tab selected")
        recentCallsTabBtnAction()
    }
    
    func recentCallsTabBtnAction() {
        dialBottomLine.isHidden = true
        dialTabLable.textColor = .lightGray
        
        contactBottomLine.isHidden = true
        contactHideView.isHidden = true
        contactsTabLable.textColor = .lightGray
        
        recentCallsBottomLine.isHidden = false
        recentCallsHideView.isHidden = false
        recentCallsTabLable.textColor = .white
        
        recentCallsData.removeAll()
        recentCallsData = databaseHelper.getAllData()
        recentCallsTableView.reloadData()
    }
    
    @IBAction func callBtnAction(_ sender: UIButton) {
        self.view.endEditing(true)
        
        if(!validateInputNumber()) {
            return
        }
        
        do {
            VoiceAppLogger.debug(TAG: TAG, message: "Dial input entered by user: \(String(describing: dialToTextView.text))")
            destinationNumber = dialToTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
            let number = ApplicationUtils.getUpdatedNumberToDial(destination: destinationNumber)
            try ApplicationUtils.makeIPCall(number: number, destination: destinationNumber)
        } catch let voiceError as VoiceAppError {
            ApplicationUtils.alert(message: voiceError.localizedDescription, view: self)
        } catch let error {
            ApplicationUtils.alertDismiss(message: "Failed to Dial: \(error.localizedDescription)", view: self)
        }

    }
    
    
    @IBAction func whatsppCallBtnAction(_ sender: UIButton) {
        VoiceAppLogger.debug(TAG: TAG, message: "whatsapp button pressed")
        self.view.endEditing(true)
        
        if(!validateInputNumber()) {
            return
        }
        
        do {
            VoiceAppLogger.debug(TAG: TAG, message: "Dial whatsapp number entered by user: \(String(describing: dialToTextView.text))")
            destinationNumber = dialToTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
            try ApplicationUtils.makeWhatsappCall(destination: destinationNumber)
        } catch let voiceError as VoiceAppError {
            ApplicationUtils.alert(message: voiceError.localizedDescription, view: self)
        } catch let error {
            ApplicationUtils.alertDismiss(message: "Failed to Dial: \(error.localizedDescription)", view: self)
        }
    }
    
    private func validateInputNumber() -> Bool{
        if dialToTextView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true {
            VoiceAppLogger.error(TAG: TAG, message: "Dial: No number entered.")
            ApplicationUtils.alertDismiss(message: "No number entered.", view: self)
            return false
        }
        
        if !ApplicationUtils.validateDialText(dialText: dialToTextView.text) {
            VoiceAppLogger.error(TAG: TAG, message: "Dial: Only alphanumeric characters OR \"+\" sign followed by numbers are allowed - \(String(describing: dialToTextView.text)).")
            ApplicationUtils.alertDismiss(message: "Only alphanumeric characters OR \"+\" sign followed by numbers are allowed.", view: self)
            return false
        }
        
        if UserDefaults.standard.string(forKey: UserDefaults.Keys.subscriberName.rawValue) == dialToTextView.text {
            VoiceAppLogger.error(TAG: TAG, message: "Dial: Cannot dial out to yourself - \(String(describing: dialToTextView.text)).")
            ApplicationUtils.alertDismiss(message: "Cannot dial out to yourself.", view: self)
            return false
        }
        
        return true;
    }
    
    @objc func onCallInitiated(notificaiton: NSNotification) {
        let call: Call = notificaiton.object as! Call
        DispatchQueue.main.async {
            let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let dialVC = storyBoard.instantiateViewController(withIdentifier: "CallViewController") as! CallViewController
            if self.destinationNumber.isEmpty {
                self.destinationNumber = UserDefaults.standard.string(forKey: UserDefaults.Keys.lastDialedNumber.rawValue) ?? ""
                if self.destinationNumber.isEmpty {
                    self.destinationNumber = call.getCallDetails().getRemoteId()
                }
            }
            UserDefaults.standard.set(self.destinationNumber, forKey: UserDefaults.Keys.lastDialedNumber.rawValue)
            dialVC.destinationStr = self.destinationNumber
            dialVC.call = call
            self.navigationController?.pushViewController(dialVC, animated: false)
        }
    }
    
    @IBAction func menuBtnTapped(_ sender: UIButton) {
        dropDown.dataSource = ["Logout", "Report Problem", "SDK Details", "Last Call Feedback", "Account Details", "Enable Multi-call", "Disable Multi-call"]
        /**
         [AP2AP-175] start
         hiding multi call feature in production env based on environmental variable
         */
#if HIDE_MULTI_CALL
            dropDown.dataSource.removeAll { ["Enable Multi-call", "Disable Multi-call"].contains($0) }
#endif
        //"Enable Debug Dialing", "Disable Debug Dialing" - removed options from UI
        dropDown.anchorView = dropFrameView
        dropDown.textFont = UIFont(name: "Roboto-Medium", size: 15)!
        dropDown.bottomOffset = CGPoint(x: 0, y: sender.frame.size.height)
        dropDown.show()
        dropDown.selectionAction = { [weak self] (index: Int, item: String) in
            guard let currentSelf = self else { return }
            switch index {
            case 0:
                VoiceAppLogger.debug(TAG: currentSelf.TAG, message: "User selected \"Logout\" option")
                let isLoggedOut = VoiceAppService.shared.deinitialize()
                if isLoggedOut {
                    DispatchQueue.main.async {
                        currentSelf.navigationController?.popToRootViewController(animated: false)
                        currentSelf.navigationController?.viewControllers.removeAll()
                    }
                } else {
                    ApplicationUtils.alert(message: "Failed to logout", view: currentSelf)
                }
                
            case 1:
                VoiceAppLogger.debug(TAG: currentSelf.TAG, message: "User selected \"Report Problem\" option")
                currentSelf.blurView.isHidden = false
                currentSelf.reportPrblmView.isHidden = false
                currentSelf.descriptionTextView.text = ""
                
            case 2:
                VoiceAppLogger.debug(TAG: currentSelf.TAG, message: "User selected \"SDK Details\" option")
                ApplicationUtils.alert(message: "SDK Details:\n\(VoiceAppService.shared.getVersionDetails())", view: currentSelf)
                
            case 3:
                VoiceAppLogger.debug(TAG: currentSelf.TAG, message: "User selected \"Last Call Feedback\" option")
                currentSelf.blurView.isHidden = false
                currentSelf.callFeedbackView.isHidden = false
                currentSelf.ratingLbl.text = "5"
                currentSelf.issuesLbl.text = "NO_ISSUE"
                
            case 4:
                VoiceAppLogger.debug(TAG: currentSelf.TAG, message: "User selected \"Account Details\" option")
                currentSelf.showAccountDetails()
                
                /* removed options "Enable Debug Dialing", "Disable Debug Dialing" from UI
                 case 5:
                 VoiceAppLogger.debug(TAG: currentSelf.TAG, message: "User selected \"Enable Debug Dialing\" option")
                 UserDefaults.standard.set("true", forKey: UserDefaults.Keys.enableDebugDialing.rawValue)
                 
                 case 6:
                 VoiceAppLogger.debug(TAG: currentSelf.TAG, message: "User selected \"Disable Debug Dialing\" option")
                 UserDefaults.standard.set("false", forKey: UserDefaults.Keys.enableDebugDialing.rawValue)*/
                
            case 5:
                VoiceAppLogger.debug(TAG: currentSelf.TAG, message: "User selected \"Enable Multi-call\" option")
                UserDefaults.standard.set("true", forKey: UserDefaults.Keys.enableMultiCall.rawValue)
                
            case 6:
                VoiceAppLogger.debug(TAG: currentSelf.TAG, message: "User selected \"Disable Multi-call\" option")
                UserDefaults.standard.set("false", forKey: UserDefaults.Keys.enableMultiCall.rawValue)
                
            default:
                VoiceAppLogger.debug(TAG: currentSelf.TAG, message: "User selected option is not yet supported")
            }
        }
    }
    
    @IBAction func reportPrblmOkBtnAction(_ sender: UIButton) {
        let endDate = Date()
        let startDate = Date(timeInterval: -(Double(UPLOAD_LOG_NUM_DAYS) * DAY_IN_MS), since: endDate)
        
        var description = "Something went wrong!"
        if !descriptionTextView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            description = descriptionTextView.text
        }
        VoiceAppService.shared.uploadLogs(startDate: startDate, endDate: endDate, description: description)
        
        blurView.isHidden = true
        reportPrblmView.isHidden = true
        self.view.endEditing(true)
    }
    
    @IBAction func reportPrblmCancelBtnAction(_ sender: UIButton) {
        blurView.isHidden = true
        reportPrblmView.isHidden = true
        self.view.endEditing(true)
    }
    
    @IBAction func ratingBtnAction(_ sender: UIButton) {
        dropDown.dataSource = ["1", "2", "3", "4", "5"]
        dropDown.anchorView = sender
        dropDown.textFont = UIFont(name: "Roboto-Medium", size: 15)!
        dropDown.bottomOffset = CGPoint(x: 0, y: sender.frame.size.height)
        dropDown.show()
        dropDown.selectionAction = { [weak self] (index: Int, item: String) in
            guard let currentSelf = self else { return }
            currentSelf.ratingLbl.text = item
        }
    }
    
    @IBAction func issuesBtnAction(_ sender: UIButton) {
        dropDown.dataSource = ["NO_ISSUE", "ECHO", "NO_AUDIO", "HIGH_LATENCY", "CHOPPY_AUDIO", "BACKGROUND_NOISE"]
        dropDown.textFont = UIFont(name: "Roboto-Medium", size: 15)!
        dropDown.anchorView = sender
        dropDown.bottomOffset = CGPoint(x: 0, y: sender.frame.size.height)
        dropDown.show()
        dropDown.selectionAction = { [weak self] (index: Int, item: String) in
            guard let currentSelf = self else { return }
            currentSelf.issuesLbl.text = item
        }
    }
    
    @IBAction func callFeedbackCancelBtnAction(_ sender: UIButton) {
        blurView.isHidden = true
        callFeedbackView.isHidden = true
    }
    
    @IBAction func callFeedbackOkBtnAction(_ sender: UIButton) {
        blurView.isHidden = true
        callFeedbackView.isHidden = true
        
        let issue = CallIssue.stringToEnum(callIssue: issuesLbl.text ?? "NONE")
        let rating = Int(ratingLbl.text ?? "0") ?? 0
        VoiceAppLogger.debug(TAG: TAG, message: "Issue reported: \(issuesLbl.text ?? "NONE")")
        VoiceAppLogger.debug(TAG: TAG, message: "Rating provided: \(rating)")
        
        do {
            try VoiceAppService.shared.postFeedback(rating: rating, issue: issue)
        } catch let error {
            VoiceAppLogger.error(TAG: TAG, message: "Error while posting last call feedback: \(error.localizedDescription)")
        }
    }
    
    func showAccountDetails() {
        let userName = UserDefaults.standard.string(forKey: UserDefaults.Keys.subscriberName.rawValue) ?? ""
        let displayName = UserDefaults.standard.string(forKey: UserDefaults.Keys.displayName.rawValue) ?? ""
        let accountSID = UserDefaults.standard.string(forKey: UserDefaults.Keys.accountSID.rawValue) ?? ""
        let hostName = UserDefaults.standard.string(forKey: UserDefaults.Keys.bellatrixHostName.rawValue) ?? ""
        ApplicationUtils.alert(message: "Account Details:\n\nSubscriber Name: \(userName)\nDisplay Name: \(displayName)\nAccount SID: \(accountSID)\nBase URL: \(hostName)", view: self)
    }
    
    func getContactList() {
        contactGrouparray = nil
        
        var url = UserDefaults.standard.string(forKey: UserDefaults.Keys.bellatrixHostName.rawValue) ?? ""
        let accountSid = UserDefaults.standard.string(forKey: UserDefaults.Keys.accountSID.rawValue) ?? ""
        let userName = UserDefaults.standard.string(forKey: UserDefaults.Keys.subscriberName.rawValue) ?? ""
        
        if url.isEmpty || accountSid.isEmpty || userName.isEmpty {
            VoiceAppLogger.error(TAG: TAG, message: "getContactList: Host name, account id and user id cannot be empty")
            return
        }
        
        url = url + "/accounts/" + accountSid + "/subscribers/" + userName + "/contacts"
        VoiceAppLogger.debug(TAG: TAG, message: "getContactList: URL is: \(url)")
        
        let urlLink = NSURL(string: url)
        let request = NSMutableURLRequest(url: urlLink! as URL)
        let accessToken = ExotelVoiceClientSDK.getToken()
        request.setValue("Bearer " + accessToken, forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let session = URLSession.shared
        
        let mData = session.dataTask(with: request as URLRequest) { (data, response, error) -> Void in
            guard let data = data, error == nil else {
                if error != nil {
                    let message = "Contact List: Failed to get response \(error!.localizedDescription)"
                    VoiceAppLogger.error(TAG: self.TAG, message: "getContactList: \(message)")
                    DispatchQueue.main.async {
                        self.showToast(message: "Contact List - Fetch failed", font: .systemFont(ofSize: 15.0))
                    }
                }
                return
            }
            
            do {
                let conntactgroup = try JSONDecoder().decode(MainModule.self, from: data)
                var tablearray:[sectionData] = []
                for group in conntactgroup.response {
                    let obj_section = sectionData(sectionInfo: group, isSectionOpened: false)
                    tablearray.append(obj_section)
                }
                self.contactGrouparray = tablearray
                DispatchQueue.main.async {
                    self.contactTableView.reloadData()
                }
            } catch let error {
                let message = "Contact List: Exception in reading response: \(error.localizedDescription)"
                VoiceAppLogger.error(TAG: self.TAG, message: "getContactList: \(message)")
                DispatchQueue.main.async {
                    self.showToast(message: "Contact List - Exception", font: .systemFont(ofSize: 15.0))
                }
                return
            }
        }
        mData.resume()
    }
    
    func setupGestures() {
        let fromRecentCallsToContactsList = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        fromRecentCallsToContactsList.direction = UISwipeGestureRecognizer.Direction.right
        recentCallsHideView.addGestureRecognizer(fromRecentCallsToContactsList)
        recentCallsHideView.isUserInteractionEnabled = true
        recentCallsTableView.addGestureRecognizer(fromRecentCallsToContactsList)
        recentCallsTableView.isUserInteractionEnabled = true
        
        let fromContactsListToDial = UISwipeGestureRecognizer(target: self, action: #selector(handleRightSwipe(_:)))
        fromContactsListToDial.direction = UISwipeGestureRecognizer.Direction.right
        contactHideView.addGestureRecognizer(fromContactsListToDial)
        contactHideView.isUserInteractionEnabled = true
        contactTableView.addGestureRecognizer(fromContactsListToDial)
        contactTableView.isUserInteractionEnabled = true
        
        let fromDialToContactsList = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        fromDialToContactsList.direction = UISwipeGestureRecognizer.Direction.left
        scrollView_ToDial.addGestureRecognizer(fromDialToContactsList)
        scrollView_ToDial.isUserInteractionEnabled = true
        dialToTextView.addGestureRecognizer(fromDialToContactsList)
        dialToTextView.isUserInteractionEnabled = true
        ToDialView.addGestureRecognizer(fromDialToContactsList)
        ToDialView.isUserInteractionEnabled = true
        
        let fromContactsListToRecentCalls = UISwipeGestureRecognizer(target: self, action: #selector(handleLeftSwipe(_:)))
        fromContactsListToRecentCalls.direction = UISwipeGestureRecognizer.Direction.left
        contactHideView.addGestureRecognizer(fromContactsListToRecentCalls)
        contactHideView.isUserInteractionEnabled = true
        contactTableView.addGestureRecognizer(fromContactsListToRecentCalls)
        contactTableView.isUserInteractionEnabled = true
    }
    
    @objc func handleSwipe(_ recognizer: UISwipeGestureRecognizer) {
        VoiceAppLogger.debug(TAG: TAG, message: "Contacts tab selected using Swipe Gesture")
        contactTabBtnAction()
    }
    
    @objc func handleRightSwipe(_ recognizer: UISwipeGestureRecognizer) {
        VoiceAppLogger.debug(TAG: TAG, message: "Dial tab selected using Swipe Gesture")
        loadDefaultHomeView()
    }
    
    @objc func handleLeftSwipe(_ recognizer: UISwipeGestureRecognizer) {
        VoiceAppLogger.debug(TAG: TAG, message: "Recent Calls tab selected using Swipe Gesture")
        recentCallsTabBtnAction()
    }
}

extension HomeViewController : UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch tableView {
        case recentCallsTableView:
            return recentCallsData.count
        case contactTableView:
            var tablearray:[sectionData]?
            if(isSearchingContact) {
                tablearray = self.searchContactGrouparray
            } else {
                tablearray = self.contactGrouparray
            }
            guard let contactDetails = tablearray else { return 0 }
            if contactDetails[section].isSectionOpened {
                return contactDetails[section].sectionInfo.data.contacts.count
            } else {return 0}
        default:
            VoiceAppLogger.error(TAG: TAG, message: "Trying to get number of rows for unkown table view!")
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch tableView {
        case recentCallsTableView:
            let cell = tableView.dequeueReusableCell(withIdentifier: "RecentCallsCell", for: indexPath) as! RecentCallsCell
            let indexRow = indexPath.row
            cell.phoneNoLbl.text = recentCallsData[indexRow].getRemoteId()
            cell.callTypeLbl.text = CallType.stringFromEnum(callType: recentCallsData[indexRow].getCallType())
            cell.dateTimeLbl.text = recentCallsData[indexRow].getTime()
            cell.callBtn.tag = indexRow
            cell.callBtn.addTarget(self, action: #selector(onRecentCallBtnTapped(sender:)), for: .touchUpInside)
            cell.whatsappBtn.tag = indexRow
            cell.whatsappBtn.addTarget(self, action: #selector(onRecentWhatsappBtnTapped(sender:)), for: .touchUpInside)
            cell.whatsappBtn.isHidden = true; // hide whatsapp button
            return cell
        case contactTableView:
            var tablearray:[sectionData]?
            if(isSearchingContact) {
                tablearray = self.searchContactGrouparray
            } else {
                tablearray = self.contactGrouparray
            }
            guard let contactDetails = tablearray, contactDetails[indexPath.section].isSectionOpened else { return UITableViewCell() }
            let cell = tableView.dequeueReusableCell(withIdentifier: "ContactCell", for: indexPath) as! ContactCell
            let indexRow = indexPath.row
            let group = contactDetails[indexPath.section].sectionInfo.data.group;
            cell.contactName.text = contactDetails[indexPath.section].sectionInfo.data.contacts[indexPath.row].contactName
            cell.contactNo.text = contactDetails[indexPath.section].sectionInfo.data.contacts[indexPath.row].contactNumber
            cell.callBtn.tag = indexRow
            cell.callBtn.addTarget(self, action: #selector(onContactCallBtnTapped(sender:)), for: .touchUpInside)
            cell.whatsappBtn.tag = indexRow
            cell.whatsappBtn.addTarget(self, action: #selector(onContactWhatsappBtnTapped(sender:)), for: .touchUpInside)
            if(group.contains("Exotel")) {
                cell.whatsappBtn.isHidden = false; // show whatsapp button for exotel group only
            } else {
                cell.whatsappBtn.isHidden = true;
            }
            return cell
        default:
            VoiceAppLogger.error(TAG: TAG, message: "Trying to load unkown table view!")
            return UITableViewCell()
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        switch tableView {
        case recentCallsTableView:
            return 1
        case contactTableView:
            var tablearray:[sectionData]?
            if(isSearchingContact) {
                tablearray = self.searchContactGrouparray
            } else {
                tablearray = self.contactGrouparray
            }
            guard let contactDetails = tablearray else { return 0 }
            return contactDetails.count
        default:
            VoiceAppLogger.error(TAG: TAG, message: "Trying to get number of rows for unkown table view!")
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        VoiceAppLogger.debug(TAG: TAG, message: "tableview viewForHeaderInSection isSearchingContact \(isSearchingContact)")
        if tableView == contactTableView {
            var tablearray:[sectionData]?
            if(isSearchingContact) {
                tablearray = self.searchContactGrouparray
            } else {
                tablearray = self.contactGrouparray
            }
            guard let contactDetails = tablearray else { return nil }
            let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 60))
            view.tag = section
            view.backgroundColor = #colorLiteral(red: 0.9999960065, green: 1, blue: 1, alpha: 1)
            let lbl = UILabel(frame: CGRect(x: 5, y: -5, width: view.frame.width - 15, height: 60))
            lbl.font = UIFont.boldSystemFont(ofSize: 18)
            lbl.text = contactDetails[section].sectionInfo.data.group
            view.addSubview(lbl)
            
            if contactDetails[section].isSectionOpened {
                let imageName = "collapse_up.png"
                let image = UIImage(named: imageName)
                let imageView = UIImageView(image: image!)
                imageView.frame = CGRect(x: tableView.frame.width-45, y: 10, width: 30, height: 30)
                self.view.bringSubviewToFront(imageView)
                view.addSubview(imageView)
            } else {
                let imageName = "expand_down.png"
                let image = UIImage(named: imageName)
                let imageView = UIImageView(image: image!)
                imageView.frame = CGRect(x: tableView.frame.width-45, y: 10, width: 30, height: 30)
                view.bringSubviewToFront(imageView)
                view.addSubview(imageView)
            }
            
            let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(headerTap(senderview:)))
            view.addGestureRecognizer(tapRecognizer)
            
            let separatorView = UIView(frame: CGRect(x: tableView.separatorInset.left, y: 0, width: 10, height: 1))
            separatorView.backgroundColor = UIColor.darkGray
            separatorView.translatesAutoresizingMaskIntoConstraints  = false
            view.addSubview(separatorView) //### <- add to subview before adding constraints
            NSLayoutConstraint.activate([
                separatorView.leadingAnchor.constraint(equalTo:view.leadingAnchor),
                separatorView.trailingAnchor.constraint(equalTo:view.trailingAnchor),
                separatorView.heightAnchor.constraint(equalToConstant:1),
                separatorView.bottomAnchor.constraint(equalTo:view.bottomAnchor)
            ])
            view.addSubview(separatorView)
            view.bringSubviewToFront(separatorView)
            return view
        }
        return nil
    }
    
    @objc func headerTap(senderview:UIGestureRecognizer) {
        VoiceAppLogger.debug(TAG: TAG, message: "headerTap isSearchingContact \(isSearchingContact)")
        var tablearray:[sectionData]?
        if(isSearchingContact) {
            tablearray = self.searchContactGrouparray
        } else {
            tablearray = self.contactGrouparray
        }
        guard var contact = tablearray,let sentview = senderview.view else {return}
        
        if(isSearchingContact) {
            self.searchContactGrouparray = self.removing(item: contact[sentview.tag], fromArray: &contact)
        } else {
            self.contactGrouparray = self.removing(item: contact[sentview.tag], fromArray: &contact)
        }
        
        DispatchQueue.main.async {
            self.contactTableView.reloadData()
        }
    }
    
    func removing (item: sectionData, fromArray: inout [sectionData])  -> [sectionData] {
        var newArray = fromArray
        for i in 0...newArray.count-1 {
            if newArray[i].sectionInfo.data.group == item.sectionInfo.data.group {
                let index = i
                newArray.remove(at: index)
                let status = item.isSectionOpened
                newArray.insert(sectionData(sectionInfo: item.sectionInfo, isSectionOpened: !status), at: i)
            }
        }
        return newArray
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if tableView == contactTableView {
            return 50
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    @objc func onRecentCallBtnTapped(sender: UIButton){
        VoiceAppLogger.debug(TAG: TAG, message: "Dialing from recent calls list")
        do {
            destinationNumber = recentCallsData[sender.tag].getRemoteId()
            VoiceAppLogger.debug(TAG: TAG, message: "User selected number to dial: \(destinationNumber)")
            let number = ApplicationUtils.getUpdatedNumberToDial(destination: destinationNumber)
            
            if number.isEmpty {
                VoiceAppLogger.error(TAG: TAG, message: "Cannot find the number to dial out")
                ApplicationUtils.alertDismiss(message: "Failed to Dial: Cannot find the number to dial out", view: self)
                return
            }
            
            try ApplicationUtils.makeIPCall(number: number, destination: destinationNumber)
            
        } catch let voiceError as VoiceAppError {
            ApplicationUtils.alertDismiss(message: "Failed to Dial: \(voiceError.localizedDescription)", view: self)
        } catch let error {
            ApplicationUtils.alertDismiss(message: "Failed to Dial:  System exception: \(error.localizedDescription)", view: self)
        }
    }
    
    @objc func onRecentWhatsappBtnTapped(sender: UIButton) {
        VoiceAppLogger.debug(TAG: TAG, message: "Dialing whatsapp number from recent calls list")
        
        do {
            destinationNumber = recentCallsData[sender.tag].getRemoteId()
            VoiceAppLogger.debug(TAG: TAG, message: "User selected number to dial: \(destinationNumber)")
            
            try ApplicationUtils.makeWhatsappCall(destination: destinationNumber)
            
        } catch let voiceError as VoiceAppError {
            ApplicationUtils.alertDismiss(message: "Failed to Dial: \(voiceError.localizedDescription)", view: self)
        } catch let error {
            ApplicationUtils.alertDismiss(message: "Failed to Dial:  System exception: \(error.localizedDescription)", view: self)
        }
    }
    
    @objc func onContactCallBtnTapped(sender: UIButton) {
        VoiceAppLogger.debug(TAG: TAG, message: "Dialing from contact list")
        do {
            var tablearray:[sectionData]?
            if(isSearchingContact) {
                tablearray = self.searchContactGrouparray
            } else {
                tablearray = self.contactGrouparray
            }
            if let indexPath = indexPath(of: sender) {
                VoiceAppLogger.debug(TAG: TAG, message: "The selected section is = \(indexPath.section) and value is= \(indexPath.row)")
                if let contactDetails = tablearray {
                    destinationNumber =  contactDetails[indexPath.section].sectionInfo.data.contacts[indexPath.row].contactNumber
                    is_special = contactDetails[indexPath.section].sectionInfo.data.is_special
                }
            }
            VoiceAppLogger.debug(TAG: TAG, message: "User selected number to dial: \(destinationNumber)")
            
            let number = ApplicationUtils.getUpdatedNumberToDialContact(destination: destinationNumber, isSpecialNumber: is_special)
            if number.isEmpty {
                VoiceAppLogger.error(TAG: TAG, message: "Cannot find the number to dial out")
                ApplicationUtils.alertDismiss(message: "Failed to Dial: Cannot find the number to dial out", view: self)
                return
            }
            try ApplicationUtils.makeIPCall(number: number, destination: destinationNumber)
        } catch let voiceError as VoiceAppError {
            ApplicationUtils.alertDismiss(message: "Failed to Dial: \(voiceError.localizedDescription)", view: self)
        } catch let error {
            ApplicationUtils.alertDismiss(message: "Failed to Dial:  System exception: \(error.localizedDescription)", view: self)
        }
    }
    
    @objc func onContactWhatsappBtnTapped(sender: UIButton) {
        VoiceAppLogger.debug(TAG: TAG, message: "Dialing whatsapp number from contact list")
        do {
            var tablearray:[sectionData]?
            if(isSearchingContact) {
                tablearray = self.searchContactGrouparray
            } else {
                tablearray = self.contactGrouparray
            }
            if let indexPath = indexPath(of: sender) {
                VoiceAppLogger.debug(TAG: TAG, message: "The selected section is = \(indexPath.section) and value is= \(indexPath.row)")
                if let contactDetails = tablearray {
                    destinationNumber =  contactDetails[indexPath.section].sectionInfo.data.contacts[indexPath.row].contactNumber
                    is_special = contactDetails[indexPath.section].sectionInfo.data.is_special
                }
            }
            VoiceAppLogger.debug(TAG: TAG, message: "User selected number to dial: \(destinationNumber)")
            
            try ApplicationUtils.makeWhatsappCall(destination: destinationNumber)
        } catch let voiceError as VoiceAppError {
            ApplicationUtils.alertDismiss(message: "Failed to Dial: \(voiceError.localizedDescription)", view: self)
        } catch let error {
            ApplicationUtils.alertDismiss(message: "Failed to Dial:  System exception: \(error.localizedDescription)", view: self)
        }
    }
    
    private func indexPath(of element:Any) -> IndexPath? {
        if let view = element as?  UIView {
            let pos = view.convert(CGPoint.zero, to: self.contactTableView)
            return contactTableView.indexPathForRow(at: pos)
        }
        return nil
    }
}

extension HomeViewController : UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        if(searchText.trimmingCharacters(in: .whitespacesAndNewlines).count == 0) {
            searchEnded(searchBar)
            return
        }
        
        searchContactGrouparray?.removeAll()
        if(searchBar == contactSearchBar) {
            
            contactGrouparray?.forEach { tmpSectionData in
                let filteredContacts = tmpSectionData.sectionInfo.data.contacts.filter { contact in
                    return (
                        contact.contactName.prefix(searchText.count).lowercased() == searchText.lowercased() ||
                        contact.contactNumber.prefix(searchText.count).lowercased() == searchText.lowercased()
                    )
                }
                
                if(filteredContacts.count > 0) {
                    let filterData:DataClass = DataClass(group: tmpSectionData.sectionInfo.data.group, is_special:tmpSectionData.sectionInfo.data.is_special, contacts:filteredContacts)
                    let filterSecionInfo:ContactGroupDetails = ContactGroupDetails(code: tmpSectionData.sectionInfo.code, errorData: tmpSectionData.sectionInfo.errorData, status: tmpSectionData.sectionInfo.status, data: filterData)
                    let filterSectionData:sectionData = sectionData(sectionInfo: filterSecionInfo, isSectionOpened: true)
                    searchContactGrouparray?.append(filterSectionData)
                }
            }
            
            isSearchingContact = true
            contactTableView.reloadData()
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchEnded(searchBar)
    }
    
    func searchEnded(_ searchBar: UISearchBar) {
        if(searchBar == contactSearchBar) {
            searchContactGrouparray?.removeAll()
            isSearchingContact = false
            searchBar.text = ""
            contactTableView.reloadData()
        }
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.view.endEditing(true);
    }
}

extension UIViewController {
    func showToast(message : String, font: UIFont) {
        let toastLabel = UILabel(frame: CGRect(x: self.view.frame.size.width/2 - 120, y: self.view.frame.size.height - 100, width: 230, height: 40))
        toastLabel.backgroundColor = UIColor.white.withAlphaComponent(1.0)
        toastLabel.textColor = UIColor.black
        toastLabel.font = font
        toastLabel.adjustsFontSizeToFitWidth = true
        toastLabel.textAlignment = .center
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10
        toastLabel.layer.borderWidth = 0.5
        toastLabel.layer.borderColor = UIColor.lightGray.cgColor
        toastLabel.clipsToBounds = true
        self.view.addSubview(toastLabel)
        UIView.animate(withDuration: 3.0, delay: 0.1, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.8
        }, completion: {(isCompleted) in
            toastLabel.removeFromSuperview()
        })
    }
}
