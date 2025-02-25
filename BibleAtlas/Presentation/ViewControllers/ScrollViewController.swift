import UIKit
import SnapKit

class ScrollViewViewController: UIViewController {
    
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.alwaysBounceVertical = true  // ✅ 세로 스크롤 활성화
        sv.showsVerticalScrollIndicator = true // ✅ 스크롤바 표시 (선택)
        sv.showsHorizontalScrollIndicator = false // ❌ 가로 스크롤 비활성화
        return sv
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .lightGray  // ✅ 배경색 추가
        return view
    }()
    
    private let boxView: UIView = {
        let view = UIView()
        view.backgroundColor = .red  // ✅ 테스트용 박스
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(boxView) // ✅ 내부에 박스를 추가 (스크롤 확인용)
    }
    
    private func setupConstraints() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide) // ✅ safeArea에 맞춤
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide) // ✅ scrollView 내부에 맞춤
            make.width.equalTo(scrollView.frameLayoutGuide) // ✅ 가로 크기를 scrollView와 동일하게 설정
        }
        
        boxView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(800) // ✅ 스크롤 확인을 위해 큰 높이 설정
            make.bottom.equalToSuperview().offset(-20) // ✅ 마지막 요소가 contentView의 bottom과 연결되도록 설정
        }
    }
}
