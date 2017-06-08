import Foundation
import UIKit
import QuartzCore

class PDFDocumentController {
	
	// MARK: - Property
	private var fileURL: URL
	private var password: String?
	private var pageBackgroundColor: UIColor
	
	private var _document: CGPDFDocument?
	private var document: CGPDFDocument? {
		if self._document != nil {
			return self._document 
		}

		// Read PDF File
		if let document = CGPDFDocument(self.fileURL as CFURL) {
			if document.isEncrypted {
				self.password?.withCString {
					_ = document.unlockWithPassword($0)
				}
			}
			
			if document.isUnlocked {
				self._document = document
				return document
			}
		}
		
		return nil
	}
	
	private(set) var numberOfPages = 0
	private let box: CGPDFBox = .cropBox
	private var viewControllerCache = [Int: PDFPageViewController]()
	
	// MARK: - Initializer
	init?(fileURL: URL, password: String?, pageBackgroundColor: UIColor) {
		self.fileURL = fileURL
		self.password = password
		self.pageBackgroundColor = pageBackgroundColor
		if let document = self.document {
			let numberOfPages = document.numberOfPages
			if numberOfPages > 0 {
				self.numberOfPages = numberOfPages
				NotificationCenter.default.addObserver(self, selector: #selector(handleMemoryWarning), name: .UIApplicationDidReceiveMemoryWarning, object: nil)
				return
			}
		}
		
		return nil
	}

	// MARK: - Deinitializer
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
	
	// MARK: - Notification Handler
	@objc func handleMemoryWarning(notification: Notification) {
		// Remove Recreatable Resources
		self._document = nil
		self.clearCache()
	}
	
	// MARK: - Page Size
	var maxPageSize: CGSize {
		var maxPageSize = CGSize.zero
		for pageNumber in 1...self.numberOfPages {
			if let page = self.document!.page(at: pageNumber) {
				let pageSize = page.size(for: self.box)
				maxPageSize.width = max(maxPageSize.width, pageSize.width)
				maxPageSize.height = max(maxPageSize.height, pageSize.height)
			}
		}
		
		return maxPageSize
	}
		
	// MARK: - Get PDF Page View Controller
	func pageViewController(at pageNumber: Int) -> PDFPageViewController? {
		// Manage Cache
		let numberOfCachesInOneDirection = 4
		let numberOfCachesInOneDirectionToCreate = numberOfCachesInOneDirection - 1
		let minCachePageNumber = pageNumber - numberOfCachesInOneDirection > 1 ? pageNumber - numberOfCachesInOneDirection : 1
		let maxCachePageNumber = pageNumber + numberOfCachesInOneDirection < self.numberOfPages ? pageNumber + numberOfCachesInOneDirection : self.numberOfPages
		var newViewControllerCache = [Int: PDFPageViewController]()
		for cache in self.viewControllerCache {
			if cache.key >= minCachePageNumber && cache.key <= maxCachePageNumber {
				newViewControllerCache[cache.key] = cache.value
			}
		}

		// Instantiate Uncached PDF Page View Controllers
		let minCachePageNumberToCreate = pageNumber - numberOfCachesInOneDirectionToCreate > 1 ? pageNumber - numberOfCachesInOneDirectionToCreate : 1
		let maxCachePageNumberToCreate = pageNumber + numberOfCachesInOneDirectionToCreate < self.numberOfPages ? pageNumber + numberOfCachesInOneDirectionToCreate : self.numberOfPages
		let pageNumbers = Array(minCachePageNumberToCreate ... maxCachePageNumberToCreate).sorted { abs($0 - pageNumber) < abs($1 - pageNumber) }
		for pageNumber in pageNumbers {
			if newViewControllerCache[pageNumber] == nil {
				newViewControllerCache[pageNumber] = PDFPageViewController(page: self.document!.page(at: pageNumber), box: self.box, backgroundColor: self.pageBackgroundColor)
			}
		}

		// Set New Cache
		self.viewControllerCache = newViewControllerCache
		
		// Return Page View Controller
		return self.viewControllerCache[pageNumber]
	}
	
	var emptyPageViewController: PDFPageViewController {
		return PDFPageViewController(page: nil, box: self.box, backgroundColor: UIColor.clear)
	}
	
	// MARK: - Clear Cache
	func clearCache() {
		self.viewControllerCache = [:]
	}

}
