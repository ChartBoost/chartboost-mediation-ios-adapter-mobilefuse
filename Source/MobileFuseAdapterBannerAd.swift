// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import ChartboostMediationSDK
import Foundation
import MobileFuseSDK

final class MobileFuseAdapterBannerAd: MobileFuseAdapterAd, PartnerAd {

    // For storing a correctly typed reference to the ad instead of casting from MFAd in onAdLoaded()
    private var mfBannerAd: MFBannerAd?
    // For storing a ViewController if one is passed in load()
    private weak var viewController: UIViewController?

    /// The partner ad view to display inline. E.g. a banner view.
    /// Should be nil for full-screen ads.
    var inlineView: UIView? {
        mfBannerAd
    }

    /// Loads an ad.
    /// - parameter viewController: The view controller on which the ad will be presented on. Needed on load for some banners.
    /// - parameter completion: Closure to be performed once the ad has been loaded.
    func load(with viewController: UIViewController?, completion: @escaping (Result<PartnerEventDetails, Error>) -> Void) {
        log(.loadStarted)
        self.viewController = viewController

        guard let adm = request.adm, adm.isEmpty == false else {
            let error = error(.loadFailureInvalidAdMarkup)
            completion(.failure(error))
            return
        }

        let adSize = getMobileFuseBannerAdSize(size: request.size)
        if let bannerAd = MFBannerAd(placementId: request.partnerPlacement, with: adSize) {
            mfBannerAd = bannerAd
            loadCompletion = completion
            // Set test mode to either true or false
            bannerAd.testMode = MobileFuseAdapterConfiguration.testMode
            // Set self as the callback receiver
            bannerAd.register(self)
            bannerAd.load(withBiddingResponseToken: adm)
        } else {
            let error = error(.loadFailureUnknown, description: "Failed to create MFBannerAd instance")
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

    func invalidate() throws {
        log(.invalidateStarted)
        DispatchQueue.main.async {
            if let ad = self.mfBannerAd {
                ad.destroy()
                self.log(.invalidateSucceeded)
            } else {
                self.log(.invalidateFailed(self.error(.invalidateFailureAdNotFound)))
            }
        }
    }
}

extension MobileFuseAdapterBannerAd: IMFAdCallbackReceiver {
    func onAdLoaded(_ ad: MFAd!) {
        log(.loadSucceeded)
        loadCompletion?(.success([:])) ?? log(.loadResultIgnored)
        loadCompletion = nil

        log(.showStarted)
        if let vc = viewController {
            self.mfBannerAd?.show(with: vc)
        } else {
            self.mfBannerAd?.show()
        }
    }

    func onAdNotFilled(_ ad: MFAd!) {
        let error = error(.loadFailureNoFill)
        log(.loadFailed(error))
        loadCompletion?(.failure(error)) ?? log(.loadResultIgnored)
        loadCompletion = nil
    }

    func onAdClosed(_ ad: MFAd!) {
        log(.didDismiss(error: nil))
        delegate?.didDismiss(self, details: [:], error: nil) ?? log(.delegateUnavailable)
    }

    func onAdRendered(_ ad: MFAd!) {
        log(.showSucceeded)
    }

    func onAdClicked(_ ad: MFAd!) {
        log(.didClick(error: nil))
        delegate?.didClick(self, details: [:]) ?? log(.delegateUnavailable)
    }

    func onAdExpired(_ ad: MFAd!) {
        log(.didExpire)
        delegate?.didExpire(self, details: [:]) ?? log(.delegateUnavailable)
    }

    func onAdError(_ ad: MFAd!, withError error: MFAdError!) {
        let errorMessage = error.localizedDescription
        log(.custom(errorMessage))
    }
}
