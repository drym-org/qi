#lang racket/base

(provide conjux-clause
         disjux-clause
         right-threading-clause)

(require syntax/parse
         "../aux-syntax.rkt"
         (for-template "impl.rkt"))

(define-syntax-class conjux-clause ; "juxtaposed" conjoin
  #:attributes (parsed)
  (pattern
   (~datum _)
   #:with parsed #'true.)
  (pattern
   onex:clause
   #:with parsed #'onex))

(define-syntax-class disjux-clause ; "juxtaposed" disjoin
  #:attributes (parsed)
  (pattern
   (~datum _)
   #:with parsed #'false.)
  (pattern
   onex:clause
   #:with parsed #'onex))

(define (make-right-chiral stx)
  (syntax-property stx 'chirality 'right))

(define-syntax-class right-threading-clause
  (pattern
   onex:clause
   #:with chiral (make-right-chiral #'onex)))
