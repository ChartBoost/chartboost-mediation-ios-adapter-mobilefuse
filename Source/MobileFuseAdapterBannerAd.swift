// Copyright 2023-2024 Chartboost, Inc.
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

    /// The loaded partner ad banner size.
    /// Should be `nil` for full-screen ads.
    var bannerSize: PartnerBannerSize?
    
    /// Loads an ad.
    /// - parameter viewController: The view controller on which the ad will be presented on. Needed on load for some banners.
    /// - parameter completion: Closure to be performed once the ad has been loaded.
    func load(with viewController: UIViewController?, completion: @escaping (Result<PartnerDetails, Error>) -> Void) {
        log(.loadStarted)
        self.viewController = viewController

        guard let adm = request.adm, adm.isEmpty == false else {
            let error = error(.loadFailureInvalidAdMarkup)
            completion(.failure(error))
            return
        }

        // Fail if we cannot fit a fixed size banner in the requested size.
        guard let (loadedSize, partnerSize) = fixedBannerSize(for: request.bannerSize) else {
            let error = error(.loadFailureInvalidBannerSize)
            log(.loadFailed(error))
            return completion(.failure(error))
        }
        bannerSize = PartnerBannerSize(size: loadedSize, type: .fixed)

        if let bannerAd = MFBannerAd(placementId: request.partnerPlacement, with: partnerSize) {
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
    func show(with viewController: UIViewController, completion: @escaping (Result<PartnerDetails, Error>) -> Void) {
        // no-op
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

// MARK: - Helpers
extension MobileFuseAdapterBannerAd {
    private func fixedBannerSize(
        for requestedSize: BannerSize?
    ) -> (size: CGSize, partnerSize: MFBannerAdSize)? {
        guard let requestedSize else {
            return (IABStandardAdSize, .MOBILEFUSE_BANNER_SIZE_320x50)
        }
        let sizes: [(size: CGSize, partnerSize: MFBannerAdSize)] = [
            (size: IABLeaderboardAdSize, partnerSize: .MOBILEFUSE_BANNER_SIZE_728x90),
            (size: IABMediumAdSize, partnerSize: .MOBILEFUSE_BANNER_SIZE_300x250),
            (size: IABStandardAdSize, partnerSize: .MOBILEFUSE_BANNER_SIZE_320x50)
        ]
        // Find the largest size that can fit in the requested size.
        for (size, partnerSize) in sizes {
            // If height is 0, the pub has requested an ad of any height, so only the width matters.
            if requestedSize.size.width >= size.width &&
                (size.height == 0 || requestedSize.size.height >= size.height) {
                return (size, partnerSize)
            }
        }
        // The requested size cannot fit any fixed size banners.
        return nil
    }
}
