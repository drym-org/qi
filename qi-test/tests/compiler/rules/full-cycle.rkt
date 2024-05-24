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
         qi/flow/core/compiler
         qi/flow/core/compiler/0100-deforest
         "private/deforest-util.rkt"
         (submod qi/flow/extended/expander invoke))

(begin-for-syntax
  ;; A function that expands and compiles surface syntax
  (define (qi-compile stx)
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
