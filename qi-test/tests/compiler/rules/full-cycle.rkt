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
                    (let ([eval (parameterize ([sandbox-output 'string]
                                               [sandbox-error-output 'string]
                                               [sandbox-memory-limit #f])
                                  (make-evaluator
                                   'racket/base
                                   '(require (for-syntax racket/base)
                                             ;; necessary to recognize and expand core forms correctly
                                             qi/flow/extended/expander
                                             ;; necessary to correctly expand the right-threading form
                                             qi/flow/extended/forms
                                             syntax/macro-testing
                                             racket/list
                                             qi/flow/core/compiler
                                             (submod qi/flow/extended/expander invoke))

                                   '(begin-for-syntax
                                      (require syntax/parse/define
                                               (for-template qi/flow/core/compiler)
                                               (for-syntax racket/base))

                                      ;; A macro that expands and compiles surface syntax
                                      (define-syntax-parse-rule (qi-compile stx)
                                        (compile-flow
                                         (expand-flow stx))))))])
                      (eval
                       '(phase1-eval
                         (qi-compile
                          #'sqr)))))))))

(module+ main
  (void
   (run-tests tests)))
