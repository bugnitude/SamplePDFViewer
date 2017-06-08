import UIKit

class PDFPageImageView: UIView {
	
	// MARK: - Property
	private var page: CGPDFPage?
	private var box = CGPDFBox.cropBox
	
	var alignment: PDFPageAlignment = .center {
		didSet {
			self.setNeedsLayout()
		}
	}
	
	var fillColor = UIColor.white {
		didSet {
			self.imageView.backgroundColor = self.fillColor
		}
	}

	private weak var imageView: UIImageView!
	private var imageViewConstraints = [NSLayoutConstraint]()
	
	// MARK: - Initializer
	convenience init(page: CGPDFPage?, box: CGPDFBox, size: CGSize) {
		self.init()
		
		// Set Properties
		self.page = page
		self.box = box
		self.backgroundColor = UIColor.clear
		self.isUserInteractionEnabled = false
		
		// Setup Image View
		let imageView = UIImageView()
		imageView.backgroundColor = self.fillColor
		imageView.contentMode = .scaleToFill
		imageView.translatesAutoresizingMaskIntoConstraints = false
		self.addSubview(imageView)
		self.imageView = imageView

		// Generate Image
		self.generateImage(size: size)
	}
	
	private override init(frame: CGRect) {
		super.init(frame: frame)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	// MARK: - Layout
	override func layoutSubviews() {
		super.layoutSubviews()
		
		guard let image = self.imageView.image else {
			return
		}
		
		// Update Image View Constraints
		NSLayoutConstraint.deactivate(self.imageViewConstraints)
		var constraints = [NSLayoutConstraint]()
		let displaySize = image.size.aspectFitSize(within: self.frame.size)
		switch self.alignment {
		case .center:
			constraints.append(NSLayoutConstraint(item: self, attribute: .centerX, relatedBy: .equal, toItem: self.imageView, attribute: .centerX, multiplier: 1.0, constant: 0.0))
		case .left:
			constraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|[view]", options: [], metrics: nil, views: ["view": self.imageView]))
		case .right:
			constraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:[view]|", options: [], metrics: nil, views: ["view": self.imageView]))
		}
		constraints.append(NSLayoutConstraint(item: self, attribute: .centerY, relatedBy: .equal, toItem: self.imageView, attribute: .centerY, multiplier: 1.0, constant: 0.0))
		constraints.append(NSLayoutConstraint(item: self.imageView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: displaySize.width))
		constraints.append(NSLayoutConstraint(item: self.imageView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: displaySize.height))
		NSLayoutConstraint.activate(constraints)
		self.imageViewConstraints = constraints
	}
	
	// MARK: - Generate Image
	private func generateImage(size: CGSize) {
		if size.width == 0.0 || size.height == 0.0 {
			return
		}
		
		guard let page = self.page else {
			return
		}
		
		// Generate Image on Concurrent Queue
		let pageSize = page.size(for: self.box)
		let imageSize = pageSize.aspectFitSize(within: size)
		let imageRect = CGRect(origin: CGPoint.zero, size: imageSize)
		let queue = DispatchQueue(label: "Image Generation Queue for Page: \(page.pageNumber)", attributes: .concurrent)
		queue.async {
			UIGraphicsBeginImageContextWithOptions(imageSize, false, 0.0)
			let ctx = UIGraphicsGetCurrentContext()!
			self.drawPDF(for: page, box: self.box, rect: imageRect, alignment: .left, in: ctx)
			let image = UIGraphicsGetImageFromCurrentImageContext()
			UIGraphicsEndImageContext()
			
			DispatchQueue.main.async { [weak self] in
				self?.imageView.image = image
				self?.setNeedsLayout()
			}
		}
	}

}
