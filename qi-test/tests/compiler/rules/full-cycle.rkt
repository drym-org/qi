#lang racket/base

(provide tests)

(require (for-template qi/flow/core/compiler)
         ;; necessary to recognize and expand core forms correctly
         qi/flow/extended/expander
         ;; necessary to correctly expand the right-threading form
         qi/flow/extended/forms
         (for-syntax racket/base)
         rackunit
         rackunit/text-ui
         qi/flow/core/private/form-property
         (only-in "deforest.rkt" deforested?)
         "../private/expand-util.rkt"
         syntax/parse/define)

;; A macro that accepts surface syntax, expands it, and then applies the
;; indicated optimization passes.
(define-syntax-parser test-compile~>
  [(_ stx)
   #'(phase0-expand-flow stx)]
  [(_ stx pass ... passN)
   #'(passN
      (tag-form-syntax
       (test-compile~> stx pass ...)))])


(define tests

  (test-suite
   "full cycle tests"

   (test-suite
    "multiple passes"
    (test-true "normalize → deforest"
               (deforested?
                 (test-compile~> #'(~>> (filter odd?) values (map sqr))
                                 normalize-pass
                                 deforest-pass))))

   (test-suite
    "compilation sequences"
    null)))

(module+ main
  (void
   (run-tests tests)))
