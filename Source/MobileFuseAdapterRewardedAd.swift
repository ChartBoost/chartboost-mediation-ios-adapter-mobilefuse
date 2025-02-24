// Copyright 2023-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import ChartboostMediationSDK
import Foundation
import MobileFuseSDK

final class MobileFuseAdapterRewardedAd: MobileFuseAdapterAd, PartnerFullscreenAd {
    /// The MobileFuseSDK ad instance.
    private var ad: MFRewardedAd?

    /// Tracks whether a show operation is in progress
    private var showInProgress = false

    /// Loads an ad.
    /// - parameter viewController: The view controller on which the ad will be presented on. Needed on load for some banners.
    /// - parameter completion: Closure to be performed once the ad has been loaded.
    func load(with viewController: UIViewController?, completion: @escaping (Error?) -> Void) {
        log(.loadStarted)

        guard let adm = request.adm, adm.isEmpty == false else {
            let error = error(.loadFailureInvalidAdMarkup)
            completion(error)
            return
        }

        DispatchQueue.main.async {
            if let rewardedAd = MFRewardedAd(placementId: self.request.partnerPlacement) {
                self.ad = rewardedAd
                self.loadCompletion = completion
                // Set test mode to either true or false
                rewardedAd.testMode = MobileFuseAdapterConfiguration.testMode
                // Set self as the callback receiver
                rewardedAd.register(self)
                rewardedAd.load(withBiddingResponseToken: adm)
            } else {
                let error = self.error(.loadFailureUnknown)
                self.log(.loadFailed(error))
                completion(error)
            }
        }
    }

    /// Shows a loaded ad.
    /// Chartboost Mediation SDK will always call this method from the main thread.
    /// - parameter viewController: The view controller on which the ad will be presented on.
    /// - parameter completion: Closure to be performed once the ad has been shown.
    func show(with viewController: UIViewController, completion: @escaping (Error?) -> Void) {
        log(.showStarted)

        guard let ad, ad.isLoaded() else {
            let error = error(.showFailureAdNotReady)
            log(.showFailed(error))
            completion(error)
            return
        }

        showCompletion = completion
        showInProgress = true
        // MobileFuse actually tells you to do this, and I haven't found a workaround to make
        // the ad load without adding it as a subview first https://docs.mobilefuse.com/docs/ios-rewarded-ads
        // ad will be removed from its superview when MFAd.destroy() is called by our invalidate() method
        viewController.view.addSubview(ad)
        ad.show()
    }

    func invalidate() throws {
        log(.invalidateStarted)
        DispatchQueue.main.async {
            if let ad = self.ad {
                ad.destroy()
                self.log(.invalidateSucceeded)
            } else {
                self.log(.invalidateFailed(self.error(.invalidateFailureAdNotFound)))
            }
        }
    }
}

extension MobileFuseAdapterRewardedAd: IMFAdCallbackReceiver {
    func onAdLoaded(_ ad: MFAd!) {
        log(.loadSucceeded)
        loadCompletion?(nil) ?? log(.loadResultIgnored)
        loadCompletion = nil
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
        showInProgress = false
        log(.showSucceeded)
        showCompletion?(nil) ?? log(.showResultIgnored)
        showCompletion = nil
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
        if showInProgress {
            log(.showFailed(error))
            showCompletion?(error) ?? log(.showResultIgnored)
            showCompletion = nil
        } else {
            let errorMessage = error.localizedDescription
            log(.custom(errorMessage))
        }
    }

    func onUserEarnedReward(_ ad: MFAd!) {
        log(.didReward)
        delegate?.didReward(self) ?? log(.delegateUnavailable)
    }
}
