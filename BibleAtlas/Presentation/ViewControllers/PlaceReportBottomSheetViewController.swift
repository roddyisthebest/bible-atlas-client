//
//  ReportBottomSheetViewController.swift
//  BibleAtlas
//
//  Created by 배성연 on 7/23/25.
//

import UIKit
import RxRelay
import RxSwift


final class PlaceReportBottomSheetViewController: UIViewController {

    private var cellHeight = 40;

    private let reportTypes:[PlaceReportType] = [
        .spam,
        .inappropriate,
        .hateSpeech,
        .falseInfomation,
        .personalInfomation,
        .etc
    ]
    
    private var selectedReportType:PlaceReportType? = nil
    
    private let placeReportBottomSheetViewModel:PlaceReportBottomSheetViewModelProtocol;
    
    private let cancelButtonTapped$ = PublishRelay<Void>()

    private let reportTypeCellTapped$ = PublishRelay<PlaceReportType>()
    
    private let disposeBag = DisposeBag();
    
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
        let label = HeaderLabel(text: L10n.PlaceReport.title);
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
        let sv = UIStackView(arrangedSubviews: [tableView, reasonTextView])
        sv.axis = .vertical
        sv.spacing = 20
        return sv
    }()
    
 
    
    
    private lazy var tableView = {
        let tv = UITableView();
        tv.register(ReportTypeTableViewCell.self,forCellReuseIdentifier: ReportTypeTableViewCell.identifier)
        
        
        tv.delegate = self;
        tv.dataSource = self;
        
        tv.layer.cornerRadius = 10;
        tv.layer.masksToBounds = true;
        tv.isScrollEnabled = false
        return tv;
    }()
        
    private let reasonTextView: UITextView = {
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
    
    private func setupUI(){
        view.addSubview(headerStackView)
        view.addSubview(scrollView)
        
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

        tableView.snp.makeConstraints { make in
            make.height.equalTo(cellHeight * reportTypes.count)
        }

        reasonTextView.snp.makeConstraints { make in
            make.height.equalTo(120)
        }
        
        
    }
    
    private func setupStyle(){
        view.backgroundColor = .mainBkg

    }
    
    private func toggleReasonTextView(show: Bool) {
        if show {
            reasonTextView.isHidden = false
            UIView.animate(withDuration: 0.25, animations: {
                self.reasonTextView.alpha = 1
             
            }, completion: { _ in
                self.reasonTextView.becomeFirstResponder()
            })
        } else {
          
            reasonTextView.resignFirstResponder()
            UIView.animate(withDuration: 0.25, animations: {
                self.reasonTextView.alpha = 0
            }, completion: { _ in
                self.reasonTextView.isHidden = true
            })
        }
    }
    
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else {
            return
        }

        let bottomInset = keyboardFrame.height

        UIView.animate(withDuration: duration) {
            self.scrollView.contentInset.bottom = bottomInset
            self.scrollView.scrollIndicatorInsets.bottom = bottomInset
            
            
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.scrollToBottom()
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else {
            return
        }

        UIView.animate(withDuration: duration) {
            self.scrollView.contentInset.bottom = 0
            self.scrollView.scrollIndicatorInsets.bottom = 0
        }
    }

    
    private func scrollToBottom(animated: Bool = true) {
        let bottomOffset = CGPoint(
            x: 0,
            y: max(scrollView.contentSize.height - scrollView.bounds.size.height + scrollView.contentInset.bottom, 0)
        )
        scrollView.setContentOffset(bottomOffset, animated: animated)
    }
    
    
    
    
    private func bindViewModel(){
        
        cancelButton.rx.tap
            .bind(to: cancelButtonTapped$)
            .disposed(by: disposeBag)
        

        
        let confirmButtonTapped$ = confirmButton.rx.tap.asObservable();
            
        
        let confirmTappedWithText$ = confirmButtonTapped$
            .withLatestFrom(reasonTextView.rx.text.orEmpty).asObservable()
        
        let output = self.placeReportBottomSheetViewModel.transform(input: PlaceReportBottomSheetViewModel.Input(cancelButttonTapped$: cancelButtonTapped$.asObservable(), placeTypeCellTapped$: reportTypeCellTapped$.asObservable(), confirmButtonTapped$: confirmTappedWithText$))
        
        
        output.reportType$
            .observe(on: MainScheduler.asyncInstance)
            .bind{[weak self] reportType in
                self?.selectedReportType = reportType
                self?.tableView.reloadData();
                let shouldShow = reportType == .etc
                self?.toggleReasonTextView(show: shouldShow)
            }.disposed(by: disposeBag)
        
        
        output.isLoading$.observe(on: MainScheduler.asyncInstance)
            .bind{[weak self] isLoading in
                self?.confirmButton.isHidden = isLoading
                self?.confirmButton.isUserInteractionEnabled = !isLoading
                self?.confirmLoadingView.isHidden = !isLoading
            }.disposed(by: disposeBag)
        
        
        output.networkError$.observe(on: MainScheduler.asyncInstance)
            .compactMap{ $0 }
            .bind{[weak self] error in
                self?.showErrorAlert(message: error?.description)
            }.disposed(by: disposeBag)
        
        output.clientError$.observe(on: MainScheduler.asyncInstance)
            .compactMap{ $0 }
            .bind{[weak self] error in
                var msg = ""
                switch(error){
                    case .placeId:
                        msg = L10n.ClientError.placeIdRequired
                    case .placeType:
                        msg = L10n.ClientError.placeTypeRequired
                    case .reasonMissing:
                        msg = L10n.ClientError.reasonRequired
                }
                self?.showErrorAlert(message: msg)
            }.disposed(by: disposeBag)
        
        
        output.isSuccess$.observe(on: MainScheduler.asyncInstance)
            .bind{[weak self] isSuccess in
                guard let _ = isSuccess else{
                    return;
                }
                
                self?.showDefaultAlert(message: L10n.PlaceReport.success, buttonTitle: L10n.Common.ok, animated: true, completion: nil, handler: self?.handleSuccessionAlertComplete)
                
            }.disposed(by: disposeBag)
        
    }
    
    @objc private func handleSuccessionAlertComplete(_:UIAlertAction){
        cancelButtonTapped$.accept(Void())
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI();
        setupConstraints();
        setupStyle();
        bindViewModel();
        setupDismissKeyboardOnTap();
        setupKeyboardObservers();
    }
    

    
    
    
    init(placeReportBottomSheetViewModel: PlaceReportBottomSheetViewModelProtocol) {
        self.placeReportBottomSheetViewModel = placeReportBottomSheetViewModel
                
        super.init(nibName: nil, bundle: nil)

    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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

extension PlaceReportBottomSheetViewController:UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        reportTypes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ReportTypeTableViewCell.identifier, for: indexPath) as? ReportTypeTableViewCell else {
            return UITableViewCell()
        }
        
        let reportType = reportTypes[indexPath.row]
        cell.setReportType(report: reportType, isCheck: reportType == selectedReportType)
        
        if indexPath.row == reportTypes.count - 1 {
               cell.separatorInset = UIEdgeInsets(top: 0, left: tableView.bounds.width, bottom: 0, right: 0)
           } else {
               cell.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
        }
        
        
        return cell
        
        
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(cellHeight);
    }
}

extension PlaceReportBottomSheetViewController:UITableViewDelegate{
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let reportType = reportTypes[indexPath.row]
        reportTypeCellTapped$.accept(reportType)
    }
    
    
}


#if DEBUG
extension PlaceReportBottomSheetViewController {
    var _test_tableView: UITableView { tableView }
    var _test_reasonTextView: UITextView { reasonTextView }
    var _test_confirmButton: UIButton { confirmButton }
    var _test_confirmLoadingView: LoadingView { confirmLoadingView }
    var _test_selectedReportType: PlaceReportType? { selectedReportType }
    var _test_cancelButton: UIButton { cancelButton }
    var _test_scrollView: UIScrollView { scrollView }
}
#endif
