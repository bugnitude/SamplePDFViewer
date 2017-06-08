import UIKit

extension UIView {
	
	func drawPDF(for page: CGPDFPage, box: CGPDFBox, rect: CGRect, alignment: PDFPageAlignment, in ctx: CGContext) {
		ctx.saveGState()
		
		let pageSize = page.size(for: box)
		let displaySize = pageSize.aspectFitSize(within: rect.size)
		var offsetX: CGFloat = rect.origin.x
		switch alignment {
		case .center:
			offsetX += (rect.width - displaySize.width) / 2.0
		case .left:
			offsetX += 0.0
		case .right:
			offsetX += rect.width - displaySize.width
		}
		let offsetY: CGFloat = rect.origin.y + (rect.height - displaySize.height) / 2.0
		ctx.translateBy(x: offsetX, y: offsetY)
		
		let scale = pageSize.width != 0.0 ? displaySize.width / pageSize.width : 1.0
		ctx.scaleBy(x: scale, y: scale)
		
		let mediaBoxRect = page.getBoxRect(.mediaBox)
		let currentBoxRect = page.getBoxRect(box)
		let boxRect = mediaBoxRect.intersection(currentBoxRect)
		
		var rotationAngle = page.rotationAngle % 360
		if rotationAngle < 0 {
			rotationAngle += 360
		}
		
		switch rotationAngle {
		case 90:
			ctx.scaleBy(x: 1.0, y: -1.0)
			ctx.rotate(by: -.pi / 2.0)
		case 180:
			ctx.scaleBy(x: 1.0, y: -1.0)
			ctx.translateBy(x: boxRect.width, y: 0.0)
			ctx.rotate(by: .pi)
		case 270:
			ctx.translateBy(x: boxRect.height, y: boxRect.width)
			ctx.rotate(by: .pi / 2.0)
			ctx.scaleBy(x: -1.0, y: 1.0)
		default:
			ctx.translateBy(x: 0.0, y: boxRect.height)
			ctx.scaleBy(x: 1.0, y: -1.0)
		}
		
		let clipRect = CGRect(origin: CGPoint.zero, size: boxRect.size)
		ctx.clip(to: clipRect)
		ctx.translateBy(x: -boxRect.origin.x, y: -boxRect.origin.y)
		
		ctx.interpolationQuality = .high
		ctx.setRenderingIntent(.defaultIntent)
		ctx.drawPDFPage(page)
		ctx.restoreGState()
	}
	
}
