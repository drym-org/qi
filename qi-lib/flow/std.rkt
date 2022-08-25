#lang racket/base

(provide (for-space qi
                    one-of?))

(require (for-syntax racket/base
                     syntax/parse
                     "aux-syntax.rkt")
         "../macro.rkt"
         "impl.rkt")

;;; Predicates

(define-qi-syntax-rule (one-of? v:expr ...)
  (~> (member (list v ...)) ->boolean))
