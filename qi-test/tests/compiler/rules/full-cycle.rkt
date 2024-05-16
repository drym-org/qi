#lang racket/base

(provide tests)

(require (for-syntax racket/base)
         ;; necessary to recognize and expand core forms correctly
         qi/flow/extended/expander
         ;; necessary to correctly expand the right-threading form
         qi/flow/extended/forms
         rackunit
         rackunit/text-ui
         syntax/macro-testing
         qi/flow/core/deforest
         qi/flow/core/compiler
         "private/deforest-util.rkt"
         (submod qi/flow/extended/expander invoke))

(begin-for-syntax
  (require syntax/parse/define
           (for-template qi/flow/core/compiler)
           (for-syntax racket/base))

  ;; A macro that accepts surface syntax, expands it, and then applies the
  ;; indicated optimization passes.
  (define-syntax-parser test-passes~>
    [(_ stx)
     #'(expand-flow stx)]
    [(_ stx pass ... passN)
     #'(passN
        (test-passes~> stx pass ...))])

  ;; A macro that expands and compiles surface syntax
  (define-syntax-parse-rule (qi-compile stx)
    (compile-flow
     (expand-flow stx))))


(define tests

  (test-suite
   "full cycle tests"

   (test-suite
    "multiple passes"
    (test-true "normalize → deforest"
               (deforested?
                 (phase1-eval
                  (qi-compile
                   #'(~>> (filter odd?) values (map sqr)))))))))

(module+ main
  (void
   (run-tests tests)))
