//
//  Untitled.swift
//  BibleAtlas
//
//  Created by 배성연 on 1/17/26.
//


import os.signpost

private let poiLog = OSLog(subsystem: "com.seongyeon.bibleatlas", category: .pointsOfInterest)


@inline(__always)
public func spBegin(_ name: StaticString) -> OSSignpostID {
    let id = OSSignpostID(log: poiLog)
    os_signpost(.begin, log: poiLog, name: name, signpostID: id)
    return id
}

@inline(__always)
public func spEnd(_ name: StaticString, _ id: OSSignpostID) {
    os_signpost(.end, log: poiLog, name: name, signpostID: id)
}
