/**
 * Copyright 2016 IBM Corp. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Foundation
import UIKit
import BMSCore
import BMSSecurity

//Auth delegate for handling custom challenge
struct CustomAuthDelegate : AuthenticationDelegate {
    func onAuthenticationChallengeReceived(authContext: AuthenticationContext, challenge: AnyObject) {
        print("onAuthenticationChallengeReceived")
        // submit authentication by username and passsword entered in login panel
        authContext.submitAuthenticationChallengeAnswer([
            "username":"tom",
            "password":"tom"
        ])
    }

    func onAuthenticationSuccess(info: AnyObject?) {
        print("onAuthenticationSuccess info = \(info)")
        print("onAuthenticationSuccess ----")
    }

    func onAuthenticationFailure(info: AnyObject?) {
        print("onAuthenticationFailure info = \(info)")
        print("onAuthenticationFailure ----")
    }
}