#lang racket/base

(provide conjux-clause
         disjux-clause
         right-threading-clause
         blanket-template-form
         fine-template-form
         partial-application-form
         any-stx
         make-right-chiral)

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

;; Note these are used in the expander instead of in the compiler.
;; That's why they don't need the tag (i.e. they don't look for
;; #%blanket-template, #%fine-template, or #%partial-application)
(define-syntax-class blanket-template-form
  ;; "prarg" = "pre-supplied argument"
  (pattern
   (natex prarg-pre ... (~datum __) prarg-post ...)))

(define-syntax-class fine-template-form
  ;; "prarg" = "pre-supplied argument"
  (pattern
   (prarg-pre ... (~datum _) prarg-post ...)))

(define-syntax-class partial-application-form
  ;; "prarg" = "pre-supplied argument"
  (pattern
   (natex prarg ...+)))

(define-syntax-class any-stx
  (pattern _))
