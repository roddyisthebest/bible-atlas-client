//
//  ReportBottomSheetViewController.swift
//  BibleAtlas
//
//  Created by 배성연 on 11/15/25.
//

import UIKit
import RxSwift
import RxRelay

final class ReportBottomSheetViewController: UIViewController {

    private var reportBottomSheetViewModel: ReportBottomSheetViewModelProtocol
    
    private let disposeBag = DisposeBag();
    
    private let viewLoaded$ = PublishRelay<Void>();
    
    private let cancelButtonTapped$ = PublishRelay<Void>()

    private let reportTypeCellTapped$ = PublishRelay<ReportType>()
    
    private let selectedReportType$ = BehaviorRelay<ReportType?>(value: nil)

    
    private let confirmLoadingView = LoadingView(style:.medium);
    
    
    private lazy var headerStackView = {
        let sv = UIStackView(arrangedSubviews: [cancelButton, headerLabel, confirmButton, confirmLoadingView]);
        sv.axis = .horizontal;
        sv.distribution = .equalSpacing;
        sv.alignment = .center;
        return sv;
    }()
    
    private let cancelButton = {
        let button = UIButton(type: .system);
        button.setTitle(L10n.Common.cancel, for: .normal)
        button.setTitleColor(.primaryBlue, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        return button;
    }()
    
    private let headerLabel = {
        let label = HeaderLabel(text: L10n.Report.title);
        label.font = .boldSystemFont(ofSize: 18);
        return label;
    }()
    
    private let confirmButton = {
        let button = UIButton(type: .system);
        button.setTitle(L10n.Common.done, for: .normal)
        button.setTitleColor(.primaryBlue, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        return button;
    }()
    
    
    private lazy var scrollView = {
        let sv = UIScrollView();
        sv.addSubview(contentStackView)
        return sv;
    }()
    
    
    private lazy var contentStackView: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [selectButton, textView])
        sv.axis = .vertical
        sv.alignment = .fill
        sv.distribution = .fill
        sv.spacing = 20
        return sv
    }()
    
    private let textView: UITextView = {
        let tv = UITextView()
        tv.backgroundColor = .black
        tv.textColor = .mainText
        tv.font = UIFont.systemFont(ofSize: 16)
        tv.backgroundColor = .systemBackground
        tv.isScrollEnabled = true
        tv.isEditable = true
        tv.layer.cornerRadius = 8;
        tv.layer.masksToBounds = true;
        tv.text = ""
        tv.textContainerInset = UIEdgeInsets(top: 15, left: 10, bottom: 15, right: 10) // ✅ 내부 여백 추가
        return tv
    }()
    
    
    private let reportTypes:[ReportType] = [
        .bugReport,
        .dataError,
        .featureRequest,
        .generalFeedback,
        .loginIssue,
        .mapIssue,
        .performanceIssue,
        .searchIssue,
        .uiUxIssue,
        .other
    ]
    
    private let selectButton: UIButton = {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.filled()
        config.title = L10n.Report.selectTypePlaceholder
        config.image = UIImage(systemName: "chevron.down")
        config.imagePlacement = .leading
        config.imagePadding = 8
        config.contentInsets = .init(top: 10, leading: 14, bottom: 10, trailing: 14)
        config.baseForegroundColor = .detailLabelText
        config.baseBackgroundColor = .searchBarBkg
        
        // ✅ 텍스트/아이콘을 왼쪽으로
        config.titleAlignment = .leading            // 1
        button.configuration = config

        button.layer.cornerRadius = 10
        button.layer.masksToBounds = true

        button.configuration?.preferredSymbolConfigurationForImage =
            UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)

        // ✅ 버튼 자체도 왼쪽 정렬
        button.contentHorizontalAlignment = .leading // 2

        return button
    }()

    
    init(reportBottomSheetViewModel: ReportBottomSheetViewModelProtocol) {
        self.reportBottomSheetViewModel = reportBottomSheetViewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI();
        setupConstraints();
        setupStyle();
        bindViewModel();
        setupReportTypeMenu();
        setupDismissKeyboardOnTap();
        // Do any additional setup after loading the view.
    }
    
    
    private func setupUI(){
        view.addSubview(headerStackView)
        view.addSubview(scrollView)
    }
    
    
    private func setupStyle(){
        view.backgroundColor = .mainBkg
    }
    
    private func setupConstraints(){
        headerStackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20);
            make.leading.equalToSuperview().offset(20);
            make.trailing.equalToSuperview().offset(-20);
            make.height.equalTo(44)
        }
        
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(headerStackView.snp.bottom).offset(20)
            make.leading.trailing.bottom.equalToSuperview().inset(20)
        }

        contentStackView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.width.equalTo(scrollView.frameLayoutGuide)
        }

        textView.snp.makeConstraints { make in
            make.height.equalTo(120)
        }
        
    }
    
    
    private func bindViewModel(){
        cancelButton.rx.tap
            .bind(to: cancelButtonTapped$)
            .disposed(by: disposeBag)
            
        let confirmButtonTapped$ = confirmButton.rx.tap.asObservable();
        
        
        let confirmTappedWithTextAndType$ = confirmButtonTapped$
            .withLatestFrom(
                Observable.combineLatest(
                    textView.rx.text,
                    selectedReportType$
                )
            )
        
        
        let output = self.reportBottomSheetViewModel.transform(input: ReportBottomSheetViewModel.Input(viewLoaded$: viewLoaded$.asObservable(), cancelButtonTapped$: cancelButtonTapped$.asObservable(), confirmButtonTapped$: confirmTappedWithTextAndType$.asObservable()))
        
        
        
        
        output.isLoading$
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: {
                [weak self] isLoading in
                
                self?.confirmButton.isHidden = isLoading
                self?.confirmButton.isUserInteractionEnabled = !isLoading
                self?.confirmLoadingView.isHidden = !isLoading
                if(isLoading){
                    self?.confirmLoadingView.start()
                }
                else{
                    self?.confirmLoadingView.stop()
                }
            }).disposed(by: disposeBag)
        
        
        output.interactionError$.observe(on: MainScheduler.instance)            
            .compactMap{ $0 }
            .subscribe(onNext: {[weak self] error in
                self?.showErrorAlert(message: error?.description)
            }).disposed(by: disposeBag)

        
        
        output.isSuccess$.observe(on: MainScheduler.asyncInstance)
            .bind{[weak self] isSuccess in
                guard let _ = isSuccess else{
                    return;
                }
                
                self?.showDefaultAlert(message: L10n.PlaceReport.success, buttonTitle: L10n.Common.ok, animated: true, completion: nil, handler: self?.handleSuccessionAlertComplete)
                
            }.disposed(by: disposeBag)
    }
    
    private func handleSuccessionAlertComplete(_:UIAlertAction){
        cancelButtonTapped$.accept(Void())
    }
    
    private func setupReportTypeMenu() {
        let actions = reportTypes.map { type in
            UIAction(title: type.localizedTitle) { [weak self] _ in
                guard let self = self else { return }
                self.selectButton.setTitleColor(.mainText, for: .normal)
                self.selectedReportType$.accept(type)
                self.selectButton.setTitle(type.localizedTitle, for: .normal)
            }
        }
        
        selectButton.menu = UIMenu(
            title: L10n.PlaceReport.title, // 또는 "신고 유형을 선택하세요"
            children: actions
        )
        selectButton.showsMenuAsPrimaryAction = true
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
