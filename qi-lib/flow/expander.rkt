#lang racket/base

(provide expand-flow)

(require syntax/parse
         (for-template "impl.rkt" racket/base)
         "aux-syntax.rkt")

(define (expand-flow stx)
  (syntax-parse stx
    [((~datum all) onex:clause)
     #'(~> (>< onex) AND)]
    [_ stx]))
