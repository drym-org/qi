#lang racket/base

(provide probe
         readout)

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
