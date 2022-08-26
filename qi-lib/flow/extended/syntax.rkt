#lang racket/base

(provide conjux-clause
         disjux-clause)

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
