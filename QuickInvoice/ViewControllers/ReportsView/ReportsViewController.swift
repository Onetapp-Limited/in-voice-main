import UIKit
import SnapKit

class ReportsViewController: UIViewController {
    
    // MARK: - UI Elements
    
    private lazy var segmentedControl: UISegmentedControl = {
        let items = ["Invoices", "Expenses", "Balance"]
        let segmented = UISegmentedControl(items: items)
        
        segmented.selectedSegmentTintColor = UIColor.primary
        segmented.backgroundColor = UIColor.surface
        
        let font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        let selectedAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.white,
            .font: font
        ]
        let normalAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.secondaryText,
            .font: font
        ]
        
        segmented.setTitleTextAttributes(normalAttributes, for: .normal)
        segmented.setTitleTextAttributes(selectedAttributes, for: .selected)
        
        segmented.selectedSegmentIndex = 0
        segmented.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        return segmented
    }()
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .background
        return view
    }()
    
    // MARK: - Child View Controllers
    
    private let invoicesReportVC = InvoicesReportViewController()
    private let expensesReportVC = ExpensesReportViewController()
    private let balanceReportVC = BalanceReportViewController()
    
    private var currentChildVC: UIViewController?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.background
        setupNavigationBar()
        setupUI()
        display(childViewController: invoicesReportVC)
    }
    
    // MARK: - Setup
    
    private func setupNavigationBar() {
        
        // 1. Левый элемент: Иконка + Title "InvoiceFly"
        let logoImage = UIImage(systemName: "chart.bar.fill")?.withTintColor(.accent, renderingMode: .alwaysOriginal)
        let logoImageView = UIImageView(image: logoImage)
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.snp.makeConstraints { make in make.size.equalTo(24) }
        
        let titleLabel = UILabel()
        titleLabel.text = "Reports"
        titleLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = .primaryText
        
        let leftStack = UIStackView(arrangedSubviews: [UIView(), logoImageView, titleLabel, UIView()])
        leftStack.axis = .horizontal
        leftStack.spacing = 8
        
        let leftBarItem = UIBarButtonItem(customView: leftStack)
        navigationItem.leftBarButtonItem = leftBarItem
        
        // 2. Правый элемент: PRO Badge
        let proButton = UIButton(type: .custom)
        proButton.setTitle("PRO", for: .normal)
        proButton.setTitleColor(.white, for: .normal)
        proButton.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .heavy)
        
        let starIcon = UIImage(systemName: "crown.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 10, weight: .bold))
        proButton.setImage(starIcon, for: .normal)
        proButton.tintColor = .white
        
        proButton.backgroundColor = UIColor(red: 0.9, green: 0.7, blue: 0.2, alpha: 1.0)
        proButton.contentEdgeInsets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
        proButton.layer.cornerRadius = 10
        proButton.clipsToBounds = true
        
        proButton.addTarget(self, action: #selector(proBadgeTapped), for: .touchUpInside)
        
        let rightBarItem = UIBarButtonItem(customView: proButton)
        navigationItem.rightBarButtonItem = rightBarItem
        
        // 3. Общие настройки Navigation Bar
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.background
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.isTranslucent = false
    }
    
    private func setupUI() {
        view.addSubview(segmentedControl)
        view.addSubview(containerView)
        
        segmentedControl.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(16)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(40)
        }
        
        containerView.snp.makeConstraints { make in
            make.top.equalTo(segmentedControl.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
    }
    
    // MARK: - Child VC Management
    
    @objc private func segmentChanged(_ sender: UISegmentedControl) {
        currentChildVC?.willMove(toParent: nil)
        currentChildVC?.view.removeFromSuperview()
        currentChildVC?.removeFromParent()
        
        let newVC: UIViewController
        switch sender.selectedSegmentIndex {
        case 0:
            newVC = invoicesReportVC
        case 1:
            newVC = expensesReportVC
        case 2:
            newVC = balanceReportVC
        default:
            return
        }
        
        display(childViewController: newVC)
    }
    
    private func display(childViewController: UIViewController) {
        addChild(childViewController)
        containerView.addSubview(childViewController.view)
        childViewController.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        childViewController.didMove(toParent: self)
        currentChildVC = childViewController
    }
    
    @objc func proBadgeTapped() {
        let alert = UIAlertController(title: "Go PRO", message: "Unlock advanced features!", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

