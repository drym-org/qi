#lang racket/base

(provide tests)

(require rackunit
         rackunit/text-ui
         (prefix-in semantics: "compiler/semantics.rkt")
         (prefix-in rules: "compiler/rules.rkt")
         (prefix-in strategy: "compiler/strategy.rkt")
         (prefix-in impl: "compiler/impl.rkt"))

(define tests
  (test-suite
   "compiler tests"

   semantics:tests
   rules:tests
   strategy:tests
   impl:tests))

(module+ main
  (void
   (run-tests tests)))
