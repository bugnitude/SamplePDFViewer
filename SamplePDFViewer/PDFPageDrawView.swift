import UIKit

class PDFPageDrawView: UIView {
	
	// MARK: - Property
	private var page: CGPDFPage?
	private var box = CGPDFBox.cropBox
	
	var alignment: PDFPageAlignment = .center {
		didSet {
			self.setNeedsDisplay()
		}
	}
	
	var fillColor = UIColor.white {
		didSet {
			self.setNeedsDisplay()
		}
	}
	
	// MARK: - Layer
	class CustomLayer: CATiledLayer {
		override class func fadeDuration() -> CFTimeInterval {
			return 0.0
		}
	}
	
	override class var layerClass: AnyClass {
		return CustomLayer.self
	}
	
	// MARK: - Initializer
	convenience init(page: CGPDFPage?, box: CGPDFBox) {
		self.init()
		
		// Set Properties
		self.page = page
		self.box = box
		self.backgroundColor = UIColor.clear
		self.isUserInteractionEnabled = false
		self.contentMode = .redraw

		// Setup Layer
		let tiledLayer = self.layer as! CATiledLayer
		tiledLayer.levelsOfDetail = 4
		tiledLayer.levelsOfDetailBias = 3
		tiledLayer.tileSize = CGSize(width: 512.0, height: 512.0)
	}
	
	private override init(frame: CGRect) {
		super.init(frame: frame)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: - Deinitializer
	deinit {
		self.layer.delegate = nil
		self.layer.removeFromSuperlayer()
	}
	
	// MARK: - Draw
	override func draw(_ layer: CALayer, in ctx: CGContext) {
		guard let page = self.page else {
			return
		}
		
		// Draw only when zoomed-in
		if ctx.ctm.a != self.contentScaleFactor {
			// Fill Background
			ctx.setFillColor(self.fillColor.cgColor)
			ctx.fill(layer.bounds)
			
			// Draw PDF Page
			self.drawPDF(for: page, box: self.box, rect: layer.bounds, alignment: self.alignment, in: ctx)
		}
	}
	
}
