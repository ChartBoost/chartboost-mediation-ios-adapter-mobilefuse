// Copyright 2023-2026 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import ChartboostMediationSDK
import Foundation
import MobileFuseSDK

@objc public class MobileFuseAdapterConfiguration: NSObject, PartnerAdapterConfiguration {
    /// The version of the partner SDK.
    @objc public static var partnerSDKVersion: String {
        MobileFuse.version() ?? ""
    }

    /// The version of the adapter.
    /// It should have either 5 or 6 digits separated by periods, where the first digit is Chartboost Mediation SDK's major version, the
    /// last digit is the adapter's build version, and intermediate digits are the partner SDK's version.
    /// Format: `<Chartboost Mediation major version>.<Partner major version>.<Partner minor version>.<Partner patch version>.
    /// <Partner build version>.<Adapter build version>` where `.<Partner build version>` is optional.
    @objc public static let adapterVersion = "5.1.10.0.0"

    /// The partner's unique identifier.
    @objc public static let partnerID = "mobilefuse"

    /// The human-friendly partner name.
    @objc public static let partnerDisplayName = "MobileFuse"

    /// Flag that can optionally be set to enable the partner's test mode.
    /// Disabled by default.
    @objc public static var testMode = false
    // The global test mode mentioned in MobileFuse's documentation (https://docs.mobilefuse.com/docs/testing-sdk-integrations#enabling-global-test-mode))
    // is in MobileFuseSettings.h, a private header that was not imported in MobileFuseSDK.h so it
    // is not available here. However, they have another way to work with test ads - setting
    // testMode on each individual ad instance. All the ad classes apply MobileFuseAdapterConfiguration.testMode
    // where applicable, so that's why this config object doesn't directly interact with MobileFuseSDK
}
