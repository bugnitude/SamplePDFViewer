# Overview
This is a sample project to demonstrate how to implement a PDF viewer for iOS which supports zoom and page curl transition. 

![Screenshot](https://github.com/bugnitude/SamplePDFViewer/tree/master/README_IMAGES/Screenshot.png)

The PDF viewer of this project lets the user:

* Turn a page by tapping on the edge of the page
* Turn a page by swipe
* Zoom by pinch
* Zoom in by double tap
* Zoom out by two-finger tap
* See two facing pages on landscape orientation

The figure below shows the main relationships between the classes of the PDF viewer.

![Relations](https://github.com/bugnitude/SamplePDFViewer/tree/master/README_IMAGES/Relations.png)

## PDFViewController
PDFViewController is the main class of the PDF viewer. This view controller is the container view controller of UIPageViewController. This view controller has a scroll view (UIScrollView) to enable the zoom functionality, and the UIPageViewController's view is added to the scroll view as its subview.



## PDFPageViewController, PDFPageImageView, PDFPageDrawView

...




## PDFDocumentController
This controller manages a PDF document and caches PDFPageViewController's instances. PDFViewController gets the instances from this controller and provides them to UIPageViewController. This controller instantiates PDFPageViewController's instances for previous pages and next pages beforehand with an instance for a requested page to provide them immediately on demand.

# Installation
If you want to use the PDF viewer in your project, copy all files in the PDF Viewer group in this project to your project. See the ViewController class about the usage.

# Requirements
* Xcode 8.0 and later
* Swift 3.0 and later

# References
* [Drawing and Printing Guid for iOS - Apple](https://developer.apple.com/library/content/documentation/2DDrawing/Conceptual/DrawingPrintingiOS/GraphicsDrawingOverview/GraphicsDrawingOverview.html#//apple_ref/doc/uid/TP40010156-CH14-SW26)
* [Display a PDF page on the iPhone and iPad - iPDFdev](http://ipdfdev.com/2011/03/23/display-a-pdf-page-on-the-iphone-and-ipad/)
* [UIScrollView Tutorial: Getting Started - raywenderlich.com](https://www.raywenderlich.com/122139/uiscrollview-tutorial)