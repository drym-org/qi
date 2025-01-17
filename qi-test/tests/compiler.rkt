#lang racket/base

(provide tests)

(require rackunit
         rackunit/text-ui
         (prefix-in rules: "compiler/rules.rkt")
         (prefix-in strategy: "compiler/strategy.rkt")
         (prefix-in runtime: "compiler/runtime.rkt"))

(define tests
  (test-suite
   "compiler tests"

   rules:tests
   strategy:tests
   runtime:tests))

(module+ main
  (void
   (run-tests tests)))
