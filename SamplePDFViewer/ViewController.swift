import UIKit

class ViewController: UIViewController {

	@IBAction func showPDF(_ sender: UIButton) {

		// Show PDF View Controller
		let fileURL = Bundle.main.url(forResource: "Sample", withExtension: "pdf")!
		if let pdfViewController = PDFViewController(fileURL: fileURL, password: nil, hasCoverPage: true, layoutMargin: PDFLayoutMargin(margin: 5.0)) {
			let navigationController = UINavigationController(rootViewController: pdfViewController)
			self.present(navigationController, animated: true, completion: nil)
		}

	}
}

