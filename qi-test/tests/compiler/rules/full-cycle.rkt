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
         racket/sandbox
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
                   #'(~>> (filter odd?) values (map sqr)))))))
   (test-suite
    "sandboxed evaluation"
    (test-not-exn "Plays well with sandboxed evaluation"
                  ;; This test reproduces the bug and the fix fixes it. Yet,
                  ;; coverage does not show the lambda in `my-emit-local-step`
                  ;; as being covered. This could be because the constructed
                  ;; sandbox evaluator "covering" the code doesn't count as
                  ;; coverage by the main evaluator running the test?
                  ;; We address this by putting `my-emit-local-step` in a
                  ;; submodule, which, by default, are ignored by coverage.
                  (lambda ()
                    (let ([eval (make-evaluator
                                 'racket/base
                                 '(require qi))])
                      (eval
                       '(~> (3) (* 2) add1))))))))

(module+ main
  (void
   (run-tests tests)))
