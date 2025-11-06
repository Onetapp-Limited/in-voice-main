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
        navigationItem.title = "Reports"
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.background
        appearance.titleTextAttributes = [.foregroundColor: UIColor.primaryText]
        
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
}

