#lang racket/base

(provide tests)

(require rackunit
         rackunit/text-ui
         (prefix-in normalize: "rules/normalize.rkt")
         (prefix-in inline: "rules/inlining.rkt")
         (prefix-in deforest: "rules/deforest.rkt")
         (prefix-in full-cycle: "rules/full-cycle.rkt"))


(define tests

  (test-suite
   "Compiler rule tests"

   normalize:tests
   inline:tests
   deforest:tests
   full-cycle:tests))

(module+ main
  (void
   (run-tests tests)))
