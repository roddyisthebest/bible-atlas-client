//
//  PlaceUsecaseTests.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 9/25/25.
//

import XCTest
@testable import BibleAtlas


final class PlaceUsecaseTests: XCTestCase {
    
    var repo: MockPlaceRepository!
    var sut: PlaceUsecase!
    
    
    override func setUp() {
        super.setUp()
        repo = MockPlaceRepository()
        sut = PlaceUsecase(repository: repo)
    }
    
    override func tearDown() {
        sut = nil
        repo = nil
        super.tearDown()
    }
    
    func test_getPlaces_delegatesToRepository_andReturnsResult() async {
        // given
        let params = PlaceParameters(limit:10, page:2, placeTypeName: nil, name: "abc")
        
        let expected = ListResponse<Place>(total: 0, page: 2, limit: 10, data: [])
        
        repo.next_getPlaces = .success(expected)

        // when
        let result = await sut.getPlaces(parameters: params)

        // then
        XCTAssertEqual(repo.calls.map(\.name).last, "getPlaces")
        XCTAssertEqual(repo.last_parameters_getPlaces?.name, "abc")

        switch result {
        case .success(let list):
            XCTAssertEqual(list.page, 2)
            XCTAssertEqual(list.data.count, 0)
        case .failure:
            XCTFail("should succeed")
        }
    }
    
    func test_getPlace_propagatesFailure() async {
        // given
        repo.next_getPlace = .failure(.serverError(500))

        // when
        let result = await sut.getPlace(placeId: "P1")
        print(result)
        // then
        XCTAssertEqual(repo.calls.map(\.name).last, "getPlace")
        XCTAssertEqual(repo.last_placeId_getPlace, "P1")
        if case .success = result { XCTFail("should fail") }
    }
    
    func test_toggleSave_and_toggleLike_delegate() async {
        // given
        repo.next_toggleSave = .success(TogglePlaceSaveResponse(saved: true))
        repo.next_toggleLike = .success(TogglePlaceLikeResponse(liked: true))

        // when
        let r1 = await sut.toggleSave(placeId: "PX")
        let r2 = await sut.toggleLike(placeId: "PY")

        // then
        XCTAssertEqual(repo.last_placeId_toggleSave, "PX")
        XCTAssertEqual(repo.last_placeId_toggleLike, "PY")

        if case .success(let s) = r1 { XCTAssertTrue(s.saved) } else { XCTFail() }
        if case .success(let l) = r2 { XCTAssertTrue(l.liked);  } else { XCTFail() }
    }
    
    
    func test_memo_create_update_delete_delegate() async {
        repo.next_createOrUpdatePlaceMemo = .success(PlaceMemoResponse(text: "안녕"))
        repo.next_deletePlaceMemo = .success(PlaceMemoDeleteResponse(memo: "안녕"))

        let c = await sut.createOrUpdatePlaceMemo(placeId: "P1", text: "안녕")
        let d = await sut.deletePlaceMemo(placeId: "P1")

        XCTAssertEqual(repo.last_placeId_memo, "P1")
        XCTAssertEqual(repo.last_memoText, "안녕")
        XCTAssertEqual(repo.last_placeId_deleteMemo, "P1")

        if case .success(let resp) = c { XCTAssertEqual(resp.text, "안녕") } else { XCTFail() }
        if case .success(let del) = d { XCTAssertEqual(del.memo, "안녕") } else { XCTFail() }
    }
    
    
    func test_createPlaceProposal_and_report_delegate() async {
        
        let response = PlaceProposalResponse(createdAt: "12", id: 12, type: 3, comment: "선빵")
        repo.next_createPlaceProposal = .success(response)
        repo.next_createPlaceReport = .success(201)

        let p = await sut.createPlaceProposal(placeId: "P2", comment: "fix pls")
        let r = await sut.createPlaceReport(placeId: "P2", reportType: .spam, reason: "bad")

        XCTAssertEqual(repo.last_placeId_proposal, "P2")
        XCTAssertEqual(repo.last_proposalComment, "fix pls")

        if case .success(let id) = r { XCTAssertEqual(id, 201) } else { XCTFail() }
        if case .success(let resp) = p { XCTAssertEqual(resp.id, response.id) } else { XCTFail() }

        XCTAssertEqual(repo.last_placeReportArgs?.0, "P2")
        XCTAssertEqual(repo.last_placeReportArgs?.1, .spam)
        XCTAssertEqual(repo.last_placeReportArgs?.2, "bad")
    }
    
    
    func test_getBibleVerse_delegate() async {
        repo.next_getBibleVerse = .success(BibleVerseResponse(text: "In the beginning"))
        let r = await sut.getBibleVerse(version: .asv, book: "ge", chapter: "1", verse: "1")

        XCTAssertEqual(repo.last_bibleArgs?.0, .asv)
        XCTAssertEqual(repo.last_bibleArgs?.1, "ge")
        if case .success(let v) = r { XCTAssertEqual(v.text, "In the beginning") } else { XCTFail() }
    }
    
    
    func test_parseBible_groupsByBook_andStripsBookPrefix() {
          // given
          let input = "Gen.1.1, Gen.1.2, Exo.2.3"

          // when
          let out = sut.parseBible(verseString: input)

          // then
          // 각 책으로 그룹핑되었는지(순서는 Dict 특성상 불안정할 수 있으니 정렬)
          let sorted = out.sorted { $0.bookName.rawValue < $1.bookName.rawValue }

          // Exo
          if let exo = sorted.first(where: { $0.bookName == .Exod }) {
              XCTAssertEqual(exo.verses, ["2.3"])
          } else { XCTFail("Exo 그룹 없음") }

          // Gen
          if let gen = sorted.first(where: { $0.bookName == .Gen }) {
              XCTAssertEqual(gen.verses.sorted(), ["1.1","1.2"])
          } else { XCTFail("Gen 그룹 없음") }
      }
    
    func test_parseBible_returnsEmpty_onNil_orEmpty() {
        XCTAssertTrue(sut.parseBible(verseString: nil).isEmpty)
        XCTAssertTrue(sut.parseBible(verseString: "").isEmpty)
        XCTAssertTrue(sut.parseBible(verseString: "   ").isEmpty)
    }
    
    
    
    func test_parseBible_unknownBook_fallsBackToEtc() {
          let out = sut.parseBible(verseString: "Foo.3.4, Foo.5.6")
          XCTAssertEqual(out.count, 1)
          XCTAssertEqual(out.first?.bookName, .Etc)
          XCTAssertEqual(out.first?.verses.sorted(), ["3.4","5.6"])
      }

    func test_parseBible_trimsSpaces_and_handlesMixed() {
        let out = sut.parseBible(verseString: "  Gen.  1.1 ,Gen.1.2 ,  Foo.9.9 ")

        let gen = out.first(where: { $0.bookName == .Gen })
        XCTAssertNotNil(gen)

    }
    
    
    
}
