import UIKit
import SnapKit

class OnboardingPageVC: UIViewController {

    let titleLabel = UILabel()
    let detailLabel = UILabel()
    let imageView = UIImageView()
    let highlightedText: String
    
    private let titleFontSize: CGFloat = 32
    private let detailFontSize: CGFloat = 17
    private let horizontalInset: CGFloat = 30
    private let imageAspectRation: CGFloat = 0.8

    init(imageName: String, title: String, detail: String, highlightedText: String) {
        self.highlightedText = highlightedText
        
        super.init(nibName: nil, bundle: nil)
        
        self.imageView.image = UIImage(named: imageName)
        self.titleLabel.text = title
        self.detailLabel.text = detail
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupTitleLabel()
        setupUI()
    }
    
    private func setupTitleLabel() {
        guard let fullText = titleLabel.text else { return }
        
        let attributedString = NSMutableAttributedString(string: fullText, attributes: [
            .font: UIFont.boldSystemFont(ofSize: titleFontSize),
            .foregroundColor: UIColor.label
        ])
        
        if let range = fullText.range(of: highlightedText) {
            let nsRange = NSRange(range, in: fullText)
            attributedString.addAttributes([
                .foregroundColor: UIColor.systemBlue
            ], range: nsRange)
        }
        
        titleLabel.attributedText = attributedString
        titleLabel.numberOfLines = 2
        titleLabel.textAlignment = .center
    }
    
    private func setupUI() {
        view.addSubview(titleLabel)
        view.addSubview(detailLabel)
        view.addSubview(imageView)

        detailLabel.font = .boldSystemFont(ofSize: detailFontSize)
        detailLabel.textColor = .secondaryLabel
        detailLabel.textAlignment = .center
        detailLabel.numberOfLines = 2

        imageView.contentMode = .scaleAspectFit
        
        titleLabel.snp.makeConstraints { make in
//            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(30)
            make.leading.trailing.equalToSuperview().inset(horizontalInset)
        }
        
        detailLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(horizontalInset)
        }
        
        imageView.snp.makeConstraints { make in
            make.top.equalTo(detailLabel.snp.bottom).offset(30)
            make.leading.trailing.equalToSuperview().inset(-10)
            make.bottom.equalToSuperview()
        }
    }
}
