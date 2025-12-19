//
//  L10n.swift
//  BibleAtlas
//
//  Created by 배성연 on 9/23/25.
//

import Foundation


extension String {
    var localized: String { NSLocalizedString(self, comment: "") }
    func localized(_ args: CVarArg...) -> String { String(format: self.localized, arguments: args) }
}

enum L10n {
    
    /// 번들에 실제 포함된 언어 기준의 우선 언어 식별자 (예: "ko", "en", "en-GB")
    static var languageIdentifier: String {
        // 번들에 포함된 로컬라이즈(=Localizations)에 한정해 우선순위를 계산
        if let first = Bundle.main.preferredLocalizations.first {
            return first
        }
        // 기기 전체 선호 언어(번들 외) – 폴백
        return Locale.preferredLanguages.first ?? "en"
    }

    /// ISO 언어 코드 (예: "ko", "en")
    static var languageCode: String {
        let id = languageIdentifier
        // "en-GB" -> "en"
        return Locale(identifier: id).region?.identifier ?? id.split(separator: "-").first.map(String.init) ?? "en"
    }

    /// 지역 코드 (예: "KR", "US") – 없을 수도 있음
    static var regionCode: String? {
        Locale(identifier: languageIdentifier).region?.identifier
    }

    /// 한국어 환경인가?
    static var isKorean: Bool { languageCode == "ko" }

    /// 영어 환경인가? (en 계열 모두)
    static var isEnglish: Bool { languageCode == "en" }
    
    
    
    
    enum Home{
        static let searchPlaceholderKey = "Home.SearchPlaceholder"
        static let loginKey = "Home.Login"
        static let cancelKey = "Home.Cancel"
        
        static var searchPlaceholder: String { searchPlaceholderKey.localized }
        static var login: String { loginKey.localized }
        static var cancel: String { cancelKey.localized }
    }
    
    enum HomeContent{
        // Section titles
        static let collectionsKey = "HomeContent.Collections"
        static let recentKey = "HomeContent.Recent"
        static let myGuidesKey = "HomeContent.MyGuides"
        
        static var collections: String { collectionsKey.localized }
        static var recent: String { recentKey.localized }
        static var myGuides: String { myGuidesKey.localized }
        
        // Collection buttons
        static let favoritesKey = "HomeContent.Favorites"
        static let bookmarksKey = "HomeContent.Bookmarks"
        static let memosKey = "HomeContent.Memos"
        static var favorites: String { favoritesKey.localized }
        static var bookmarks: String { bookmarksKey.localized }
        static var memos: String { memosKey.localized }
        
        
        
        // Recent area
        static let moreKey = "HomeContent.More"
        static let recentEmptyKey = "HomeContent.RecentEmpty"
        static var more: String { moreKey.localized }
        static var recentEmpty: String { recentEmptyKey.localized }
        
        // Guides + menu
        static let explorePlacesKey = "HomeContent.ExplorePlaces"
        static var explorePlaces: String { explorePlacesKey.localized }
        
        static let menuTitleKey = "HomeContent.ExploreMenu.Title"
        static let menuAZKey = "HomeContent.ExploreMenu.AZ"
        static let menuByTypeKey = "HomeContent.ExploreMenu.ByType"
        static let menuByBibleKey = "HomeContent.ExploreMenu.ByBible"
        
        static let allPoliciesKey = "HomeContent.AllPolicies"
        
        static var menuTitle: String { menuTitleKey.localized }
        static var menuAZ: String { menuAZKey.localized }
        static var menuByType: String { menuByTypeKey.localized }
        static var menuByBible: String { menuByBibleKey.localized }
        
        static var allPolicies: String{ allPoliciesKey.localized }
        
        static var tosKey = "HomeContent.TOC"
        static var tos: String {
            tosKey.localized
        }
        
        static var csKey = "HomeContent.CS"
        static var cs: String {
            csKey.localized
        }
        
    }
    
    
    enum SearchResult {
        static let emptyKey = "SearchResult.Empty"
        static var empty: String { emptyKey.localized }
    }
    
    enum SearchReady {
        static let popularKey = "SearchReady.Popular"
        static let popularEmptyKey = "SearchReady.PopularEmpty"
        static let recentKey = "SearchReady.Recent"
        static let moreKey = "SearchReady.More"

        static var popular: String { popularKey.localized }
        static var popularEmpty: String { popularEmptyKey.localized }
        static var recent: String { recentKey.localized }
        static var more: String { moreKey.localized }
    }
    
    enum Bibles{
        static let titleKey = "Bibles.Title"
        static let emptyKey = "Bibles.Empty"
        static let fetchErrorMessageKey = "Bibles.FetchErrorMessage"

        static var title: String { titleKey.localized }
        static var empty: String { emptyKey.localized }
        static var fetchErrorMessage: String { fetchErrorMessageKey.localized }
    }
    
    enum PlacesByBible{
        static let titleKey = "PlacesByBible.Title"
        static let emptyKey = "PlacesByBible.Empty"
        
        static func title(_ bibleBookName: String) -> String {
            titleKey.localized(bibleBookName)
        }
        
        static var empty:String {emptyKey.localized}
    }
    
    enum Common {
        static let retryKey = "Common.Retry"
        static var retry: String { retryKey.localized }
        
        
        static let defaultErrorMessageKey = "Common.DefaultErrorMessage"
        static var defaultErrorMessage: String { defaultErrorMessageKey.localized }
        
        static var closeKey = "Common.Close"
        static var close: String { closeKey.localized }
        
        static let errorTitleKey = "Common.ErrorTitle"
        static var errorTitle: String { errorTitleKey.localized }
        
        static let okKey = "Common.Ok"
        static var ok: String { okKey.localized }
        
        static let cancelKey = "Common.Cancel"
        static var cancel: String { cancelKey.localized }

        static let doneKey = "Common.Done" // 완료
        static var done: String { doneKey.localized }

        static let emptyKey = "Common.Empty"
        static var empty: String {emptyKey.localized}
        
        // Count (stringsdict로 복수형 처리)
        static func placesCount(_ n: Int) -> String {
            // "Home.PlacesCount" = "%d places" | "장소 %d개" 등
            "Common.PlacesCount".localized(n)
        }
    
    }
    
    enum PlaceDetail {
            // Keys
        static let backKey = "PlaceDetail.Back"
        static let placeTypeKey = "PlaceDetail.PlaceType"
        static let ancientKey = "PlaceDetail.Ancient"
        static let modernKey = "PlaceDetail.Modern"

        static let descriptionKey = "PlaceDetail.Description"
        static let relatedPlacesKey = "PlaceDetail.RelatedPlaces"
        static let relatedPlacesEmptyKey = "PlaceDetail.RelatedPlacesEmpty"
        static let relatedVersesKey = "PlaceDetail.RelatedVerses"
        static let relatedVersesEmptyKey = "PlaceDetail.RelatedVersesEmpty"

        static let reportIssueKey = "PlaceDetail.ReportIssue"
        static let addMemoKey = "PlaceDetail.AddMemo"
        static let requestEditKey = "PlaceDetail.RequestEdit"

        static let reportMenuTitleKey = "PlaceDetail.ReportMenuTitle"
        static let reportSpamKey = "PlaceDetail.Report.Spam"
        static let reportInappropriateKey = "PlaceDetail.Report.Inappropriate"
        static let reportFalseInfoKey = "PlaceDetail.Report.FalseInfo"
        static let reportOtherKey = "PlaceDetail.Report.Other"

        static let okKey = "PlaceDetail.OK"
        static let likesFmtKey = "PlaceDetail.LikesFmt" // "%d Likes"
        
        static let dataSourceKey = "PlaceDetail.DataSource"

            // Values
        static var back: String { backKey.localized }
        static var placeType: String { placeTypeKey.localized }
        static var ancient: String { ancientKey.localized }
        static var modern: String { modernKey.localized }

        static var description: String { descriptionKey.localized }
        static var relatedPlaces: String { relatedPlacesKey.localized }
        static var relatedPlacesEmpty: String { relatedPlacesEmptyKey.localized }
        static var relatedVerses: String { relatedVersesKey.localized }
        static var relatedVersesEmpty: String { relatedVersesEmptyKey.localized }

        static var reportIssue: String { reportIssueKey.localized }
        static var addMemo: String { addMemoKey.localized }
        static var requestEdit: String { requestEditKey.localized }

        static var reportMenuTitle: String { reportMenuTitleKey.localized }
        static var reportSpam: String { reportSpamKey.localized }
        static var reportInappropriate: String { reportInappropriateKey.localized }
        static var reportFalseInfo: String { reportFalseInfoKey.localized }
        static var reportOther: String { reportOtherKey.localized }
        
        static var dataSource: String { dataSourceKey.localized }

        static var ok: String { okKey.localized }

        static func likes(_ n: Int) -> String { likesFmtKey.localized(n) }
        }
    
    
    enum PlaceTypes {
        // Keys
        static let titleKey = "PlaceTypes.Title"   // 타입명이 아직 없을 때
        static let emptyKey = "PlaceTypes.Empty"                   // 목록 비었을 때

        // Values
        static var title: String { titleKey.localized }
        static var empty: String { emptyKey.localized }
    }
    
    enum PlaceCharacters{
        // Keys
        static let titleKey = "PlaceCharacters.Title"   // 타입명이 아직 없을 때
        static let emptyKey = "PlaceCharacters.Empty"                   // 목록 비었을 때

        // Values
        static var title: String { titleKey.localized }
        static var empty: String { emptyKey.localized }
    }
    
    enum PlacesByCharacter {
        // Keys
        static let titleKey = "PlacesByCharacter.Title"
        static let emptyKey = "PlacesByCharacter.Empty"

        
        // Values
        static func title(_ char: String) -> String { titleKey.localized(char) }
        static var empty: String { emptyKey.localized }
        
    }
    
    enum Auth {
        
        static let titleKey = "Auth.Title" // 로그인 시트 헤더
        static var title: String { titleKey.localized }

        static let localKey = "Auth.Local"
        static let googleKey = "Auth.Google"
        static let appleKey = "Auth.Apple"
        static var local: String { localKey.localized }
        static var google: String { googleKey.localized }
        static var apple: String { appleKey.localized }

        // 더 자연스러운 버튼 문구(선택)
        static let continueWithGoogleKey = "Auth.ContinueWith.Google"
        static let continueWithAppleKey = "Auth.ContinueWith.Apple"
        static let continueWithLocalKey = "Auth.ContinueWith.Local"

        static var continueWithGoogle: String { continueWithGoogleKey.localized }
        static var continueWithApple: String { continueWithAppleKey.localized }
        static var continueWithLocal: String { continueWithLocalKey.localized }
        
        
    }
    
    
    enum Memo {
        static let addTitleKey = "Memo.AddTitle"       // "Add Memo"
        static let updateTitleKey = "Memo.UpdateTitle" // "Update Memo"
        static let deleteKey = "Memo.Delete"           // "Delete Memo"
        static let placeholderKey = "Memo.Placeholder" // (선택) "Write your memo..."
        static let textRequiredKey = "Memo.TextRequired"
        
        static var addTitle: String { addTitleKey.localized }
        static var updateTitle: String { updateTitleKey.localized }
        static var delete: String { deleteKey.localized }
        static var placeholder: String { placeholderKey.localized }
        static var textRequired: String { textRequiredKey.localized }
    }
    
    
    enum MyCollection {
        static let favoritesKey = "MyCollection.Favorites"
        static let memosKey = "MyCollection.Memos"
        static let savesKey = "MyCollection.Saves"
        static let emptyKey = "MyCollection.Empty"

        static var favorites: String { favoritesKey.localized }
        static var memos: String { memosKey.localized }
        static var saves: String { savesKey.localized }
        static var empty: String { emptyKey.localized }

    }
    
    
    enum PlaceModification {
        static let titleKey = "PlaceModification.Title"                // "Request Modification"
        static let successMessageKey = "PlaceModification.Success"     // "수정이 요청되었습니다."
        static let placeholderKey = "PlaceModification.Placeholder"    // 선택: "무엇을 수정해야 할지 알려주세요"

        static var title: String { titleKey.localized }
        static var success: String { successMessageKey.localized }
        static var placeholder: String { placeholderKey.localized }
    }
    
    
    enum RecentSearches {
        static let titleKey = "RecentSearches.Title"
        static let clearAllKey = "RecentSearches.ClearAll"
        static let emptyKey = "RecentSearches.Empty"

        static var title: String { titleKey.localized }
        static var clearAll: String { clearAllKey.localized }
        static var empty: String { emptyKey.localized }
    }
    
    
    enum PopularPlaces {
        static let titleKey = "PopularPlaces.Title"
        static let emptyKey = "PopularPlaces.Empty"

        static var title: String { titleKey.localized }
        static var empty: String { emptyKey.localized }
    }
    
    
    enum MyPage {
        static let guestNameKey = "MyPage.GuestName"
        static let emailHiddenKey = "MyPage.EmailHidden"
        static let menuEmptyKey = "MyPage.MenuEmpty"
        static let accountManagementKey = "MyPageMenu.AccountManagement"
        static let appVersionKey = "MyPageMenu.AppVersion"
        
        static var guestName: String { guestNameKey.localized }
        static var emailHidden: String { emailHiddenKey.localized }
        static var menuEmpty: String { menuEmptyKey.localized }
        static var accountManagement: String { accountManagementKey.localized }
        static var appVersion: String { appVersionKey.localized }
    }
    
    enum AccountManagement {
          static let titleKey = "AccountManagement.Title"
          static var title: String { titleKey.localized }

          // 메뉴 라벨
          static let contactSupportKey = "AccountManagement.ContactSupport"
          static let logoutKey         = "AccountManagement.Logout"
          static let withdrawKey       = "AccountManagement.Withdraw"

          static var contactSupport: String { contactSupportKey.localized }
          static var logout: String         { logoutKey.localized }
          static var withdraw: String       { withdrawKey.localized }

          // 탈퇴 알럿
          static let withdrawConfirmTitleKey = "AccountManagement.WithdrawConfirmTitle"
          static let withdrawConfirmMsgKey   = "AccountManagement.WithdrawConfirmMessage"
          static let withdrawCompleteTitleKey = "AccountManagement.WithdrawCompleteTitle"
          static let withdrawCompleteMsgKey   = "AccountManagement.WithdrawCompleteMessage"

          static var withdrawConfirmTitle: String { withdrawConfirmTitleKey.localized }
          static var withdrawConfirmMessage: String { withdrawConfirmMsgKey.localized }
          static var withdrawCompleteTitle: String { withdrawCompleteTitleKey.localized }
          static var withdrawCompleteMessage: String { withdrawCompleteMsgKey.localized }
      }
    
    enum PlaceReport {
           static let titleKey = "Report.Title" // 상단 헤더
           static var title: String { titleKey.localized }

           static let successKey = "Report.Success" // 성공 알럿 메시지
           static var success: String { successKey.localized }

           static let reasonPlaceholderKey = "Report.ReasonPlaceholder" // 사유 placeholder
           static var reasonPlaceholder: String { reasonPlaceholderKey.localized }

           enum Types {
               static let spamKey = "ReportType.Spam"
               static let inappropriateKey = "ReportType.Inappropriate"
               static let hateSpeechKey = "ReportType.HateSpeech"
               static let falseInfoKey = "ReportType.FalseInfo"
               static let personalInfoKey = "ReportType.PersonalInfo"
               static let etcKey = "ReportType.Etc"

               static var spam: String { spamKey.localized }
               static var inappropriate: String { inappropriateKey.localized }
               static var hateSpeech: String { hateSpeechKey.localized }
               static var falseInfo: String { falseInfoKey.localized }
               static var personalInfo: String { personalInfoKey.localized }
               static var etc: String { etcKey.localized }
           }
       }
    
    enum AppGate {
            static let retryKey = "AppGate.Retry"
            static let checkingKey = "AppGate.Checking"           // "Checking server status…"
            static let restoringKey = "AppGate.Restoring"         // "Restoring session…"
            static let maintenanceKey = "AppGate.Maintenance"     // "Under maintenance."
            static let restrictedKey = "AppGate.Restricted"       // "Access is restricted."
            static let timeoutKey = "AppGate.Timeout"             // "Request timed out. ..."
            static let networkErrorFmtKey = "AppGate.NetworkErrorFmt" // "Network error: %@"

            static var retry: String { retryKey.localized }
            static var checking: String { checkingKey.localized }
            static var restoring: String { restoringKey.localized }
            static var maintenance: String { maintenanceKey.localized }
            static var restricted: String { restrictedKey.localized }
            static var timeout: String { timeoutKey.localized }
            static func networkError(_ msg: String) -> String { networkErrorFmtKey.localized(msg) }
        }
    
    
    enum Report {
        // Keys
        static let titleKey = "Report.Title"
        static let successKey = "Report.Success"
        static let reasonPlaceholderKey = "Report.ReasonPlaceholder"

        static let selectTypePlaceholderKey = "Report.SelectTypePlaceholder"
        static let typeMenuTitleKey = "Report.TypeMenuTitle"

        static let commentRequiredKey = "Report.CommentRequired"
        static let typeRequiredKey = "Report.TypeRequired"
        static let diErrorKey = "Report.DiError"

        // Values
        static var title: String { titleKey.localized }
        static var success: String { successKey.localized }
        static var reasonPlaceholder: String { reasonPlaceholderKey.localized }

        static var selectTypePlaceholder: String { selectTypePlaceholderKey.localized }
        static var typeMenuTitle: String { typeMenuTitleKey.localized }

        static var commentRequired: String { commentRequiredKey.localized }
        static var typeRequired: String { typeRequiredKey.localized }
        static var diError: String { diErrorKey.localized }

        enum Types {
            static let bugReportKey        = "ReportType.BugReport"
            static let featureRequestKey   = "ReportType.FeatureRequest"
            static let uiUxIssueKey        = "ReportType.UiUxIssue"
            static let performanceIssueKey = "ReportType.PerformanceIssue"
            static let dataErrorKey        = "ReportType.DataError"
            static let loginIssueKey       = "ReportType.LoginIssue"
            static let searchIssueKey      = "ReportType.SearchIssue"
            static let mapIssueKey         = "ReportType.MapIssue"
            static let generalFeedbackKey  = "ReportType.GeneralFeedback"
            static let otherKey            = "ReportType.Other"

            static var bugReport: String        { bugReportKey.localized }
            static var featureRequest: String   { featureRequestKey.localized }
            static var uiUxIssue: String        { uiUxIssueKey.localized }
            static var performanceIssue: String { performanceIssueKey.localized }
            static var dataError: String        { dataErrorKey.localized }
            static var loginIssue: String       { loginIssueKey.localized }
            static var searchIssue: String      { searchIssueKey.localized }
            static var mapIssue: String         { mapIssueKey.localized }
            static var generalFeedback: String  { generalFeedbackKey.localized }
            static var other: String            { otherKey.localized }
        }
    }

    
    
    // 성경 책 선택 + 구절 리스트 BottomSheet 전용
        enum VerseListSheet {
            // Keys
            
            static let defaultTitleKey = "VerseListSheet.defaultTitle"
            
            static let titleKey = "VerseListSheet.Title"                   // 헤더 타이틀: "%@의 성경 구절"
            static let selectBookPromptKey = "VerseListSheet.SelectBookPrompt"        // 버튼 기본 타이틀: "책을 선택해주세요."
            static let selectBookMenuTitleKey = "VerseListSheet.SelectBookMenuTitle"     // UIMenu 타이틀: "성경 선택"
            static let searchPlaceholderKey = "VerseListSheet.SearchPlaceholder"       // (옵션) 검색 자리표시자
            static let emptyKey = "VerseListSheet.Empty"                   // 데이터 없음
            static let fetchErrorMessageKey = "VerseListSheet.FetchErrorMessage"       // 네트워크/기타 오류
            static let versesCountFmtKey = "VerseListSheet.VersesCountFmt"          // "%d절"
            static let booksCountFmtKey  = "VerseListSheet.BooksCountFmt"           // "%d권"
            static let moreVersesFmtKey = "VerseListSheet.MoreVersesFmt"           // "%d절 더보기"
            static let moreBooksFmtKey = "VerseListSheet.MoreBooksFmt"            // "%d권 더보기"

            // Values
            
            static var defaultTitle:String{
                defaultTitleKey.localized
            }
            static func title(_ placeName: String) -> String { titleKey.localized(placeName) }
            static var selectBookPrompt: String { selectBookPromptKey.localized }
            static var selectBookMenuTitle: String { selectBookMenuTitleKey.localized }
            static var searchPlaceholder: String { searchPlaceholderKey.localized }
            static var empty: String { emptyKey.localized }
            static var fetchErrorMessage: String { fetchErrorMessageKey.localized }
            static func versesCount(_ n: Int) -> String { versesCountFmtKey.localized(n) }   // stringsdict 권장
            static func booksCount(_ n: Int) -> String { booksCountFmtKey.localized(n) }     // stringsdict 권장
            static func moreVerses(_ n: Int) -> String { moreVersesFmtKey.localized(n) }     // stringsdict 권장
            static func moreBooks(_ n: Int) -> String { moreBooksFmtKey.localized(n) }       // stringsdict 권장
        }
    
    
    enum NetworkError {
           static let urlErrorKey = "NetworkError.UrlError"
           static var urlError: String { urlErrorKey.localized }

           static let invalidKey = "NetworkError.Invalid"
           static var invalid: String { invalidKey.localized }

           static let failToDecodeFmtKey = "NetworkError.FailToDecodeFmt"
           static func failToDecode(_ msg: String) -> String {
               failToDecodeFmtKey.localized(msg)
           }

           static let failToEncodeFmtKey = "NetworkError.FailToEncodeFmt"
           static func failToEncode(_ msg: String) -> String {
               failToEncodeFmtKey.localized(msg)
           }

           static let dataNilKey = "NetworkError.DataNil"
           static var dataNil: String { dataNilKey.localized }

           static let unauthorizedKey = "NetworkError.Unauthorized"
           static var unauthorized: String { unauthorizedKey.localized }

           static let serverErrorFmtKey = "NetworkError.ServerErrorFmt"
           static func serverError(_ code: Int) -> String {
               serverErrorFmtKey.localized(code)
           }

           static let clientErrorFmtKey = "NetworkError.ClientErrorFmt"
           static func clientError(_ msg: String) -> String {
               clientErrorFmtKey.localized(msg)
           }

           static let failToJSONSerializeFmtKey = "NetworkError.FailToJSONSerializeFmt"
           static func failToJSONSerialize(_ msg: String) -> String {
               failToJSONSerializeFmtKey.localized(msg)
           }
       }
    
    enum ClientError {
        static let badRequestKey = "ClientError.BadRequest"
        static let unauthorizedKey = "ClientError.Unauthorized"
        static let paymentRequiredKey = "ClientError.PaymentRequired"
        static let forbiddenKey = "ClientError.Forbidden"
        static let notFoundKey = "ClientError.NotFound"
        
        static let placeIdRequiredKey = "ClientError.PlaceIdRequired"
        static let placeTypeRequiredKey = "ClientError.PlaceTypeRequired"
        static let reasonRequiredKey = "ClientError.ReasonRequired"
        
        
        static var badRequest: String { badRequestKey.localized }
        static var unauthorized: String { unauthorizedKey.localized }
        static var paymentRequired: String { paymentRequiredKey.localized }
        static var forbidden: String { forbiddenKey.localized }
        static var notFound: String { notFoundKey.localized }
        
        static var placeIdRequired :String {
            placeIdRequiredKey.localized
        }
        
        static var placeTypeRequired :String {
            placeTypeRequiredKey.localized
        }
        
        static var reasonRequired: String {
            reasonRequiredKey.localized
        }
    }
    
    enum ServerError {
        static let internalServerErrorKey = "ServerError.InternalServerError"
        static let serviceUnavailableKey = "ServerError.ServiceUnavailable"
        static let unknownKey = "ServerError.Unknown"

        static var internalServerError: String { internalServerErrorKey.localized }
        static var serviceUnavailable: String { serviceUnavailableKey.localized }
        static var unknown: String { unknownKey.localized }
    }
        
    
    enum FatalError {
        static let reExecKey = "FatalError.ReExec"
        static var reExec: String { reExecKey.localized }
    }
    
    enum Login {
        static let invalidFormatKey = "Login.InValidFormat"
        static var invalidFormat: String { invalidFormatKey.localized }
    }
}


