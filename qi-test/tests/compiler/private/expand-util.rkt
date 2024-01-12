#lang racket/base

(provide phase0-expand-flow)

(require (submod qi/flow/extended/expander invoke)
         (for-syntax racket/base)
         syntax/parse/define
         syntax/macro-testing)

;; A macro that accepts surface syntax and expands it
;; NOTE: This macro saves us the trouble of hand writing core
;; language syntax, but it also assumes that the expander is functioning
;; correctly.  If there happens to be a bug in the expander, the results
;; of a compiler test depending on this macro would be invalid and may cause
;; confusion. So it's important to ensure that the tests in
;; tests/expander.rkt are comprehensive.  Whenever we use this macro in
;; a test, it's worth verifying that there are corresponding tests in
;; tests/expander.rkt that validate the expansion for surface expressions
;; similar to the ones we are using in our test.
(define-syntax-parse-rule (phase0-expand-flow stx)
  (phase1-eval
   (expand-flow
    stx)
   #:quote syntax))
