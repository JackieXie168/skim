;  BATCH-CROP-SCALE-BACKGROUND
;  run this as follows:
;  (assuming 'gimp' is aliased to the gimp executable)
;  gimp -i -b '(batch-crop-scale-background "*.png" 0 70)' '(gimp-quit 0)'

(define (batch-crop-scale-background pattern
			             threshold
                                     scalefactor)
  (let* ((filelist (cadr (file-glob pattern 1 ))))
    (while filelist
           (let* ((filename (car filelist))
                  (img (car (gimp-file-load RUN-NONINTERACTIVE filename filename)))
                  (drawable (car (gimp-image-get-active-layer img))))
              (apply-crop-scale-background img drawable threshold scalefactor)
              (gimp-file-save RUN-NONINTERACTIVE img drawable filename filename)
             (gimp-image-delete img))
           (set! filelist (cdr filelist)))))
