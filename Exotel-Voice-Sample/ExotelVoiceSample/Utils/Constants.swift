/*
 * Copyright (c) 2022 Exotel Techcom Pvt Ltd
 * All rights reserved
 */

import Foundation
import Alamofire
import UIKit

func dateFormatChanger(fromDate : String) -> String{
    let dateFormatterGet = DateFormatter()
    //    dateFormatterGet.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
    dateFormatterGet.dateFormat = "yyyy-MM-dd HH:mm:ss VV"
    //    dateFormatterGet.timeZone = NSTimeZone.local
    let dateFormatterPrint = DateFormatter()
    dateFormatterPrint.dateFormat = "yyyy-MM-dd HH:mm:ss"
    dateFormatterPrint.timeZone = NSTimeZone(name: "UTC")! as TimeZone
    //    dateFormatterPrint.timeZone = TimeZone.current
    //    dateFormatterPrint.locale = Locale.current
    var output = ""
    if let date = dateFormatterGet.date(from: fromDate){
        debugPrint(dateFormatterPrint.string(from: date))
        output = dateFormatterPrint.string(from: date)
    }else{
        debugPrint("There was an error decoding the string")
    }
    return output
}

func border(textField:UITextField, color: UIColor, color1: CGColor){
    textField.backgroundColor = .clear
    let border = CALayer()
    let width = CGFloat(1.0)
    border.borderColor = color1
    border.frame = CGRect(x: 0, y: textField.frame.size.height - width, width:  textField.frame.size.width, height: textField.frame.size.height)
    border.borderWidth = width
    textField.layer.addSublayer(border)
    textField.layer.masksToBounds = true
    textField.tintColor = color
}

func statusBarColorChange(){
    if #available(iOS 13.0, *) {
        let statusBar = UIView(frame: UIApplication.shared.keyWindow?.windowScene?.statusBarManager?.statusBarFrame ?? CGRect.zero)
        statusBar.backgroundColor = #colorLiteral(red: 0.1882352941, green: 0.2470588235, blue: 0.6235294118, alpha: 1)
        statusBar.tag = 100
        UIApplication.shared.keyWindow?.addSubview(statusBar)
    } else {
        let statusBar = UIApplication.shared.value(forKeyPath: "statusBarWindow.statusBar") as? UIView
        statusBar?.backgroundColor = #colorLiteral(red: 0.1882352941, green: 0.2470588235, blue: 0.6235294118, alpha: 1)
    }
}

func statusBarColorChangeIncomingCall(){
    if #available(iOS 13.0, *) {
        let statusBar = UIView(frame: UIApplication.shared.keyWindow?.windowScene?.statusBarManager?.statusBarFrame ?? CGRect.zero)
        statusBar.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        statusBar.tag = 100
        UIApplication.shared.keyWindow?.addSubview(statusBar)
    } else {
        let statusBar = UIApplication.shared.value(forKeyPath: "statusBarWindow.statusBar") as? UIView
        statusBar?.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
    }
}

func jsonToString(json:[String:Any]) -> String {
    do {
        let dataFromJson =  try JSONSerialization.data(withJSONObject: json, options:.prettyPrinted) // first of all convert json to the data
        let convertedString = String(data: dataFromJson, encoding:.utf8) // the data will be converted to the string
        debugPrint(convertedString ?? "defaultvalue")
        return convertedString!
    } catch let myJSONError {
        debugPrint(myJSONError)
    }
    return String()
}

extension UITextView {
    func adjustUITextViewHeight() {
        self.sizeToFit()
        self.isScrollEnabled = false
    }
}


class Constants{
    static let applicationName = "Exotel Voice Sample"
}

struct APIList{
    var BASE_URL = ""
    
    func getUrlString(url: urlString) -> String{
        return BASE_URL + url.rawValue
    }
}

enum urlString: String{
    case REGISTRATION = "/login"
}

// MARK: UIApplication
extension UIApplication {
    var statusBarView: UIView? {
        if responds(to: Selector(("statusBar"))) {
            return value(forKey: "statusBar") as? UIView
        }
        return nil
    }
}

extension UIView {
    func blink(duration: TimeInterval = 0.5, delay: TimeInterval = 0.0, alpha: CGFloat = 0.0) {
        UIView.animate(withDuration: duration, delay: delay, options: [.curveEaseInOut, .repeat, .autoreverse], animations: {
            self.alpha = alpha
        })
    }
}

// MARK: - corner radius extension
extension UIView {
    func roundCorners(corners: UIRectCorner, radius: CGFloat){
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }
}

extension UIView {
    func removeAllConstraints() {
        var view: UIView? = self
        while let currentView = view {
            currentView.removeConstraints(currentView.constraints.filter {
                return $0.firstItem as? UIView == self || $0.secondItem as? UIView == self
            })
            view = view?.superview
        }
    }
    
    func animShow(){
        UIView.animate(withDuration: 0.2, delay: 0, options: [.curveLinear],
                       animations: {
            self.center.y -= self.bounds.height - 100
            self.layoutIfNeeded()
        }, completion: nil)
        self.isHidden = false
    }
    
    func animHide(){
        UIView.animate(withDuration: 0.2, delay: 0, options: [.curveLinear],
                       animations: {
            self.center.y += self.bounds.height - 100
            self.layoutIfNeeded()
            
        },  completion: {(_ completed: Bool) -> Void in
            self.isHidden = true
        })
    }
    
    @IBInspectable
    public var ignoreColorInversion: Bool {
        get {
            if #available(iOS 11, *) {
                return self.accessibilityIgnoresInvertColors
            }
            return false
        }
        set {
            if #available(iOS 11, *) {
                self.accessibilityIgnoresInvertColors = newValue
            }
        }
    }
}

// MARK: @IBDesignables for UIViews
@IBDesignable extension UIView{
    
    /* The color of the shadow. Defaults to opaque black. Colors created
     * from patterns are currently NOT supported. Animatable. */
    
    @IBInspectable
    var cornerRadius: CGFloat {
        get{
            return layer.cornerRadius
        }
        set{
            layer.cornerRadius = newValue
        }
    }
    
    @IBInspectable
    var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }
    
    @IBInspectable
    var borderColor: UIColor? {
        get {
            if let color = layer.borderColor {
                return UIColor(cgColor: color)
            }
            return nil
        }
        set {
            if let color = newValue {
                layer.borderColor = color.cgColor
            }else{
                layer.borderColor = nil
            }
        }
    }
    
    @IBInspectable var shadowColor: UIColor? {
        set {
            layer.shadowColor = newValue!.cgColor
        }
        get {
            if let color = layer.shadowColor {
                return UIColor(cgColor:color)
            }else{
                return nil
            }
        }
    }
    
    /* The opacity of the shadow. Defaults to 0. Specifying a value outside the
     * [0,1] range will give undefined results. Animatable. */
    
    // MARK: IBInspectables for shadowOpacity and shadowOffset
    @IBInspectable var shadowOpacity: Float {
        set {
            layer.shadowOpacity = newValue
        }
        get {
            return layer.shadowOpacity
        }
    }
    
    /* The shadow offset. Defaults to (0, -3). Animatable. */
    @IBInspectable var shadowOffset: CGPoint {
        set {
            layer.shadowOffset = CGSize(width: newValue.x, height: newValue.y)
        }
        get {
            return CGPoint(x: layer.shadowOffset.width, y:layer.shadowOffset.height)
        }
    }
    
    /* The blur radius used to create the shadow. Defaults to 3. Animatable. */
    @IBInspectable var shadowRadius: CGFloat {
        set {
            layer.shadowRadius = newValue
        }
        get {
            return layer.shadowRadius
        }
    }
    
    /// Flip view horizontally.
    func flipX() {
        transform = CGAffineTransform(scaleX: -transform.a, y: transform.d)
    }
    
    /// Flip view vertically.
    func flipY() {
        transform = CGAffineTransform(scaleX: transform.a, y: -transform.d)
    }
}

extension UINavigationController {
    func getViewController<T: UIViewController>(of type: T.Type) -> UIViewController? {
        return self.viewControllers.first(where: { $0 is T })
    }
    
    func popToViewController<T: UIViewController>(of type: T.Type, animated: Bool) {
        guard let viewController = self.getViewController(of: type) else { return }
        self.popToViewController(viewController, animated: animated)
    }
}
