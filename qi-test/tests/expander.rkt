#lang racket/base

(provide tests)

(require (for-syntax racket/base)
         syntax/macro-testing
         syntax-spec-v1
         racket/base
         qi/flow/extended/expander
         rackunit
         rackunit/text-ui)

(begin-for-syntax
  (define (expand-flow stx)
    ((nonterminal-expander closed-floe) stx)))

;; TODO: these tests compare syntax as datums, but that's not sufficient
;; since the identifiers used may be bound differently which would affect
;; e.g. literal pattern matching.
;; To do it correctly, we need an alpha-equivalence predicate for Core Qi
;; that possibly delegates to a similar predicate for any Racket
;; subexpressions. This could be a predicate that syntax-spec could
;; infer, but it's unclear at this time.
(define tests
  (test-suite
   "expander tests"

   (check-true
    (phase1-eval
     (equal? (syntax->datum
              (expand-flow #'(~> sqr add1)))
             '(thread (esc (#%host-expression sqr))
                      (esc (#%host-expression add1))))))))

(module+ main
  (void
   (run-tests tests)))
