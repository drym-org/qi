#lang racket/base

(provide probe
         readout
         define-probed-flow
         probe-named-flow)

(require syntax/parse/define
         racket/stxparam
         (for-syntax racket/base)
         version-case
         mischief/shorthand)

(version-case
 [(version< (version) "7.9.0.22")
  (define-alias define-syntax-parse-rule define-simple-macro)])

(define-syntax-parameter readout
  (lambda (stx)
    (raise-syntax-error (syntax-e stx) "can only be used inside `probe`")))

(define-syntax-parse-rule (probe flo)
  (call/cc
   (λ (return)
     (syntax-parameterize ([readout (syntax-id-rules ()
                                      [_ return])])
       flo))))

(define-syntax-parser define-probed-flow
  [(_ (name:id arg:id ...) expr:expr)
   #'(define name
       (λ (outer)
         (syntax-parameterize ([readout (syntax-id-rules ()
                                          [_ outer])])
           (flow-lambda (arg ...)
             expr))))]
  [(_ name:id expr:expr)
   #'(define name
       (λ (outer)
         (syntax-parameterize ([readout (syntax-id-rules ()
                                          [_ outer])])
           (flow expr))))])

(define-syntax-parse-rule (probe-named-flow (flo arg ...))
  (call/cc
   (λ (outer)
     ((flo outer) arg ...))))
