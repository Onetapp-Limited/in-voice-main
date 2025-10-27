import UIKit
import SnapKit

class HomeViewController: UIViewController {

    private let cellReuseIdentifier = "homeCollectionViewCell"

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false // Отключаем autoresizing mask
        collectionView.backgroundColor = .systemBackground // Устанавливаем фон
        return collectionView
    }()

    final var homeActionLabels = ["Create a new invoice",
                                  "Edit information",
                                  "Manage clients",
                                  "View saved items",
                                  "View previous invoices",
                                  "Settings"]

    final var imageStrings = ["newInvoiceImage",
                              "curUserImage",
                              "clientsImage",
                              "viewSavedItemsImage",
                              "previousInvoicesImage",
                              "settingsImage"]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Home"
        view.backgroundColor = .systemBackground
        
        setupLayout()
        setupCollectionView()
    }
}

extension HomeViewController {
    
    func setupLayout() {
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top) // Привязка к Safe Area сверху
            make.leading.trailing.equalToSuperview() // Привязка к левому и правому краям супервью
            make.bottom.equalToSuperview() // Привязка к нижнему краю супервью
        }
    }
    
    func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(HomeCollectionViewCell.self, forCellWithReuseIdentifier: cellReuseIdentifier)
        
        
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
            layout.minimumInteritemSpacing = 10 // Добавляем минимальный интервал между элементами
            layout.minimumLineSpacing = 10 // Добавляем минимальный интервал между линиями
            
            layout.itemSize = CGSize(width: collectionView.frame.width/2-17 , height: collectionView.frame.width/2-17)
        }
    }
}

extension HomeViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return homeActionLabels.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseIdentifier, for: indexPath) as? HomeCollectionViewCell
        else {
            return UICollectionViewCell()
        }
        
        let customCell = cell
        customCell.actionLabel.text = homeActionLabels[indexPath.row]
        customCell.imageIcon.image = UIImage(named: imageStrings[indexPath.row]) ?? UIImage()
        customCell.updateShadow()
        
        
        // Временный вариант, чтобы коллекция работала
        cell.backgroundColor = .systemGray5
        cell.layer.cornerRadius = 8
        
        return cell
    }
    
    // UICollectionViewDelegate (Навигация полностью закомментирована)
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        /*
        // Навигация (переходы) полностью закомментированы.
        // Используй эту структуру для программного перехода, когда создашь новые VC.
        
        switch indexPath.row {
        case 0:
            // Создание и презентация нового VC (был "newInvoiceVC")
            // let vc = NewInvoiceViewController()
            // vc.modalPresentationStyle = .fullScreen // Соответствует .overFullScreen
            // self.present(vc, animated: true)
            break
        case 1:
            // let vc = EditInfoViewController()
            // self.present(vc, animated: true)
            break
        case 2:
            // let vc = ClientsViewController()
            // self.present(vc, animated: true)
            break
        case 3:
            // let vc = ItemsViewController()
            // self.present(vc, animated: true)
            break
        case 4:
            // let vc = PreviousInvoicesViewController()
            // vc.modalPresentationStyle = .fullScreen
            // self.present(vc, animated: true)
            break
        case 5:
            // let vc = SettingsViewController()
            // self.present(vc, animated: true)
            break
        default:
            print("Could not find indexpath")
        }
        */
    }
}

//---

// Если нужен динамический расчет размера ячейки, как был в оригинале:
extension HomeViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
                
        let inset: CGFloat = 10.0 // sectionInset
        let spacing: CGFloat = 10.0 // minimumInteritemSpacing
        
        let totalHorizontalPadding = (inset * 2) + spacing
        
        let width = (collectionView.bounds.width - totalHorizontalPadding) / 2
        
        let height = width
        
        return CGSize(width: width, height: height)
    }
}
