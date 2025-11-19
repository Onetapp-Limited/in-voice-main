import UIKit
import SnapKit

class PaywallViewController: UIViewController {
    
    private let viewModel: PaywallViewModel = PaywallViewModel()
    
    private lazy var closeButton = createCloseButton()
    private lazy var scrollView = UIScrollView()
    private lazy var contentView = UIView()
    
    private lazy var mainTitleLabel = createMainTitleLabel()
    private lazy var paywallImageView = createPaywallImageView()
    private lazy var subscriptionPlansStackView = createSubscriptionPlansStackView()
    
    private lazy var continueButton = createContinueButton()
    private lazy var bottomLinksView = createBottomLinksView()
        
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.background
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
        
        contentView.addSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.equalToSuperview().offset(20)
            make.width.height.equalTo(22)
        }
        
        contentView.addSubview(mainTitleLabel)
        mainTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(closeButton.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        contentView.addSubview(paywallImageView)
        paywallImageView.snp.makeConstraints { make in
            make.top.equalTo(mainTitleLabel.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(view.snp.width).multipliedBy(0.5).priority(.low)
        }
        
        contentView.addSubview(subscriptionPlansStackView)
        subscriptionPlansStackView.snp.makeConstraints { make in
            make.top.equalTo(paywallImageView.snp.bottom).offset(-50)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        contentView.addSubview(continueButton)
        continueButton.snp.makeConstraints { make in
            make.top.equalTo(subscriptionPlansStackView.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(60)
        }
        
        contentView.addSubview(bottomLinksView)
        bottomLinksView.snp.makeConstraints { make in
            make.top.equalTo(continueButton.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(30)
            make.bottom.equalToSuperview().inset(30)
        }
    }
    
    private func bindViewModel() {
        viewModel.onPricesUpdated = { [weak self] in
            self?.updateSubscriptionPlans()
        }
        
        viewModel.onDismiss = { [weak self] in
            self?.dismiss(animated: true)
        }
        
        updateSubscriptionPlans()
    }
    
    private func updateSubscriptionPlans() {
        subscriptionPlansStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        let yearlyPlan = createSubscriptionPlanView(
            plan: .yearly,
            title: "Yearly",
            pricePerPeriod: viewModel.yearlyPrice,
            pricePerWeek: viewModel.yearlyPricePerWeek,
            isBestOffer: true,
            isSelected: true
        )
        
        let monthlyPlan = createSubscriptionPlanView(
            plan: .monthly3,
            title: "Monthly",
            pricePerPeriod: viewModel.monthlyPrice,
            pricePerWeek: viewModel.monthlyPricePerWeek,
            isBestOffer: false,
            isSelected: false
        )
        
        let weeklyPlan = createSubscriptionPlanView(
            plan: .weekly,
            title: "Weekly",
            pricePerPeriod: nil,
            pricePerWeek: viewModel.weekPrice,
            isBestOffer: false,
            isSelected: false
        )

        subscriptionPlansStackView.addArrangedSubview(yearlyPlan)
        subscriptionPlansStackView.addArrangedSubview(monthlyPlan)
        subscriptionPlansStackView.addArrangedSubview(weeklyPlan)
        
        viewModel.selectedPlan = .yearly
        updateSelectionState()
    }
    
    private func updateSelectionState() {
        for view in subscriptionPlansStackView.arrangedSubviews {
            if let planView = view as? SubscriptionPlanView {
                let isSelected = planView.plan == viewModel.selectedPlan
                
                if let wrapperView = planView.subviews.first(where: { $0.tag == 101 }) {
                    wrapperView.layer.borderColor = isSelected ? UIColor.primary.cgColor : UIColor.white.cgColor
                    wrapperView.layer.borderWidth = isSelected ? 4 : 1
                }
            }
        }
    }
    
    @objc private func handlePlanTap(_ sender: UITapGestureRecognizer) {
        guard let planView = sender.view as? SubscriptionPlanView else { return }
        viewModel.selectedPlan = planView.plan
        updateSelectionState()
    }

    @objc private func continueButtonTapped() {
        guard let selectedPlan = viewModel.selectedPlan else { return }
        viewModel.continueTapped(with: selectedPlan)
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

private extension PaywallViewController {
    
    func createMainTitleLabel() -> UILabel {
        let label = UILabel()
        label.text = "Drive your business beyond limits"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textColor = UIColor.black
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }

    func createPaywallImageView() -> UIImageView {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "paywallMainImage") ?? UIImage(named: "PayWallImege1")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }
    
    func createSubscriptionPlansStackView() -> UIStackView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 10
        stack.distribution = .fillEqually
        return stack
    }
    
    class SubscriptionPlanView: UIView {
        let plan: SubscriptionPlan
        
        init(plan: SubscriptionPlan) {
            self.plan = plan
            super.init(frame: .zero)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    func createSubscriptionPlanView(
        plan: SubscriptionPlan,
        title: String,
        pricePerPeriod: String?,
        pricePerWeek: String?,
        isBestOffer: Bool,
        isSelected: Bool
    ) -> SubscriptionPlanView {
        
        let planView = SubscriptionPlanView(plan: plan)
        planView.layer.masksToBounds = false
        planView.backgroundColor = .clear
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handlePlanTap(_:)))
        planView.addGestureRecognizer(tapGesture)
        
        // --- WRAPPER VIEW (Контейнер для границы и контента) ---
        let wrapperView = UIView()
        wrapperView.tag = 101
        wrapperView.layer.cornerRadius = 20
        wrapperView.layer.masksToBounds = true
        wrapperView.backgroundColor = UIColor.white
        wrapperView.layer.borderWidth = isSelected ? 4 : 1
        wrapperView.layer.borderColor = isSelected ? UIColor.primary.cgColor : UIColor.white.cgColor
        
        planView.addSubview(wrapperView)
        wrapperView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = UIColor.black
        
        let pricePerPeriodLabel = UILabel()
        if let price = pricePerPeriod {
            pricePerPeriodLabel.text = price
            pricePerPeriodLabel.font = .systemFont(ofSize: 14, weight: .regular)
            pricePerPeriodLabel.textColor = UIColor.secondaryText
        } else {
            pricePerPeriodLabel.text = " "
        }
        
        let leftStack = UIStackView(arrangedSubviews: [titleLabel, pricePerPeriodLabel])
        leftStack.axis = .vertical
        leftStack.alignment = .leading
        leftStack.spacing = 2
        
        let pricePerWeekLabel = UILabel()
        if let price = pricePerWeek {
            pricePerWeekLabel.text = price + " / week"
            pricePerWeekLabel.font = .systemFont(ofSize: 14, weight: .semibold)
            pricePerWeekLabel.textColor = UIColor.black
        }

        let rightStack = UIStackView(arrangedSubviews: [pricePerWeekLabel])
        rightStack.axis = .vertical
        rightStack.alignment = .trailing
        
        let hStack = UIStackView(arrangedSubviews: [leftStack, rightStack])
        hStack.axis = .horizontal
        hStack.distribution = .fill
        hStack.alignment = .center
        hStack.spacing = 10
        
        wrapperView.addSubview(hStack)
        hStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 5, left: 15, bottom: 5, right: 15))
            make.height.equalTo(50)
        }
        
        if isBestOffer {
            let badgeView = createBadgeView(text: "Save 69%")
            planView.addSubview(badgeView)
            
            badgeView.snp.makeConstraints { make in
                make.top.equalToSuperview().inset(-12)
                make.trailing.equalToSuperview().inset(10)
                make.height.equalTo(24)
            }
            planView.bringSubviewToFront(badgeView)
        }
        
        return planView
    }
    
    func createBadgeView(text: String) -> UIView {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 12, weight: .bold)
        label.textColor = UIColor.white
        label.textAlignment = .center
        
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.9, green: 0.7, blue: 0.2, alpha: 1.0)
        view.layer.cornerRadius = 12
        view.addSubview(label)
        
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8))
        }
        
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        return view
    }

    func createCloseButton() -> UIButton {
        let button = UIButton(type: .system)
        let image = UIImage(systemName: "xmark")?.withConfiguration(UIImage.SymbolConfiguration(pointSize: 20))
        button.setImage(image, for: .normal)
        button.tintColor = UIColor.secondaryText.withAlphaComponent(0.5)
        button.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        return button
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
    
    func createBottomLinksView() -> UIStackView {
        let privacyButton = createBottomLinkButton(title: "Privacy Policy", action: #selector(privacyPolicyTapped))
        let restoreButton = createBottomLinkButton(title: "Restore", action: #selector(restoreTapped))
        let termsButton = createBottomLinkButton(title: "Terms of Use", action: #selector(termsOfUseTapped))
        
        let stack = UIStackView(arrangedSubviews: [privacyButton, restoreButton, termsButton])
        stack.axis = .horizontal
        stack.distribution = .equalSpacing
        stack.spacing = 15
        
        return stack
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
