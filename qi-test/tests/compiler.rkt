#lang racket/base

(provide tests)

(require rackunit
         rackunit/text-ui
         (prefix-in rules: "compiler/rules.rkt")
         (prefix-in strategy: "compiler/strategy.rkt")
         (prefix-in impl: "compiler/impl.rkt"))

(define tests
  (test-suite
   "compiler tests"

   rules:tests
   strategy:tests
   impl:tests))

(module+ main
  (void
   (run-tests tests)))
