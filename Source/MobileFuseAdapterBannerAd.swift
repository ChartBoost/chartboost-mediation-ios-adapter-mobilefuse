// Copyright 2023-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import ChartboostMediationSDK
import Foundation
import MobileFuseSDK

final class MobileFuseAdapterBannerAd: MobileFuseAdapterAd, PartnerBannerAd {
    /// The partner banner ad view to display.
    var view: UIView? { mfBannerAd }

    /// The loaded partner ad banner size.
    var size: PartnerBannerSize?

    // For storing a correctly typed reference to the ad instead of casting from MFAd in onAdLoaded()
    private var mfBannerAd: MFBannerAd?
    // For storing a ViewController if one is passed in load()
    private weak var viewController: UIViewController?

    /// Loads an ad.
    /// - parameter viewController: The view controller on which the ad will be presented on. Needed on load for some banners.
    /// - parameter completion: Closure to be performed once the ad has been loaded.
    func load(with viewController: UIViewController?, completion: @escaping (Error?) -> Void) {
        log(.loadStarted)
        self.viewController = viewController

        guard let adm = request.adm, adm.isEmpty == false else {
            let error = error(.loadFailureInvalidAdMarkup)
            completion(error)
            return
        }

        // Fail if we cannot fit a fixed size banner in the requested size.
        guard
            let requestedSize = request.bannerSize,
            let fittingSize = BannerSize.largestStandardFixedSizeThatFits(in: requestedSize),
            let mobileFuseSize = fittingSize.mfAdSize
        else {
            let error = error(.loadFailureInvalidBannerSize)
            log(.loadFailed(error))
            completion(error)
            return
        }
        size = PartnerBannerSize(size: fittingSize.size, type: .fixed)

        if let bannerAd = MFBannerAd(placementId: request.partnerPlacement, with: mobileFuseSize) {
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
            completion(error)
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
        loadCompletion?(nil) ?? log(.loadResultIgnored)
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
        loadCompletion?(error) ?? log(.loadResultIgnored)
        loadCompletion = nil
    }

    func onAdClosed(_ ad: MFAd!) {
        log(.didDismiss(error: nil))
        delegate?.didDismiss(self, error: nil) ?? log(.delegateUnavailable)
    }

    func onAdRendered(_ ad: MFAd!) {
        log(.showSucceeded)
    }

    func onAdClicked(_ ad: MFAd!) {
        log(.didClick(error: nil))
        delegate?.didClick(self) ?? log(.delegateUnavailable)
    }

    func onAdExpired(_ ad: MFAd!) {
        log(.didExpire)
        delegate?.didExpire(self) ?? log(.delegateUnavailable)
    }

    func onAdError(_ ad: MFAd!, withError error: MFAdError!) {
        let errorMessage = error.localizedDescription
        log(.custom(errorMessage))
    }
}

extension BannerSize {
    fileprivate var mfAdSize: MFBannerAdSize? {
        switch self {
        case .standard:
            .MOBILEFUSE_BANNER_SIZE_320x50
        case .medium:
            .MOBILEFUSE_BANNER_SIZE_300x250
        case .leaderboard:
            .MOBILEFUSE_BANNER_SIZE_728x90
        default:
            nil
        }
    }
}
