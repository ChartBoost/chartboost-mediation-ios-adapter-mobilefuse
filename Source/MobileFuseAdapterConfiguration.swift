// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
import MobileFuseSDK

@objc public class MobileFuseAdapterConfiguration: NSObject {

    /// Flag that can optionally be set to enable the partner's test mode.
    /// Disabled by default.
    @objc public static var testMode: Bool = false {
        didSet {
            // TODO: Set the test mode on the partner SDK.
        }
    }
}
