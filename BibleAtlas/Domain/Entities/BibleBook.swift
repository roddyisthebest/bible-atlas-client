//
//  BibleBook.swift
//  BibleAtlas
//
//  Created by 배성연 on 9/23/25.
//

import Foundation

enum BibleBook: String, Codable, CaseIterable {
    case Gen = "ge"
    case Exod = "exo"
    case Lev = "lev"
    case Num = "num"
    case Deut = "deu"
    case Josh = "josh"
    case Judg = "jdgs"
    case Ruth = "ruth"
    case Sam1 = "1sm"
    case Sam2 = "2sm"
    case Kgs1 = "1ki"
    case Kgs2 = "2ki"
    case Chr1 = "1chr"
    case Chr2 = "2chr"
    case Ezra = "ezra"
    case Neh = "neh"
    case Esth = "est"
    case Job = "job"
    case Ps = "psa"
    case Prov = "prv"
    case Eccl = "eccl"
    case Song = "ssol"
    case Isa = "isa"
    case Jer = "jer"
    case Lam = "lam"
    case Ezek = "eze"
    case Dan = "dan"
    case Hos = "hos"
    case Joel = "joel"
    case Amos = "amos"
    case Obad = "obad"
    case Jonah = "jonah"
    case Mic = "mic"
    case Nah = "nahum"
    case Hab = "hab"
    case Zeph = "zep"
    case Hag = "hag"
    case Zech = "zec"
    case Mal = "mal"
    case Matt = "mat"
    case Mark = "mark"
    case Luke = "luke"
    case John = "john"
    case Acts = "acts"
    case Rom = "rom"
    case Cor1 = "1cor"
    case Cor2 = "2cor"
    case Gal = "gal"
    case Eph = "eph"
    case Phil = "phi"
    case Col = "col"
    case Thess1 = "1th"
    case Thess2 = "2th"
    case Tim1 = "1tim"
    case Tim2 = "2tim"
    case Titus = "titus"
    case Phile = "phmn"
    case Heb = "heb"
    case Jam = "jas"
    case Pet1 = "1pet"
    case Pet2 = "2pet"
    case Jn1 = "1jn"
    case Jn2 = "2jn"
    case Jn3 = "3jn"
    case Jude = "jude"
    case Rev = "rev"
    case Etc = "etc"
}

// MARK: - Display names (EN/KR) + helpers
extension BibleBook {
    /// EN 공식 표기
    var titleEn: String { Self._en[self]! }
    /// KR 공식 표기
    var titleKo: String { Self._ko[self]! }

    /// 현재/지정 Locale에 따른 표기
    func title(locale: Locale = .current) -> String {
        let lang = (locale.language.languageCode ?? "en")
        return lang == "ko" ? titleKo : titleEn
    }

    /// TypeScript enum 키가 필요하면 이걸로 (e.g. "1Sam")
    var tsKey: String { Self._tsKey[self]! }

    /// rawValue 그대로 노출하고 싶을 때 가독성용 별칭
    var code: String { rawValue }

    // --- maps ---
    private static let _en: [BibleBook: String] = [
        .Gen: "Genesis", .Exod: "Exodus", .Lev: "Leviticus", .Num: "Numbers", .Deut: "Deuteronomy",
        .Josh: "Joshua", .Judg: "Judges", .Ruth: "Ruth",
        .Sam1: "1 Samuel", .Sam2: "2 Samuel",
        .Kgs1: "1 Kings", .Kgs2: "2 Kings",
        .Chr1: "1 Chronicles", .Chr2: "2 Chronicles",
        .Ezra: "Ezra", .Neh: "Nehemiah", .Esth: "Esther", .Job: "Job",
        .Ps: "Psalms", .Prov: "Proverbs", .Eccl: "Ecclesiastes", .Song: "Song of Songs",
        .Isa: "Isaiah", .Jer: "Jeremiah", .Lam: "Lamentations", .Ezek: "Ezekiel", .Dan: "Daniel",
        .Hos: "Hosea", .Joel: "Joel", .Amos: "Amos", .Obad: "Obadiah", .Jonah: "Jonah",
        .Mic: "Micah", .Nah: "Nahum", .Hab: "Habakkuk", .Zeph: "Zephaniah", .Hag: "Haggai",
        .Zech: "Zechariah", .Mal: "Malachi",
        .Matt: "Matthew", .Mark: "Mark", .Luke: "Luke", .John: "John", .Acts: "Acts",
        .Rom: "Romans",
        .Cor1: "1 Corinthians", .Cor2: "2 Corinthians",
        .Gal: "Galatians", .Eph: "Ephesians", .Phil: "Philippians", .Col: "Colossians",
        .Thess1: "1 Thessalonians", .Thess2: "2 Thessalonians",
        .Tim1: "1 Timothy", .Tim2: "2 Timothy",
        .Titus: "Titus", .Phile: "Philemon",
        .Heb: "Hebrews", .Jam: "James",
        .Pet1: "1 Peter", .Pet2: "2 Peter",
        .Jn1: "1 John", .Jn2: "2 John", .Jn3: "3 John",
        .Jude: "Jude", .Rev: "Revelation", .Etc: "Etc"
    ]

    private static let _ko: [BibleBook: String] = [
        .Gen: "창세기", .Exod: "출애굽기", .Lev: "레위기", .Num: "민수기", .Deut: "신명기",
        .Josh: "여호수아", .Judg: "사사기", .Ruth: "룻기",
        .Sam1: "사무엘상", .Sam2: "사무엘하",
        .Kgs1: "열왕기상", .Kgs2: "열왕기하",
        .Chr1: "역대상", .Chr2: "역대하",
        .Ezra: "에스라", .Neh: "느헤미야", .Esth: "에스더", .Job: "욥기",
        .Ps: "시편", .Prov: "잠언", .Eccl: "전도서", .Song: "아가",
        .Isa: "이사야", .Jer: "예레미야", .Lam: "예레미야 애가", .Ezek: "에스겔", .Dan: "다니엘",
        .Hos: "호세아", .Joel: "요엘", .Amos: "아모스", .Obad: "오바댜", .Jonah: "요나",
        .Mic: "미가", .Nah: "나훔", .Hab: "하박국", .Zeph: "스바냐", .Hag: "학개",
        .Zech: "스가랴", .Mal: "말라기",
        .Matt: "마태복음", .Mark: "마가복음", .Luke: "누가복음", .John: "요한복음", .Acts: "사도행전",
        .Rom: "로마서",
        .Cor1: "고린도전서", .Cor2: "고린도후서",
        .Gal: "갈라디아서", .Eph: "에베소서", .Phil: "빌립보서", .Col: "골로새서",
        .Thess1: "데살로니가전서", .Thess2: "데살로니가후서",
        .Tim1: "디모데전서", .Tim2: "디모데후서",
        .Titus: "디도서", .Phile: "빌레몬서",
        .Heb: "히브리서", .Jam: "야고보서",
        .Pet1: "베드로전서", .Pet2: "베드로후서",
        .Jn1: "요한일서", .Jn2: "요한이서", .Jn3: "요한삼서",
        .Jude: "유다서", .Rev: "요한계시록", .Etc: "기타"
    ]

    private static let _tsKey: [BibleBook: String] = [
        .Gen: "Gen", .Exod: "Exod", .Lev: "Lev", .Num: "Num", .Deut: "Deut",
        .Josh: "Josh", .Judg: "Judg", .Ruth: "Ruth",
        .Sam1: "1Sam", .Sam2: "2Sam",
        .Kgs1: "1Kgs", .Kgs2: "2Kgs",
        .Chr1: "1Chr", .Chr2: "2Chr",
        .Ezra: "Ezra", .Neh: "Neh", .Esth: "Esth", .Job: "Job",
        .Ps: "Ps", .Prov: "Prov", .Eccl: "Eccl", .Song: "Song",
        .Isa: "Isa", .Jer: "Jer", .Lam: "Lam", .Ezek: "Ezek", .Dan: "Dan",
        .Hos: "Hos", .Joel: "Joel", .Amos: "Amos", .Obad: "Obad", .Jonah: "Jonah",
        .Mic: "Mic", .Nah: "Nah", .Hab: "Hab", .Zeph: "Zeph", .Hag: "Hag",
        .Zech: "Zech", .Mal: "Mal",
        .Matt: "Matt", .Mark: "Mark", .Luke: "Luke", .John: "John", .Acts: "Acts",
        .Rom: "Rom",
        .Cor1: "1Cor", .Cor2: "2Cor",
        .Gal: "Gal", .Eph: "Eph", .Phil: "Phil", .Col: "Col",
        .Thess1: "1Thess", .Thess2: "2Thess",
        .Tim1: "1Tim", .Tim2: "2Tim",
        .Titus: "Titus", .Phile: "Phile",
        .Heb: "Heb", .Jam: "Jam",
        .Pet1: "1Pet", .Pet2: "2Pet",
        .Jn1: "1Jn", .Jn2: "2Jn", .Jn3: "3Jn",
        .Jude: "Jude", .Rev: "Rev", .Etc: "Etc"
    ]
}


// MARK: - Custom Codable to accept TS keys ("Gen") and codes ("ge")
extension BibleBook {
    /// TS 키 → Enum 매핑
    private static let tsKeyToCase: [String: BibleBook] = [
        "Gen": .Gen, "Exod": .Exod, "Lev": .Lev, "Num": .Num, "Deut": .Deut,
        "Josh": .Josh, "Judg": .Judg, "Ruth": .Ruth,
        "1Sam": .Sam1, "2Sam": .Sam2,
        "1Kgs": .Kgs1, "2Kgs": .Kgs2,
        "1Chr": .Chr1, "2Chr": .Chr2,
        "Ezra": .Ezra, "Neh": .Neh, "Esth": .Esth, "Job": .Job,
        "Ps": .Ps, "Prov": .Prov, "Eccl": .Eccl, "Song": .Song,
        "Isa": .Isa, "Jer": .Jer, "Lam": .Lam, "Ezek": .Ezek, "Dan": .Dan,
        "Hos": .Hos, "Joel": .Joel, "Amos": .Amos, "Obad": .Obad, "Jonah": .Jonah,
        "Mic": .Mic, "Nah": .Nah, "Hab": .Hab, "Zeph": .Zeph, "Hag": .Hag, "Zech": .Zech, "Mal": .Mal,
        "Matt": .Matt, "Mark": .Mark, "Luke": .Luke, "John": .John, "Acts": .Acts,
        "Rom": .Rom, "1Cor": .Cor1, "2Cor": .Cor2,
        "Gal": .Gal, "Eph": .Eph, "Phil": .Phil, "Col": .Col,
        "1Thess": .Thess1, "2Thess": .Thess2,
        "1Tim": .Tim1, "2Tim": .Tim2,
        "Titus": .Titus, "Phile": .Phile, "Heb": .Heb, "Jam": .Jam,
        "1Pet": .Pet1, "2Pet": .Pet2,
        "1Jn": .Jn1, "2Jn": .Jn2, "3Jn": .Jn3,
        "Jude": .Jude, "Rev": .Rev, "Etc": .Etc
    ]

    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        let raw = try c.decode(String.self)

        // 1) TS 키로 우선 매핑 (대소문자 정확히)
        if let e = Self.tsKeyToCase[raw] {
            self = e
            return
        }
        // 2) 코드값("ge","exo"...)도 허용 (대소문자 관대하게)
        let lowered = raw.lowercased()
        if let e = BibleBook(rawValue: lowered) {
            self = e
            return
        }
        throw DecodingError.dataCorruptedError(in: c, debugDescription: "Invalid BibleBook value: \(raw)")
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        // 서버로 보낼 땐 코드값(rawValue)로 내보냄
        try c.encode(self.rawValue)
    }
}

// BibleBook.swift (아래 extension만 추가)

extension BibleBook {
    /// 임의의 문자열을 BibleBook으로 파싱 (TS 키/코드/케이스명 지원)
    /// 허용 예: "Gen", "ge", "GEN", "1Sam", "1sam", "Cor1", "1Cor"
    init?(parsing string: String) {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let lower = trimmed.lowercased()

        // 1) TS 키 (정확/대소문자 무시) → .Gen, .Sam1, ...
        if let e = Self.tsKeyToCase[trimmed] { self = e; return }
        if let e = Self._tsKeyLowerToCase[lower] { self = e; return }

        // 2) 코드값(rawValue) "ge","exo","1sm" ... (대소문자 무시)
        if let e = BibleBook(rawValue: lower) { self = e; return }

        // 3) enum 케이스명 "Gen","Sam1","Cor1" ... (대소문자 무시)
        if let e = Self._caseNameLowerToCase[lower] { self = e; return }

        return nil
    }

   

    // MARK: - 내부 맵들 (대소문자 무시용)
    private static let _tsKeyLowerToCase: [String: BibleBook] = {
        var m: [String: BibleBook] = [:]
        for (k, v) in Self.tsKeyToCase { m[k.lowercased()] = v }
        return m
    }()

    private static let _caseNameLowerToCase: [String: BibleBook] = {
        var m: [String: BibleBook] = [:]
        for e in Self.allCases {
            m[String(describing: e).lowercased()] = e
        }
        return m
    }()
}



struct BibleBookCount:Decodable {
    var bible:BibleBook;
    var placeCount: Int
}
