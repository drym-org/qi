#lang racket/base

(provide (for-space qi
                    one-of?
                    all
                    any
                    none
                    ;; not
                    NOR
                    NAND
                    XNOR
                    any?
                    all?
                    none?
                    and%
                    or%))

(require (for-syntax racket/base
                     syntax/parse
                     "syntax.rkt"
                     "../aux-syntax.rkt")
         "../../macro.rkt"
         "impl.rkt")

;;; Predicates

(define-qi-syntax-rule (one-of? v:expr ...)
  (~> (member (list v ...)) ->boolean))

(define-qi-syntax-rule (all onex:clause)
  (~> (>< onex) AND))

(define-qi-syntax-rule (any onex:clause)
  (~> (>< onex) OR))

(define-qi-syntax-rule (none onex:clause)
  (not (any onex)))

;; (define-qi-syntax-rule (not onex:clause)
;;   (~> onex NOT))

(define-qi-syntax-parser NOR
  [_:id #'(~> OR NOT)])

(define-qi-syntax-parser NAND
  [_:id #'(~> AND NOT)])

(define-qi-syntax-parser XNOR
  [_:id #'(~> XOR NOT)])

(define-qi-syntax-parser any?
  [_:id #'OR])

(define-qi-syntax-parser all?
  [_:id #'AND])

(define-qi-syntax-parser none?
  [_:id #'(~> any? NOT)])

(define-qi-syntax-rule (and% onex:conjux-clause ...)
  (~> (== onex.parsed ...)
      all?))

(define-qi-syntax-rule (or% onex:disjux-clause ...)
  (~> (== onex.parsed ...)
      any?))
