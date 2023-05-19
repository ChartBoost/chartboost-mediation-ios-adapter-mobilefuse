// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import ChartboostMediationSDK
import Foundation
import MobileFuseSDK

final class MobileFuseAdapterBannerAd: MobileFuseAdapterAd, PartnerAd {

    /// The partner ad view to display inline. E.g. a banner view.
    /// Should be nil for full-screen ads.
    var inlineView: UIView?

    /// Loads an ad.
    /// - parameter viewController: The view controller on which the ad will be presented on. Needed on load for some banners.
    /// - parameter completion: Closure to be performed once the ad has been loaded.
    func load(with viewController: UIViewController?, completion: @escaping (Result<PartnerEventDetails, Error>) -> Void) {
        log(.loadStarted)
        let adSize = getMobileFuseBannerAdSize(size: request.size)
        if let ad = MFBannerAd.init(placementId: request.partnerPlacement, with: adSize) {
            loadCompletion = completion
            ad.register(self)
            inlineView = ad
            ad.load(withBiddingResponseToken: request.adm)
        } else {
            let error = error(.loadFailureUnknown)
            log(.loadFailed(error))
            completion(.failure(error))
        }
    }

    /// Shows a loaded ad.
    /// It will never get called for banner ads. You may leave the implementation blank for that ad format.
    /// - parameter viewController: The view controller on which the ad will be presented on.
    /// - parameter completion: Closure to be performed once the ad has been shown.
    func show(with viewController: UIViewController, completion: @escaping (Result<PartnerEventDetails, Error>) -> Void) {
        // no-op
    }

    /// Map Chartboost Mediation's banner sizes to the MobileFuse SDK's supported sizes.
    /// - Parameter size: The Chartboost Mediation's banner size.
    /// - Returns: The corresponding MobileFuse banner size.
    func getMobileFuseBannerAdSize(size: CGSize?) -> MFBannerAdSize {
        let height = size?.height ?? 50

        switch height {
        case 50..<89:
            return MFBannerAdSize.MOBILEFUSE_BANNER_SIZE_320x50
        case 90..<249:
            return MFBannerAdSize.MOBILEFUSE_BANNER_SIZE_728x90
        case 250...:
            return MFBannerAdSize.MOBILEFUSE_BANNER_SIZE_300x250
        default:
            return MFBannerAdSize.MOBILEFUSE_BANNER_SIZE_320x50
        }
    }
}

extension MobileFuseAdapterBannerAd: IMFAdCallbackReceiver {
    func onAdLoaded() {
        log(.loadSucceeded)
        loadCompletion?(.success([:])) ?? log(.loadResultIgnored)
        loadCompletion = nil
    }

    func onAdNotFilled() {
        let error = error(.loadFailureNoFill)
        log(.loadFailed(error))
        loadCompletion?(.failure(error)) ?? log(.loadResultIgnored)
        loadCompletion = nil
    }

    func onAdClosed() {
        log(.didDismiss(error: nil))
        delegate?.didDismiss(self, details: [:], error: nil) ?? log(.delegateUnavailable)
    }

    func onAdRendered() {
        log(.showSucceeded)
        showCompletion?(.success([:])) ?? log(.showResultIgnored)
        showCompletion = nil
    }

    func onAdClicked() {
        log(.didClick(error: nil))
        delegate?.didClick(self, details: [:]) ?? log(.delegateUnavailable)
    }

    func onAdExpired() {
        log(.didExpire)
        delegate?.didExpire(self, details: [:]) ?? log(.delegateUnavailable)
    }

    func onAdError(_ message: String!) {
        let errorMessage = message ?? "An unidentified error occoured"
        log(.custom(errorMessage))
    }
}