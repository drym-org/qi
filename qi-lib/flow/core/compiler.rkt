#lang racket/base

(provide (for-syntax compile-flow normalize-pass))

(require (for-syntax racket/base
                     syntax/parse)
         "compiler/1000-qi0.rkt"
         "compiler/2000-bindings.rkt"
         "compiler/0010-normalize.rkt"
         "compiler/0100-deforest.rkt"
         "passes.rkt")

(begin-for-syntax

  ;; note: this does not return compiled code but instead,
  ;; syntax whose expansion compiles the code
  (define (compile-flow stx)
    (run-passes stx)))
