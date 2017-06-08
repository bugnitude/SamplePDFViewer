import UIKit

extension CGSize {
	
	enum RoundType {
		case none
		case down
		case up
		case off
	}
	
	func aspectFitSize(within size: CGSize, roundType: RoundType = .none) -> CGSize {
		if self.width == 0.0 || self.height == 0.0 {
			return CGSize.zero
		}
		
		let widthRatio = size.width / self.width
		let heightRatio = size.height / self.height
		let aspectFitRatio = min(widthRatio, heightRatio)
		var aspectFitSize = CGSize(width: self.width * aspectFitRatio, height: self.height * aspectFitRatio)
		
		switch roundType {
		case .down:
			aspectFitSize = CGSize(width: floor(aspectFitSize.width), height: floor(aspectFitSize.height))
		case .up:
			aspectFitSize = CGSize(width: ceil(aspectFitSize.width), height: ceil(aspectFitSize.height))
		case .off:
			aspectFitSize = CGSize(width: round(aspectFitSize.width), height: round(aspectFitSize.height))
		default:
			break
		}
		
		return aspectFitSize
	}
	
}
