/*
 * Copyright (c) 2022 Exotel Techcom Pvt Ltd
 * All rights reserved
 */

import UIKit
import ExotelVoice

class CustomKeyPadVC: UIViewController,UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout {
    let TAG = "CustomKeyPadViewController"
    
    @IBOutlet weak var keypadCollectionView: UICollectionView!
    var keypadArray = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        keypadArray = ["1","2","3","4","5","6","7","8","9","*","0","#"]
        keypadCollectionView.delegate = self
        keypadCollectionView.dataSource = self
        keypadCollectionView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onCallEnded), name: Notification.Name(rawValue: endedCallKey), object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: endedCallKey), object: nil)
    }
    
    @IBAction func hideKeypadBtnAction(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: false)
    }
    
    @objc func onCallEnded(notification: NSNotification) {
        VoiceAppLogger.debug(TAG: TAG, message: "Call Ended")
        let call = notification.object as? Call ?? nil
        var callEndedMessage = ""
        if call != nil {
            if call?.getCallDetails().getCallDirection() == .INCOMING {
                let userId = UserDefaults.standard.string(forKey: UserDefaults.Keys.subscriberName.rawValue) ?? ""
                ApplicationUtils.removeCallContext(userId: userId)
            }
            let endReason = call?.getCallDetails().getCallEndReason()
            if endReason != nil {
                if endReason == .NONE {
                    callEndedMessage = "Call Ended"
                } else {
                    callEndedMessage = "Call Ended - " + CallEndReason.stringFromEnum(callEndReason: endReason!)
                }
            } else {
                callEndedMessage = "Call Ended"
            }
        } else {
            callEndedMessage = "Call Ended"
        }
        VoiceAppLogger.debug(TAG: TAG, message: callEndedMessage)
        DispatchQueue.main.async {
            UserDefaults.standard.set(callEndedMessage, forKey: UserDefaults.Keys.toastMessage.rawValue)
            self.navigationController?.popToViewController(of: HomeViewController.self, animated: true)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return keypadArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let item  = keypadCollectionView.dequeueReusableCell(withReuseIdentifier: "KeypadCell", for: indexPath) as! KeypadCell
        item.numbersLbl.text = keypadArray[indexPath.item]
        return item
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: keypadCollectionView.frame.width/3, height: 50)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let digit = keypadArray[indexPath.item]
        VoiceAppLogger.debug(TAG: TAG, message: "Key pressed: \(digit)")
        
        guard let dtmfDigit = digit.first else {
            VoiceAppLogger.error(TAG: TAG, message: "Failed to get key pressed value \(digit)")
            return
        }
        VoiceAppLogger.debug(TAG: TAG, message: "Keypad digit clicked: \(dtmfDigit)")
        do {
            try VoiceAppService.shared.sendDtmf(digit: dtmfDigit)
        } catch let error {
            VoiceAppLogger.error(TAG: TAG, message: "Failed to send DTMF digit \(dtmfDigit). Error: \(error.localizedDescription)")
        }
    }
}
