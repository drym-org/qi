#lang racket/base

(provide tests)

(require rackunit
         rackunit/text-ui
         (prefix-in semantics: "compiler/semantics.rkt")
         (prefix-in rules: "compiler/rules.rkt")
         (prefix-in util: "compiler/util.rkt"))

(define tests
  (test-suite
   "compiler tests"

   semantics:tests
   rules:tests
   util:tests))

(module+ main
  (void
   (run-tests tests)))
