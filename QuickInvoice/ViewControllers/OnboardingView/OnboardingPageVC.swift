import UIKit
import SnapKit

class OnboardingPageVC: UIViewController {
    
    let titleLabel = UILabel()
    let detailLabel = UILabel()
    let imageView = UIImageView()
    
    init(imageName: String, title: String, detail: String) {
        super.init(nibName: nil, bundle: nil)
        self.imageView.image = UIImage(systemName: imageName)
        self.titleLabel.text = title
        self.detailLabel.text = detail
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
    }
    
    private func setupUI() {
        titleLabel.font = .boldSystemFont(ofSize: 28)
        titleLabel.textColor = .systemBlue
        titleLabel.textAlignment = .center
        
        detailLabel.font = .systemFont(ofSize: 17)
        detailLabel.textColor = .secondaryLabel
        detailLabel.textAlignment = .center
        detailLabel.numberOfLines = 0
        
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemBlue
        
        let stackView = UIStackView(arrangedSubviews: [imageView, titleLabel, detailLabel])
        stackView.axis = .vertical
        stackView.spacing = 20
        
        view.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(30)
            make.centerY.equalToSuperview().offset(-50)
            make.height.equalToSuperview().multipliedBy(0.6)
        }
        
        imageView.snp.makeConstraints { make in
            make.height.equalTo(150)
        }
    }
}
