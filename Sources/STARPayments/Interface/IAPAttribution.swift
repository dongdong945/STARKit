import Foundation

public enum IAPAttribution {
    case adjustID
    case appsFlyerID
    case fBAnonID
    case mpParticleID
    case oneSignalID
    case oneSignalUserID
    case airshipChannelID
    case cleverTapID
    case mixpanelDistinctID
    case firebaseAppInstanceID

    case custom(key: String)
}
