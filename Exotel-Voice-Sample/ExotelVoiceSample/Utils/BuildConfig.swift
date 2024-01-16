/*
 * Copyright (c) 2022 Exotel Techcom Pvt Ltd
 * All rights reserved
 */

import Foundation
import UIKit

class BuildConfig {
    static var DEBUG: Bool = true
    static var LIBRARY_PACKAGE_NAME: String = "com.exotel.voice"
    static var APPLICATION_ID: String = "com.exotel.voice"
    static var BUILD_TYPE: String = "debug"
    static var FLAVOR: String = ""
    static var VERSION_CODE: Int = 10
    static var VERSION_NAME: String = "1.0.0"
    static var TIMESTAMP: String = Date().description
    
    //Device details
    static var DEVICE_MODEL: String = UIDevice.current.model
    static var DEVICE_VERSION: String = UIDevice.current.systemName + " " + UIDevice.current.systemVersion
}
