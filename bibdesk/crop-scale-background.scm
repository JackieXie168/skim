;  CROP-SCALE-BACKGROUND

(define (apply-crop-scale-background img
			             drawable
			             threshold
                                     scalefactor)
  (let* ((bg-color (car (gimp-image-pick-color img drawable 0.0 0.0 FALSE FALSE 1.0)))
	 (select-bounds)
	 (has-selection)
	 (select-x1)
	 (select-y1)
	 (select-x2)
	 (select-y2)
	 (select-width)
	 (select-height)
         (scaled-width)
         (scaled-height))
    (gimp-by-color-select drawable bg-color threshold 2 TRUE FALSE 0.0 0)
    (gimp-selection-invert img)
    (set! select-bounds (gimp-selection-bounds img))
    (set! has-selection (car select-bounds))
    (set! select-x1 (cadr select-bounds))
    (set! select-y1 (caddr select-bounds))
    (set! select-x2 (cadr (cddr select-bounds)))
    (set! select-y2 (caddr (cddr select-bounds)))
    (set! select-width (- select-x2 select-x1))
    (set! select-height (- select-y2 select-y1))
    (gimp-image-crop img select-width select-height select-x1 select-y1)
    (gimp-selection-none img)
    (set! scaled-width (* select-width (/ scalefactor 100)))
    (set! scaled-height (* select-height (/ scalefactor 100)))
    (gimp-image-scale img scaled-width scaled-height)))

(define (script-fu-crop-scale-background img
				         drawable
				         threshold
                                         scalefactor)
  (begin
    (gimp-image-undo-group-start img)
    (apply-crop-scale-background img drawable threshold scalefactor)
    (gimp-image-undo-group-end img)
    (gimp-displays-flush)))


(script-fu-register "script-fu-crop-scale-background"
		    _"<Image>/Script-Fu/Utils/_Crop Background and Scale..."
		    "Crop background and scale"
		    "Christiaan Hofman"
		    "Christiaan Hofman"
		    "2005"
		    "*"
                    SF-IMAGE      "Image" 0
                    SF-DRAWABLE   "Drawable" 0
		    SF-ADJUSTMENT _"Threshold" '(0 0 255 1 10 0 0)
		    SF-ADJUSTMENT _"Scale" '(100 0 100 1 10 0 0)
		    )
