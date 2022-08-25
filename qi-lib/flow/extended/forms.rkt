#lang racket/base

(provide (for-space qi
                    one-of?
                    all
                    any
                    none))

(require (for-syntax racket/base
                     syntax/parse
                     "../aux-syntax.rkt")
         "../../macro.rkt"
         "util.rkt")

;;; Predicates

(define-qi-syntax-rule (one-of? v:expr ...)
  (~> (member (list v ...)) ->boolean))

(define-qi-syntax-rule (all onex:clause)
  (~> (>< onex) AND))

(define-qi-syntax-rule (any onex:clause)
  (~> (>< onex) OR))

(define-qi-syntax-rule (none onex:clause)
  (not (any onex)))
