// Copyright 2023-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

@objc public class MobileFuseAdapterConfiguration: NSObject {

    /// Flag that can optionally be set to enable the partner's test mode.
    /// Disabled by default.
    @objc public static var testMode: Bool = false
    // The global test mode mentioned in MobileFuse's documentation (https://docs.mobilefuse.com/docs/testing-sdk-integrations#enabling-global-test-mode))
    // is in MobileFuseSettings.h, a private header that was not imported in MobileFuseSDK.h so it
    // is not available here. However, they have another way to work with test ads - setting
    // testMode on each individual ad instance. All the ad classes apply MobileFuseAdapterConfiguration.testMode
    // where applicable, so that's why this config object doesn't directly interact with MobileFuseSDK
}
