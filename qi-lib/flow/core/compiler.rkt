#lang racket/base

(provide (for-syntax compile-flow normalize-pass))

(require (for-syntax racket/base
                     syntax/parse)
         "passes/pass-1000-qi0.rkt"
         "passes/pass-2000-bindings.rkt"
         "passes/pass-0010-normalize.rkt"
         "passes.rkt")

(begin-for-syntax

  ;; note: this does not return compiled code but instead,
  ;; syntax whose expansion compiles the code
  (define (compile-flow stx)
    (run-passes stx)))
