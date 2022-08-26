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
                    or%
                    thread-right
                    ~>>
                    crossover
                    X))

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

;;; Routing

;; Right-threading is just normal threading but with a syntax
;; property attached to the components indicating the chirality
(define-qi-syntax-rule (thread-right onex:right-threading-clause ...)
  (~> onex.chiral ...))

;; TODO: do it as an alias?
;; (define-qi-alias ~>> thread-right)

(define-qi-syntax-rule (~>> arg ...)
  (thread-right arg ...))

(define-qi-syntax-parser crossover
  [_:id #'(~> ▽ reverse △)])

;; TODO: alias
(define-qi-syntax-parser X
  [_:id #'crossover])
