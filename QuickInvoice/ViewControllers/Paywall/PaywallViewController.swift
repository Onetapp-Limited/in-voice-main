import UIKit
import SnapKit

class PaywallViewController: UIViewController {
    
    // MARK: - Properties
    
    private let viewModel: PaywallViewModel = PaywallViewModel()
    
    // UI элементы
    private lazy var closeButton = createCloseButton()
    private lazy var scrollView = UIScrollView()
    private lazy var contentView = UIView()
    private lazy var headerView = createHeaderView()
    private lazy var iconsBlockView = createIconsBlockView()
    private lazy var featuresTagView = createFeaturesTagView()
    private lazy var trialLabelsStackView = createTrialLabelsStackView()
    private lazy var priceLabel = createPriceLabel()
    private lazy var continueButton = createContinueButton()
    private lazy var bottomLinksView = createBottomLinksView()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = UIColor.background
        
        // ScrollView для контента
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
        }
        
        // Header
        contentView.addSubview(headerView)
        headerView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(-10)
            make.leading.trailing.equalToSuperview()
        }
        
        // Icons Block
        contentView.addSubview(iconsBlockView)
        iconsBlockView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        // Features Tag View
        contentView.addSubview(featuresTagView)
        featuresTagView.snp.makeConstraints { make in
            make.top.equalTo(iconsBlockView.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        // Trial Labels Stack
        contentView.addSubview(trialLabelsStackView)
        trialLabelsStackView.snp.makeConstraints { make in
            make.top.equalTo(featuresTagView.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
        }
        
        // Price Label
        contentView.addSubview(priceLabel)
        priceLabel.snp.makeConstraints { make in
            make.top.equalTo(trialLabelsStackView.snp.bottom).offset(40)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        // Continue Button
        contentView.addSubview(continueButton)
        continueButton.snp.makeConstraints { make in
            make.top.equalTo(priceLabel.snp.bottom).offset(40)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(60)
        }
        
        // Bottom Links
        contentView.addSubview(bottomLinksView)
        bottomLinksView.snp.makeConstraints { make in
            make.top.equalTo(continueButton.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().offset(-20)
        }
        
        // Close Button
        view.addSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(-15)
            make.leading.equalToSuperview().offset(30)
            make.width.height.equalTo(22)
        }
    }
    
    private func bindViewModel() {
        viewModel.onPricesUpdated = { [weak self] in
            guard let self = self else { return }
            self.updatePriceLabel()
        }
        
        viewModel.onDismiss = { [weak self] in
            self?.dismiss(animated: true)
        }
        
        updatePriceLabel()
    }
    
    // MARK: - Actions & Updates
    
    private func updatePriceLabel() {
        priceLabel.text = "Try 3 days free, after \(viewModel.weekPrice)/week\nCancel anytime"
    }
    
    @objc private func continueButtonTapped() {
        viewModel.continueTapped(with: .weekly)
    }
    
    @objc private func closeButtonTapped() {
        self.dismiss(animated: true)
    }
    
    @objc private func privacyPolicyTapped() {
        viewModel.privacyPolicyTapped()
    }
    
    @objc private func restoreTapped() {
        viewModel.restoreTapped()
    }
    
    @objc private func termsOfUseTapped() {
        viewModel.licenseAgreementTapped()
    }
}

// MARK: - UI Element Factory

private extension PaywallViewController {
    
    func createCloseButton() -> UIButton {
        let button = UIButton(type: .system)
        let image = UIImage(systemName: "xmark")?.withConfiguration(UIImage.SymbolConfiguration(pointSize: 20))
        button.setImage(image, for: .normal)
        button.tintColor = UIColor.secondaryText.withAlphaComponent(0.5)
        button.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        return button
    }
    
    func createHeaderView() -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = "Premium Free"
        titleLabel.font = .systemFont(ofSize: 40, weight: .semibold)
        titleLabel.textColor = UIColor.primary
        titleLabel.textAlignment = .center
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = "for 3 days"
        subtitleLabel.font = .systemFont(ofSize: 40, weight: .semibold)
        subtitleLabel.textColor = UIColor.black
        subtitleLabel.textAlignment = .center
        
        let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .center
        
        return stack
    }
    
    func createIconsBlockView() -> UIView {
        let iconData = [
            ("PayWallImege1", "Unlimited\nInvoices"),
            ("PayWallImege2", "Advanced\nReports"),
            ("PayWallImege3", "Estimate\nManagement")
        ]
        
        let iconViews = iconData.map { (imageName, text) -> UIView in
            return self.createIconWithText(imageName: imageName, text: text)
        }
        
        let stack = UIStackView(arrangedSubviews: iconViews)
        stack.axis = .horizontal
        stack.spacing = 15
        stack.distribution = .fillEqually
        stack.alignment = .top
        
        return stack
    }
    
    func createIconWithText(imageName: String, text: String) -> UIView {
        let imageView = UIImageView()
        imageView.image = UIImage(named: imageName)
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = UIColor.iconPrimary
        
        let textLabel = UILabel()
        textLabel.text = text
        textLabel.numberOfLines = 2
        textLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        textLabel.textColor = UIColor.primaryText
        textLabel.textAlignment = .center
        
        let stack = UIStackView(arrangedSubviews: [imageView, textLabel])
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .center
        
        imageView.snp.makeConstraints { make in
            make.width.height.equalTo(80)
        }
        
        return stack
    }
    
    func createFeaturesTagView() -> UIView {
        let features = [
            "Detailed analytics of income, expenses, and balance",
            "Store clients, estimates, and payment statuses — all in one place",
            "Download and send invoices without watermarks"
        ]
        
        let featureViews = features.map { text -> UIView in
            return createFeatureTagLabel(text: text)
        }
        
        let vStack = UIStackView(arrangedSubviews: featureViews)
        vStack.axis = .vertical
        vStack.spacing = 10
        vStack.distribution = .fill
        vStack.alignment = .fill
        
        return vStack
    }
    
    func createFeatureTagLabel(text: String) -> UIView {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 14, weight: .bold)
        label.textColor = UIColor.black
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textAlignment = .left
        
        let containerView = UIView()
        containerView.backgroundColor = .clear // UIColor.secondary.withAlphaComponent(0.1)
        containerView.layer.cornerRadius = 8
        
        containerView.addSubview(label)
        label.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(12)
            make.top.bottom.equalToSuperview().inset(8)
        }
        
        return containerView
    }
    
    func createTrialLabelsStackView() -> UIStackView {
        let label1 = createStyledLabel(text: "100% FREE FOR 3 DAYS", color: UIColor.primary, opacity: 1.0)
        let label2 = createStyledLabel(text: "FULL ACCESS", color: UIColor.primary, opacity: 0.8)
        let label3 = createStyledLabel(text: "ZERO RISK", color: UIColor.primary, opacity: 0.6)
        
        let stack = UIStackView(arrangedSubviews: [label1, label2, label3])
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .center
        
        return stack
    }
    
    func createStyledLabel(text: String, color: UIColor, opacity: CGFloat) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 22, weight: .bold)
        label.textColor = color.withAlphaComponent(opacity)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }
    
    func createPriceLabel() -> UILabel {
        let label = UILabel()
        label.text = "Try 3 days free, after N/A/week\nCancel anytime"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = UIColor.secondaryText.withAlphaComponent(0.4)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }
    
    func createContinueButton() -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle("Continue", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        button.setTitleColor(UIColor.white, for: .normal)
        button.backgroundColor = UIColor.primary
        button.layer.cornerRadius = 30
        button.addTarget(self, action: #selector(continueButtonTapped), for: .touchUpInside)
        return button
    }
    
    func createBottomLinksView() -> UIView {
        let privacyButton = createBottomLinkButton(title: "Privacy Policy", action: #selector(privacyPolicyTapped))
        let restoreButton = createBottomLinkButton(title: "Restore", action: #selector(restoreTapped))
        let termsButton = createBottomLinkButton(title: "Terms of Use", action: #selector(termsOfUseTapped))
        
        let stack = UIStackView(arrangedSubviews: [privacyButton, restoreButton, termsButton])
        stack.axis = .horizontal
        stack.spacing = 20
        stack.distribution = .equalSpacing
        stack.alignment = .center
        
        let wrapper = UIView()
        wrapper.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.top.bottom.equalToSuperview().inset(10)
        }
        
        return wrapper
    }
    
    func createBottomLinkButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 12)
        button.setTitleColor(UIColor.secondaryText, for: .normal)
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }
}
