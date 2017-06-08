import UIKit

class PDFViewController: UIViewController, UIPageViewControllerDelegate, UIPageViewControllerDataSource, UIScrollViewDelegate {

	// MARK: - Property
	private var pdfDocumentController: PDFDocumentController!
	private var hasCoverPage = false
	private var layoutMargin = PDFLayoutMargin.zero
	private var backgroundColor = UIColor.lightGray

	private weak var scrollView: UIScrollView!
	private weak var pageViewController: UIPageViewController!
	private weak var pageViewWidthConstraint: NSLayoutConstraint!
	private weak var pageViewHeightConstraint: NSLayoutConstraint!
	private weak var pageViewLeadingConstraint: NSLayoutConstraint!
	private weak var pageViewTrailingConstraint: NSLayoutConstraint!
	private weak var pageViewTopConstraint: NSLayoutConstraint!
	private weak var pageViewBottomConstraint: NSLayoutConstraint!

	private var isTransitioning = false

	private let zoomFactor: CGFloat = 2.0
	
	// MARK: - Initializer
	convenience init?(fileURL: URL, password: String? = nil, hasCoverPage: Bool = false, layoutMargin: PDFLayoutMargin = PDFLayoutMargin.zero, backgroundColor: UIColor = UIColor.lightGray, pageBackgroundColor: UIColor = UIColor.white) {
		if let pdfDocumentController = PDFDocumentController(fileURL: fileURL, password: password, pageBackgroundColor: pageBackgroundColor) {
			self.init(nibName: nil, bundle: nil)
			self.pdfDocumentController = pdfDocumentController
			self.hasCoverPage = hasCoverPage
			self.layoutMargin = layoutMargin
			self.backgroundColor = backgroundColor
		}
		else {
			return nil
		}
	}
	
	// MARK: -
	private override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
		super.init(nibName: nil, bundle: nil)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	// MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
		
		// Disable Auto Adjustment
		self.automaticallyAdjustsScrollViewInsets = false
		
		// Setup Scroll View
		let scrollView = UIScrollView()
		scrollView.backgroundColor = self.backgroundColor
		scrollView.zoomScale = 1.0
		scrollView.minimumZoomScale = 1.0
		scrollView.maximumZoomScale = 8.0
		scrollView.decelerationRate = UIScrollViewDecelerationRateFast
		scrollView.translatesAutoresizingMaskIntoConstraints = false
		self.view.addSubview(scrollView)
		var constraintsForScrollView = [NSLayoutConstraint]()
		constraintsForScrollView.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|[view]|", options: [], metrics: nil, views: ["view": scrollView]))
		constraintsForScrollView.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|", options: [], metrics: nil, views: ["view": scrollView]))
		NSLayoutConstraint.activate(constraintsForScrollView)
		self.scrollView = scrollView
		
		// Get Initial View Controllers
		var viewControllers = [PDFPageViewController]()
		let firstPageViewController = self.pdfDocumentController.pageViewController(at: 1)!
		if UIApplication.shared.statusBarOrientation.isLandscape && self.pdfDocumentController.numberOfPages != 1 {
			if self.hasCoverPage {
				viewControllers = [self.pdfDocumentController.emptyPageViewController]
			}
			else {
				viewControllers = [firstPageViewController]
			}
		}
		else {
			viewControllers = [firstPageViewController]
		}

		// Setup Page View Controller
		let pageViewController = UIPageViewController(transitionStyle: .pageCurl, navigationOrientation: .horizontal, options: nil)
		pageViewController.setViewControllers(viewControllers, direction: .forward, animated: false, completion: nil)
		pageViewController.dataSource = self
		pageViewController.delegate = self
		pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
		self.addChildViewController(pageViewController)
		self.scrollView.addSubview(pageViewController.view)
		pageViewController.didMove(toParentViewController: self)
		self.pageViewController = pageViewController
		
		// Set Constraints to Page View Controller
		let view = pageViewController.view!
		let pageViewWidthConstraint = NSLayoutConstraint(item: view, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: self.view.frame.width)
		let pageViewHeightConstraint = NSLayoutConstraint(item: view, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: self.view.frame.height)
		let pageViewLeadingConstraint = NSLayoutConstraint(item: view, attribute: .leading, relatedBy: .equal, toItem: scrollView, attribute: .leading, multiplier: 1.0, constant: 0.0)
		let pageViewTrailingConstraint = NSLayoutConstraint(item: view, attribute: .trailing, relatedBy: .equal, toItem: scrollView, attribute: .trailing, multiplier: 1.0, constant: 0.0)
		let pageViewTopConstraint = NSLayoutConstraint(item: view, attribute: .top, relatedBy: .equal, toItem: scrollView, attribute: .top, multiplier: 1.0, constant: 0.0)
		let pageViewBottomConstraint = NSLayoutConstraint(item: view, attribute: .bottom, relatedBy: .equal, toItem: scrollView, attribute: .bottom, multiplier: 1.0, constant: 0.0)
		NSLayoutConstraint.activate([pageViewWidthConstraint, pageViewHeightConstraint, pageViewLeadingConstraint, pageViewTrailingConstraint, pageViewTopConstraint, pageViewBottomConstraint])
		self.pageViewWidthConstraint = pageViewWidthConstraint
		self.pageViewHeightConstraint = pageViewHeightConstraint
		self.pageViewLeadingConstraint = pageViewLeadingConstraint
		self.pageViewTrailingConstraint = pageViewTrailingConstraint
		self.pageViewTopConstraint = pageViewTopConstraint
		self.pageViewBottomConstraint = pageViewBottomConstraint
		
		// Set Delegate to Scroll View
		self.scrollView.delegate = self
	
		// Add Gesture Recognizer to Hide or Show Navigation Bar
		let navigationBarGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleOneFingerSingleTap))
		navigationBarGestureRecognizer.numberOfTouchesRequired = 1
		navigationBarGestureRecognizer.numberOfTapsRequired = 1
		self.view.addGestureRecognizer(navigationBarGestureRecognizer)
		
		// Add Gesture Recognizer to Zoom-in
		let zoomInGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleOneFingerDoubleTap))
		zoomInGestureRecognizer.numberOfTouchesRequired = 1
		zoomInGestureRecognizer.numberOfTapsRequired = 2
		self.view.addGestureRecognizer(zoomInGestureRecognizer)
		
		// Add Gesture Recognizer to Zoom-out
		let zoomOutGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTwoFingerSingleTap))
		zoomOutGestureRecognizer.numberOfTouchesRequired = 2
		zoomOutGestureRecognizer.numberOfTapsRequired = 1
		self.view.addGestureRecognizer(zoomOutGestureRecognizer)
		
		// Add Dependency to Gesture Recognizers
		self.pageViewController.gestureRecognizers.forEach { zoomInGestureRecognizer.require(toFail: $0) }
		self.pageViewController.gestureRecognizers.forEach { navigationBarGestureRecognizer.require(toFail: $0) }
		navigationBarGestureRecognizer.require(toFail: zoomInGestureRecognizer)
		
		// Add Bar Buttom Item to Close
		let doneButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(close))
		self.navigationItem.leftBarButtonItem = doneButtonItem
    }
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		// Update
		self.resetSize()
		self.updateMargin()
	}
	
	// MARK: - Layout
	private func resetSize() {
		// Get Max Page Size
		var maxPageSize = self.pdfDocumentController.maxPageSize
		if self.pageViewController.viewControllers?.count == 2 {
			maxPageSize.width *= 2.0
		}
		
		// Set Size Constraints
		var viewSize = self.view.frame.size
		viewSize.width -= self.layoutMargin.horizontal * 2.0
		viewSize.height -= self.layoutMargin.vertical * 2.0
		let aspectFitSize = maxPageSize.aspectFitSize(within: viewSize)
		self.pageViewWidthConstraint.constant = aspectFitSize.width
		self.pageViewHeightConstraint.constant = aspectFitSize.height

		// Reset Zoom Scale
		self.scrollView.zoomScale = 1.0
		
		// Enable Gesture Recognizers of Page View Controller
		self.pageViewController.gestureRecognizers.forEach{ $0.isEnabled = true }
		
		// Upadte Layout
		self.view.layoutIfNeeded()
	}
	
	private func updateMargin() {
		let xOffset = max(0, (self.view.frame.width - self.pageViewController.view.frame.width) / 2.0)
		self.pageViewLeadingConstraint.constant = xOffset
		self.pageViewTrailingConstraint.constant = xOffset
		
		let yOffset = max(0, (self.view.frame.height - self.pageViewController.view.frame.height) / 2.0) 
	  	self.pageViewTopConstraint.constant = yOffset
	  	self.pageViewBottomConstraint.constant = yOffset
			
	  	self.view.layoutIfNeeded()
	}
	
	// MARK: - Action
	func close(sender: UIBarButtonItem) {
		self.dismiss(animated: true, completion: nil)
	}
	
	// MARK: - Gesture Recognizer
	func handleOneFingerSingleTap(sender: UIGestureRecognizer) {
		// Hide or Show Navigation Controller
		if sender.state == .ended {
			if let navigationController = self.navigationController {
				navigationController.setNavigationBarHidden(!navigationController.isNavigationBarHidden, animated: true)
			}
		}
	}
	
	func handleOneFingerDoubleTap(sender: UIGestureRecognizer) {
		// Zoom-in & Hide Navigation Bar
		if sender.state == .ended {
			var zoomInScale = self.scrollView.zoomScale * self.zoomFactor
			if zoomInScale > self.scrollView.maximumZoomScale {
				zoomInScale = self.scrollView.maximumZoomScale
			}
			
			self.scrollView.setZoomScale(zoomInScale, animated: true)
			self.hideNavigationBarIfRequired()
		}
	}
	
	func handleTwoFingerSingleTap(sender: UIGestureRecognizer) {
		// Zoom-out & Hide Navigation Bar
		if sender.state == .ended {
			var zoomOutScale = self.scrollView.zoomScale / self.zoomFactor
			if zoomOutScale < self.scrollView.minimumZoomScale {
				zoomOutScale = self.scrollView.minimumZoomScale
			}
			
			self.scrollView.setZoomScale(zoomOutScale, animated: true)
			self.hideNavigationBarIfRequired()
		}
	}
	
	// MARK: - Utility
	private func hideNavigationBarIfRequired() {
		if let navigationController = self.navigationController {
			if !navigationController.isNavigationBarHidden {
				navigationController.setNavigationBarHidden(true, animated: true)
			}
		}
	}
	
	// MARK: - Scroll View Delegate
	func viewForZooming(in scrollView: UIScrollView) -> UIView? {
		return self.pageViewController.view
	}
	
	func scrollViewDidZoom(_ scrollView: UIScrollView) {
		// Upadte Margin
		self.updateMargin()
		
		// Enable or Disable Gesture Recognizers of Page View Controller
		let isEnabled = scrollView.zoomScale == 1.0
		self.pageViewController.gestureRecognizers.forEach{ $0.isEnabled = isEnabled }
	}
	
	// MARK: - Page View Controller Data Source
	func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
		// In Transition
		if self.isTransitioning {
			return nil
		}
		
		// Return Previous PDF Page View Controller
		if let pageNumber = (viewController as! PDFPageViewController).pageNumber {
			if let previousViewController = self.pdfDocumentController.pageViewController(at: pageNumber - 1) {
				previousViewController.alignment = .center
				if pageViewController.viewControllers?.count == 2 {
					if (self.hasCoverPage && pageNumber % 2 == 0) || (!self.hasCoverPage && pageNumber % 2 == 1)  {
						previousViewController.alignment = .left
					}
					else {
						previousViewController.alignment = .right
					}
				}
				return previousViewController
			}
			else if pageViewController.viewControllers?.count == 2 {
				if self.hasCoverPage && pageNumber == 1 {
					return self.pdfDocumentController.emptyPageViewController
				}
			}
		}
		
		return nil
	}
	
	func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
		// In Transition
		if self.isTransitioning {
			return nil
		}
		
		// Return Next PDF Page View Controller
		if let pageNumber = (viewController as! PDFPageViewController).pageNumber {
			if let nextViewController = self.pdfDocumentController.pageViewController(at: pageNumber + 1) {
				nextViewController.alignment = .center
				if pageViewController.viewControllers?.count == 2 {
					if (self.hasCoverPage && pageNumber % 2 == 0) || (!self.hasCoverPage && pageNumber % 2 == 1)  {
						nextViewController.alignment = .left
					}
					else {
						nextViewController.alignment = .right
					}
				}
				return nextViewController
			}
			else if pageViewController.viewControllers?.count == 2 {
				if (self.hasCoverPage && pageNumber % 2 == 0) || (!self.hasCoverPage && pageNumber % 2 == 1) {
					return self.pdfDocumentController.emptyPageViewController
				}
			}
		}
		
		return nil
	}
	
	// MARK: - Page View Controller Delegate
	func pageViewController(_ pageViewController: UIPageViewController, spineLocationFor orientation: UIInterfaceOrientation) -> UIPageViewControllerSpineLocation {
		// Reset Flag
		self.isTransitioning = false
		
		// Clear Cache
		// --- To handle UIPageViewController's bug
		if orientation != UIApplication.shared.statusBarOrientation {
			self.pdfDocumentController.clearCache()
		}
		
		// Get Current View Controller
		let pageNumber = (self.pageViewController.viewControllers?.first as? PDFPageViewController)?.pageNumber ?? 1
		let currentViewController = self.pdfDocumentController.pageViewController(at: pageNumber)!
		currentViewController.alignment = .center
		
		// Single Page
		if self.pdfDocumentController.numberOfPages == 1 {
			let viewControllers = [currentViewController]
			self.pageViewController.setViewControllers(viewControllers, direction: .forward, animated: false, completion: nil)
			return .min
		}
		
		// Portrait
		if orientation == .portrait {// || UIDevice.current.userInterfaceIdiom == .phone {
			let viewControllers = [currentViewController]
			self.pageViewController.setViewControllers(viewControllers, direction: .forward, animated: false, completion: nil)
			self.pageViewController.isDoubleSided = false
			return .min
		}
		
		// Landscape
		var viewControllers = [UIViewController]()
		if self.hasCoverPage {
			if pageNumber % 2 == 1 {
				currentViewController.alignment = .left
				if let previousViewController = self.pdfDocumentController.pageViewController(at: pageNumber - 1) {
					previousViewController.alignment = .right
					viewControllers = [previousViewController, currentViewController]
				}
				else {
					viewControllers = [self.pdfDocumentController.emptyPageViewController, currentViewController]
				}
			}
			else {
				currentViewController.alignment = .right
				if let nextViewController = self.pdfDocumentController.pageViewController(at: pageNumber + 1) {
					nextViewController.alignment = .left
					viewControllers = [currentViewController, nextViewController]
				}
				else {
					viewControllers = [currentViewController, self.pdfDocumentController.emptyPageViewController]
				}
			}
		}
		else {
			if pageNumber % 2 == 0 {
				currentViewController.alignment = .left
				let previousViewController = self.pdfDocumentController.pageViewController(at: pageNumber - 1)!
				previousViewController.alignment = .right
				viewControllers = [previousViewController, currentViewController]
			}
			else {
				currentViewController.alignment = .right
				if let nextViewController = self.pdfDocumentController.pageViewController(at: pageNumber + 1) {
					nextViewController.alignment = .left
					viewControllers = [currentViewController, nextViewController]
				}
				else {
					viewControllers = [currentViewController, self.pdfDocumentController.emptyPageViewController]
				}
			}
		}
		self.pageViewController.setViewControllers(viewControllers, direction: .forward, animated: false, completion: nil)
		return .mid
	}
	
	func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
		// Hide Navigation Bar
		self.hideNavigationBarIfRequired()
		
		// Set Flag
		self.isTransitioning = true
	}
	
	func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
		// Set Flag
		self.isTransitioning = false
	}
	
}
