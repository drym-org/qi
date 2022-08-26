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
                    X
                    relay*
                    ==*
                    bundle
                    when
                    unless))

(require (for-syntax racket/base
                     syntax/parse
                     "syntax.rkt"
                     "../aux-syntax.rkt"
                     "../../private/util.rkt")
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

(define-qi-syntax-parser relay*
  [(_ onex:clause ... rest-onex:clause)
   #:with len #`#,(length (syntax->list #'(onex ...)))
   #'(group len (== onex ...) rest-onex)])

;; TODO: alias
(define-qi-syntax-rule (==* onex ...)
  (relay* onex ...))

(define-qi-syntax-rule (bundle (n:number ...)
                               selection-onex:clause
                               remainder-onex:clause)
  (-< (~> (select n ...) selection-onex)
      (~> (block n ...) remainder-onex)))

;;; Conditionals

(define-qi-syntax-rule (when condition:clause
                         consequent:clause)
  (if condition consequent ⏚))

(define-qi-syntax-rule (unless condition:clause
                         alternative:clause)
  (if condition ⏚ alternative))
