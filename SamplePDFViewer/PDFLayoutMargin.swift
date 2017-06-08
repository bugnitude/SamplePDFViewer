import UIKit

struct PDFLayoutMargin {
	
	var horizontal: CGFloat
	var vertical: CGFloat

	static var zero: PDFLayoutMargin {
		return PDFLayoutMargin(horizontal: 0.0, vertical: 0.0)
	}
	
}

extension PDFLayoutMargin {
	
	init(margin: CGFloat) {
		self.horizontal = margin
		self.vertical = margin
	}
	
}
