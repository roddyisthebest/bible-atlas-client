//
//  PlaceType.swift
//  BibleAtlas
//
//  Created by 배성연 on 11/3/25.
//

import Foundation

struct PlaceType: Decodable {
    var id: Int
    var name: PlaceTypeName
}

// ✅ Decodable → Codable 로 바꿔두면 encode도 커스터마이즈 가능
enum PlaceTypeName: String, Codable {
    case river
    case mountainRange = "mountain range"
    case settlement
    case campsite
    case peopleGroup = "people group"
    case region
    case mountain
    case spring
    case hill
    case bodyOfWater = "body of water"
    case road
    case canal
    case valley
    case field
    case mountainPass = "mountain pass"
    case tree
    case mountainRidge = "mountain ridge"
    case wadi
    case well
    case structure
    case naturalArea = "natural area"
    case altar
    case gate
    case pool
    case ford
    case island
    case wall
    case archipelago
    case districtInSettlement = "district in settlement"
    case rock
    case garden
    case probabilityCenterRadial = "probability center radial"
    case cave
    case stoneHeap = "stone heap"
    case harbor
    case hall
    case intersection
    case cliff
    case forest
    case room
    case mine
    case marsh
    case plateau
    case promontory
    case probabilityCenterNToS = "probability center n-s"
    case mouthOfRiver = "mouth of river"
    case fortification = "fortification"
}

// MARK: - Display names (EN/KR) + helpers
extension PlaceTypeName {
    /// EN 공식 표기 (타이틀 케이스)
    var titleEn: String { Self._en[self]! }
    /// KR 공식 표기
    var titleKo: String { Self._ko[self]! }

    /// 현재/지정 Locale에 따른 표기
    func title(locale: Locale = .current) -> String {
        let lang = (locale.language.languageCode ?? "en")
        return lang == "ko" ? titleKo : titleEn
    }

    /// TypeScript enum 키 (camelCase)
    var tsKey: String { Self._tsKey[self]! }

    /// rawValue 그대로 (서버 저장용 문자열)
    var code: String { rawValue }

    // --- maps ---
    private static let _en: [PlaceTypeName: String] = [
        .river: "River",
        .mountainRange: "Mountain Range",
        .settlement: "Settlement",
        .campsite: "Campsite",
        .peopleGroup: "People Group",
        .region: "Region",
        .mountain: "Mountain",
        .spring: "Spring",
        .hill: "Hill",
        .bodyOfWater: "Body of Water",
        .road: "Road",
        .canal: "Canal",
        .valley: "Valley",
        .field: "Field",
        .mountainPass: "Mountain Pass",
        .tree: "Tree",
        .mountainRidge: "Mountain Ridge",
        .wadi: "Wadi",
        .well: "Well",
        .structure: "Structure",
        .naturalArea: "Natural Area",
        .altar: "Altar",
        .gate: "Gate",
        .pool: "Pool",
        .ford: "Ford",
        .island: "Island",
        .wall: "Wall",
        .archipelago: "Archipelago",
        .districtInSettlement: "District in Settlement",
        .rock: "Rock",
        .garden: "Garden",
        .probabilityCenterRadial: "Probability Center (Radial)",
        .cave: "Cave",
        .stoneHeap: "Stone Heap",
        .harbor: "Harbor",
        .hall: "Hall",
        .intersection: "Intersection",
        .cliff: "Cliff",
        .forest: "Forest",
        .room: "Room",
        .mine: "Mine",
        .marsh: "Marsh",
        .plateau: "Plateau",
        .promontory: "Promontory",
        .probabilityCenterNToS: "Probability Center (N–S)",
        .mouthOfRiver: "Mouth of River",
        .fortification: "Fortification"
    ]

    private static let _ko: [PlaceTypeName: String] = [
        .river: "강",
        .mountainRange: "산맥",
        .settlement: "정착지",
        .campsite: "야영지",
        .peopleGroup: "민족 집단",
        .region: "지역",
        .mountain: "산",
        .spring: "샘",
        .hill: "언덕",
        .bodyOfWater: "수역",
        .road: "길",
        .canal: "운하",
        .valley: "골짜기",
        .field: "들판",
        .mountainPass: "고개",
        .tree: "나무",
        .mountainRidge: "산등성이",
        .wadi: "와디(건천)",
        .well: "우물",
        .structure: "구조물",
        .naturalArea: "자연 지형",
        .altar: "제단",
        .gate: "성문",
        .pool: "못",
        .ford: "여울목",
        .island: "섬",
        .wall: "성벽",
        .archipelago: "군도",
        .districtInSettlement: "도시 구역",
        .rock: "바위",
        .garden: "정원",
        .probabilityCenterRadial: "확률 중심(방사형)",
        .cave: "동굴",
        .stoneHeap: "돌무더기",
        .harbor: "항구",
        .hall: "회관",
        .intersection: "교차로",
        .cliff: "절벽",
        .forest: "숲",
        .room: "방",
        .mine: "광산",
        .marsh: "늪지",
        .plateau: "고원",
        .promontory: "곶",
        .probabilityCenterNToS: "확률 중심(N–S)",
        .mouthOfRiver: "강 하구",
        .fortification: "요새"
    ]

    private static let _tsKey: [PlaceTypeName: String] = [
        .river: "river",
        .mountainRange: "mountainRange",
        .settlement: "settlement",
        .campsite: "campsite",
        .peopleGroup: "peopleGroup",
        .region: "region",
        .mountain: "mountain",
        .spring: "spring",
        .hill: "hill",
        .bodyOfWater: "bodyOfWater",
        .road: "road",
        .canal: "canal",
        .valley: "valley",
        .field: "field",
        .mountainPass: "mountainPass",
        .tree: "tree",
        .mountainRidge: "mountainRidge",
        .wadi: "wadi",
        .well: "well",
        .structure: "structure",
        .naturalArea: "naturalArea",
        .altar: "altar",
        .gate: "gate",
        .pool: "pool",
        .ford: "ford",
        .island: "island",
        .wall: "wall",
        .archipelago: "archipelago",
        .districtInSettlement: "districtInSettlement",
        .rock: "rock",
        .garden: "garden",
        .probabilityCenterRadial: "probabilityCenterRadial",
        .cave: "cave",
        .stoneHeap: "stoneHeap",
        .harbor: "harbor",
        .hall: "hall",
        .intersection: "intersection",
        .cliff: "cliff",
        .forest: "forest",
        .room: "room",
        .mine: "mine",
        .marsh: "marsh",
        .plateau: "plateau",
        .promontory: "promontory",
        .probabilityCenterNToS: "probabilityCenterNToS",
        .mouthOfRiver: "mouthOfRiver",
        .fortification: "fortification"
    ]
}

