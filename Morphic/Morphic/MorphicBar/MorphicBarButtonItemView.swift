// Copyright 2020 Raising the Floor - International
//
// Licensed under the New BSD license. You may not use this file except in
// compliance with this License.
//
// You may obtain a copy of the License at
// https://github.com/GPII/universal/blob/master/LICENSE.txt
//
// The R&D leading to these results received funding from the:
// * Rehabilitation Services Administration, US Dept. of Education under
//   grant H421A150006 (APCP)
// * National Institute on Disability, Independent Living, and
//   Rehabilitation Research (NIDILRR)
// * Administration for Independent Living & Dept. of Education under grants
//   H133E080022 (RERC-IT) and H133E130028/90RE5003-01-00 (UIITA-RERC)
// * European Union's Seventh Framework Programme (FP7/2007-2013) grant
//   agreement nos. 289016 (Cloud4all) and 610510 (Prosperity4All)
// * William and Flora Hewlett Foundation
// * Ontario Ministry of Research and Innovation
// * Canadian Foundation for Innovation
// * Adobe Foundation
// * Consumer Electronics Association Foundation

import Cocoa

class MorphicBarButtonItemView: NSButton {
    
    private var titleBoxLayer: CAShapeLayer!
    private var iconCircleLayer: CAShapeLayer!
    private var iconImageLayer: CALayer!
    private var titleTextLayer: CATextLayer!

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        //
        initialize()
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        //
        initialize()
    }

    override func draw(_ dirtyRect: NSRect) {
        // NOTE: we draw a background so that macOS doesn't draw a button background (including 3D border) for us
        layer?.backgroundColor = self.backgroundColor?.cgColor ?? .clear
    }

    private func initialize() {
        // make our view a layer-based view
        self.wantsLayer = true

        // create and add each view in order (back to front)
        
        self.titleBoxLayer = CAShapeLayer()
        self.layer?.addSublayer(self.titleBoxLayer)

        self.iconCircleLayer = CAShapeLayer()
        self.layer?.addSublayer(self.iconCircleLayer)

        self.iconImageLayer = CALayer()
        self.layer?.addSublayer(self.iconImageLayer)

        self.titleTextLayer = CATextLayer()
        self.layer?.addSublayer(self.titleTextLayer)
        
        // configure each layer with default values
        configureTitleBoxLayer()
        configureIconCircleLayer()
        configureIconImageLayer()
        configureTitleTextLayer()
    }

    private func configureIconCircleLayer() {
        // calculate the diameter and bounds of the circle around our icon
        let iconCircleDiameter = calculateIconCircleDiameter()
        let iconCircleRadius = iconCircleDiameter / 2.0
        let iconCircleBounds = calculateIconCircleBounds()
        let iconCircleCenter = NSPoint(x: iconCircleBounds.midX, y: iconCircleBounds.midY)

        // sanity-check the stroke width of our icon circle
        let maxIconCircleStrokeWidth: CGFloat = iconCircleDiameter / 2.0
        let iconCircleStrokeWidthToUse = min(self.iconCircleStrokeWidth, maxIconCircleStrokeWidth)
        
        // create a new layer
        let newIconCircleLayer = CAShapeLayer()
        // and create a sublayer for the "cut out" center of the circle
        let insideCircleLayer = CAShapeLayer()
        
        // configure the layers to be drawn using the proper (e.g. Retina vs. non-Retina) scale factor
        if let backingScaleFactor = self.backingScaleFactor() {
            newIconCircleLayer.contentsScale = backingScaleFactor
            insideCircleLayer.contentsScale = backingScaleFactor
        }

        // first: draw and fill the outer circle diameter
        let outerCirclePath = CGMutablePath()
        outerCirclePath.addArc(center: iconCircleCenter, radius: iconCircleRadius, startAngle: 0.0, endAngle: 2.0 * .pi, clockwise: false)
        newIconCircleLayer.path = outerCirclePath
        newIconCircleLayer.fillColor = self.fillColor.cgColor

        // then: create the inner circle (white fill)
        let innerCirclePath = CGMutablePath()
        innerCirclePath.addArc(center: iconCircleCenter, radius: iconCircleRadius - iconCircleStrokeWidthToUse, startAngle: 0.0, endAngle: 2.0 * .pi, clockwise: false)
        insideCircleLayer.path = innerCirclePath
        insideCircleLayer.fillColor = NSColor.white.cgColor
        //
        newIconCircleLayer.addSublayer(insideCircleLayer)
        
        self.layer?.replaceSublayer(self.iconCircleLayer, with: newIconCircleLayer)
        self.iconCircleLayer = newIconCircleLayer
    }

    private func configureIconImageLayer() {
        guard let iconAsNonOptional = self.icon else {
            self.iconImageLayer.contents = nil
            return
        }
        
        // get the size of our frame
        let frameSize = self.frame.size

        // calculate the diameter of the circle around our icon
        let iconCircleDiameter = calculateIconCircleDiameter()
        
        // calculate the size of our icon
//        let iconMaxWidthAndMaxHeight: CGFloat = floor((iconCircleDiameter - 2) * 0.6) // official spec
        let iconMaxWidthAndMaxHeight: CGFloat = floor((iconCircleDiameter - 2) * 0.66) // observed behavior of Morphic for Windows

        // calculate actual width and height based on image's width to height ratio
        let pdfData = NSData(contentsOfFile: iconAsNonOptional.pathToImage)! as Data
        let pdfImageRep = NSPDFImageRep(data: pdfData)!
        let imageFrameSize = calculateImageFrameSizeForPdf(pdfBounds: pdfImageRep.bounds, maxWidth: iconMaxWidthAndMaxHeight, maxHeight: iconMaxWidthAndMaxHeight)
        
        // calculate the position of our icon
        let iconXPosition: CGFloat = (frameSize.width - imageFrameSize.width) / 2
        let iconYPosition: CGFloat = (iconCircleDiameter - imageFrameSize.height) / 2

        // create a new layer
        let newIconLayer = CAShapeLayer()

        // configure the layer to be drawn using the proper (e.g. Retina vs. non-Retina) scale factor
        if let backingScaleFactor = self.backingScaleFactor() {
            newIconLayer.contentsScale = backingScaleFactor
        }

        // frame
        newIconLayer.frame = NSRect(x: iconXPosition, y: iconYPosition, width: imageFrameSize.width, height: imageFrameSize.height)
        // background
        newIconLayer.backgroundColor = .clear
        // contents
        
        let nsImage = NSImage(size: NSSize(width: imageFrameSize.width, height: imageFrameSize.height), flipped: false) { (imageRect) -> Bool in
            pdfImageRep.draw(in: imageRect)
            return true
        }
        let recoloredNsImage = colorImage(nsImage, withColor: self.iconColor ?? self.fillColor)
        newIconLayer.contents = recoloredNsImage
        
        self.layer?.replaceSublayer(self.iconImageLayer, with: newIconLayer)
        self.iconImageLayer = newIconLayer
    }
    
    private func configureTitleBoxLayer() {
        // calculate the size of our title's background rounded rectangle box
        let titleBoxBounds: CGRect = calculateTitleBoxBounds()

        // create a new layer
        let newTitleBoxLayer = CAShapeLayer()
        
        // configure the layer to be drawn using the proper (e.g. Retina vs. non-Retina) scale factor
        if let backingScaleFactor = self.backingScaleFactor() {
            newTitleBoxLayer.contentsScale = backingScaleFactor
        }

        // sanity check our titlebox corner radius
        let maxTitleBoxCornerRadius: CGFloat = min(titleBoxBounds.width, titleBoxBounds.height) / 2.0
        
        // first: draw the rounded rectangle box behind our title
        let titleBoxPath = CGMutablePath()
        titleBoxPath.addRoundedRect(in: titleBoxBounds, cornerWidth: min(self.roundedRectangeCornerRadius, maxTitleBoxCornerRadius), cornerHeight: min(self.roundedRectangeCornerRadius, maxTitleBoxCornerRadius))
        newTitleBoxLayer.path = titleBoxPath
        newTitleBoxLayer.fillColor = self.fillColor.cgColor
        
        self.layer?.replaceSublayer(self.titleBoxLayer, with: newTitleBoxLayer)
        self.titleBoxLayer = newTitleBoxLayer
    }

    private func configureTitleTextLayer() {
        guard let titleFont = self.font else {
            return
        }
        
        // get size of our title (using its attributed font attributes)
        let titleTextSize = calculateTitleTextSize()

        // calculate the bounds of our title text
        let titleTextBounds = calculateTitleTextBounds()
        
        // create a new layer
        let newTitleTextLayer = CATextLayer()

        // configure the layer to be drawn using the proper (e.g. Retina vs. non-Retina) scale factor
        if let backingScaleFactor = self.backingScaleFactor() {
            newTitleTextLayer.contentsScale = backingScaleFactor
        }

        // frame
        newTitleTextLayer.frame = NSRect(x: titleTextBounds.minX, y: titleTextBounds.minY, width: titleTextSize.width, height: titleTextSize.height)
        // font properties
        newTitleTextLayer.font = titleFont
        newTitleTextLayer.fontSize = titleFont.pointSize
        newTitleTextLayer.foregroundColor = .white
        //
        // title string
        newTitleTextLayer.string = self.title
        
        self.layer?.replaceSublayer(self.titleTextLayer, with: newTitleTextLayer)
        self.titleTextLayer = newTitleTextLayer
    }
    
    // MARK: B&W image recoloring
    
    private func colorImage(_ image: NSImage, withColor tintColor: NSColor) -> NSImage? {
        // calculate the bounds of our image
        let imageBounds = NSRect(origin: .zero, size: image.size)

        // create an opaque copy of the provided tint color; we will lower the opacity of our image to preserve the color opacity
        let opaqueTintColor = tintColor.withAlphaComponent(1)

        // create a copy of the original image (but at the alpha level specified by our color)
        // NOTE: we create the image copy at the alpha level of our tint color so that we can then flood it with a color with 100% opacity
        //
        // first create the empty image
        let copyOfImage = NSImage(size: image.size)
        let copyOfImageBounds = NSRect(origin: .zero, size: copyOfImage.size)
        //
        // prepare our new image to receive drawing commands
        copyOfImage.lockFocus()
        //
        // draw a copy of our image (at the alpha level of our tintColor) into the new image
        image.draw(in: copyOfImageBounds, from: imageBounds, operation: .sourceOver, fraction: tintColor.alphaComponent)

        // choose the provided tintColor (but using 100% opacity) to tint our image
        opaqueTintColor.set()
        // tint (recolor) our image
        copyOfImageBounds.fill(using: .sourceAtop)

        // remove the focus from our image (as we are done drawing)
        copyOfImage.unlockFocus()

        return copyOfImage
    }
    
    // MARK: size/position calculations
    
    // NOTE: if this function is called without an explicit frame width, the view's current frame width is used
    private func calculateIconCircleDiameter(usingFrameWidth customFrameWidth: CGFloat? = nil) -> CGFloat {
        // get the size of our frame
        let frameSize = self.frame.size
        
        let frameWidthForCalculation = customFrameWidth ?? frameSize.width
        
        // calculate the size of the circle around our icon
        let circleDiameter = floor(frameWidthForCalculation * (2.0/3))
        
        return circleDiameter
    }
    
    private func calculateIconCircleBounds() -> NSRect {
        // get the size of our frame
        let frameSize = self.frame.size

        let iconCircleDiameter = calculateIconCircleDiameter()

        let iconCircleXPosition: CGFloat = (frameSize.width - iconCircleDiameter) / 2.0
        let iconCircleYPosition: CGFloat = 0.0

        let iconCircleBounds = NSRect(x: iconCircleXPosition, y: iconCircleYPosition, width: iconCircleDiameter, height: iconCircleDiameter)
        
        return iconCircleBounds
    }

    private func calculateTitleBoxSize() -> NSSize {
        // get the size of our frame
        let frameSize = self.frame.size

        let iconCircleDiameter = calculateIconCircleDiameter()
        
        // NOTE: 2/3 of the circle is above the box; the remainder of the circle is inside the box
        let titleBoxSize = NSSize(width: frameSize.width, height: frameSize.height - (iconCircleDiameter * 2.0/3))
        
        return titleBoxSize
    }
    
    private func calculateTitleBoxBounds() -> NSRect {
        // get the size of our frame
        let frameSize = self.frame.size

        // calculate the size of our title's background rounded rectangle box
        let titleBoxSize = calculateTitleBoxSize()
        let titleBoxBounds = NSRect(x: 0.0, y: frameSize.height - titleBoxSize.height, width: titleBoxSize.width, height: titleBoxSize.height)

        return titleBoxBounds
    }
    
    // NOTE: this function returns a fixed value based on the title (and not on the current size of the frame)
    private func calculateTitleTextSize() -> NSSize {
        // get size of our title (using its attributed font attributes)
        let titleAsNSString = self.title as NSString
        let titleTextSize = titleAsNSString.size(withAttributes: [ NSAttributedString.Key.font: self.font as Any ])
        
        return titleTextSize
    }
    
    private func calculateTitleTextBounds() -> NSRect {
        // get the size of our frame
        let frameSize = self.frame.size

        let titleBoxBounds = calculateTitleBoxBounds()
        
        let titleTextSize = calculateTitleTextSize()
        //
        let titleTextPosX = (frameSize.width - titleTextSize.width) / 2.0
        let titleTextPosY = titleBoxBounds.maxY - titleTextSize.height - self.titleBottomPadding
        
        let titleTextBounds = NSRect(x: titleTextPosX, y: titleTextPosY, width: titleTextSize.width, height: titleTextSize.height)
        
        return titleTextBounds
    }
    
    private func calculateImageFrameSizeForPdf(pdfBounds: NSRect, maxWidth: CGFloat, maxHeight: CGFloat) -> NSSize {
        var width: CGFloat = 0
        var height: CGFloat = 0
        
        if pdfBounds.width > pdfBounds.height {
            width = maxWidth
            height = maxHeight * (pdfBounds.height / pdfBounds.width)
        } else {
            height = maxHeight
            width = maxWidth * (pdfBounds.width / pdfBounds.height)
        }
        
        // if one of our values still doesn't fit (i.e. because we're not using a square box), scale even smaller
        if width > maxWidth {
            let shrinkRatio = maxWidth / width
            width = width * shrinkRatio
            height = height * shrinkRatio
        }
        if height > maxHeight {
            let shrinkRatio = maxHeight / height
            width = width * shrinkRatio
            height = height * shrinkRatio
        }
        
        return NSSize(width: width, height: height)
    }
    
    // MARK: self-sizing hints to layout engine
    
    override var intrinsicContentSize: NSSize {
        get {
            let width: CGFloat = 100
            
            var height: CGFloat = 0
            //
            let titleTextSize = calculateTitleTextSize()
            height += titleTextSize.height
            //
            height += self.titleBottomPadding
            //
            height += self.titleTopPadding
            //
            let iconCircleDiameter = calculateIconCircleDiameter(usingFrameWidth: width)
            height += iconCircleDiameter
            
            return NSSize(width: width, height: height)
        }
    }
    
    // MARK: utils
    
    private func backingScaleFactor() -> CGFloat? {
        // select the current window's scale factor (e.g. Retina vs. non-Retina); as a backup use the "single-monitor" scale factor
        if let backingScaleFactor = window?.backingScaleFactor {
            return backingScaleFactor
        } else if let backingScaleFactor = NSScreen.main?.backingScaleFactor {
            return backingScaleFactor
        }
        
        return nil
    }
    
    // MARK: properties
    
    public var backgroundColor: NSColor? = nil {
        didSet {
            self.needsDisplay = true
        }
    }
    
    public var fillColor: NSColor = NSColor(red: 0/255.0, green: 41/255.0, blue: 87/255.0, alpha: 1.0) {
        didSet {
            configureTitleBoxLayer()
            configureIconCircleLayer()
            if iconColor == nil {
                configureIconImageLayer()
            }
        }
    }
    
    override var font: NSFont? {
        didSet {
            configureTitleTextLayer()
        }
    }

    public var icon: MorphicBarButtonItemIcon? {
        didSet {
            configureIconImageLayer()
        }
    }
    
    public var iconColor: NSColor? {
        didSet {
            configureIconImageLayer()
        }
    }
    
    public var iconCircleStrokeWidth: CGFloat = 2.0 {
        didSet {
            configureIconCircleLayer()
        }
    }
    
    public var roundedRectangeCornerRadius: CGFloat = 10.0 {
        didSet {
            configureTitleBoxLayer()
            self.needsLayout = true
        }
    }

    override var title: String {
        didSet {
            configureTitleTextLayer()
        }
    }
    
    public var titleBottomPadding: CGFloat = 10.0 {
        didSet {
            configureTitleBoxLayer()
            configureTitleTextLayer()
            self.needsLayout = true
        }
    }

    public var titleTopPadding: CGFloat = 3.0 {
        didSet {
            configureTitleBoxLayer()
            configureTitleTextLayer()
            self.needsLayout = true
        }
    }
}