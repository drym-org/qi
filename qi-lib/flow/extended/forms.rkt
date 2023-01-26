#lang racket/base

(provide (for-space qi
                    (all-defined-out)
                    ;; defining and using a `define-qi-alias` form
                    ;; would be a more direct way to do this
                    (rename-out [thread-right ~>>]
                                [crossover X]
                                [relay* ==*]
                                [effect ε])))

(require (for-syntax racket/base
                     (only-in racket/list make-list)
                     "syntax.rkt"
                     "../aux-syntax.rkt")
         syntax/parse/define
         "expander.rkt"
         "../../macro.rkt"
         "../space.rkt"
         "impl.rkt")

;;; Predicates

(define-for-qi all? ~all?)

(define-for-qi AND ~all?)

(define-qi-syntax-rule (one-of? v:expr ...)
  (~> (member (list v ...)) ->boolean))

(define-qi-syntax-rule (all onex:clause)
  (~> (>< onex) AND))

(define-qi-syntax-rule (any onex:clause)
  (~> (>< onex) OR))

(define-qi-syntax-rule (none onex:clause)
  (not (any onex)))

(define-qi-syntax-parser NOR
  [_:id #'(~> OR NOT)])

(define-qi-syntax-parser NAND
  [_:id #'(~> AND NOT)])

(define-qi-syntax-parser XNOR
  [_:id #'(~> XOR NOT)])

(define-qi-syntax-parser any?
  [_:id #'OR])

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

(define-qi-syntax-parser crossover
  [_:id #'(~> ▽ reverse △)])

(define-qi-syntax-parser relay*
  [(_ onex:clause ... rest-onex:clause)
   #:with len #`#,(length (syntax->list #'(onex ...)))
   #'(group len (== onex ...) rest-onex)])

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

(define-qi-syntax-parser switch
  [(_) #'_]
  [(_ ((~or* (~datum divert) (~datum %))
       condition-gate:clause
       consequent-gate:clause))
   #'consequent-gate]
  [(_ [(~datum else) alternative:clause])
   #'alternative]
  [(_ ((~or* (~datum divert) (~datum %))
       condition-gate:clause
       consequent-gate:clause)
      [(~datum else) alternative:clause])
   #'(~> consequent-gate alternative)]
  [(_ [condition0:clause ((~datum =>) consequent0:clause ...)]
      [condition:clause consequent:clause]
      ...)
   ;; we split the flow ahead of time to avoid evaluating
   ;; the condition more than once
   #'(~> (-< condition0 _)
         (if 1>
             (~> consequent0 ...)
             (group 1 ⏚
                    (switch [condition consequent]
                      ...))))]
  [(_ ((~or* (~datum divert) (~datum %))
       condition-gate:clause
       consequent-gate:clause)
      [condition0:clause ((~datum =>) consequent0:clause ...)]
      [condition:clause consequent:clause]
      ...)
   ;; both divert as well as => clauses. Here, the divert clause
   ;; operates on the original inputs, not including the result
   ;; of the condition flow.
   ;; as before, we split the flow ahead of time to avoid evaluating
   ;; the condition more than once
   #'(~> (-< (~> condition-gate condition0) _)
         (if 1>
             (~> (group 1 _ consequent-gate)
                 consequent0 ...)
             (group 1 ⏚
                    (switch (divert condition-gate consequent-gate)
                      [condition consequent]
                      ...))))]
  [(_ [condition0:clause consequent0:clause]
      [condition:clause consequent:clause]
      ...)
   #'(if condition0
         consequent0
         (switch [condition consequent]
           ...))]
  [(_ ((~or* (~datum divert) (~datum %))
       condition-gate:clause
       consequent-gate:clause)
      [condition0:clause consequent0:clause]
      [condition:clause consequent:clause]
      ...)
   #'(if (~> condition-gate condition0)
         (~> consequent-gate consequent0)
         (switch (divert condition-gate consequent-gate)
           [condition consequent]
           ...))])

(define-qi-syntax-parser partition
  [(_:id)
   #'ground]
  [(_ [cond:clause body:clause])
   #'(~> (pass cond) body)]
  [(_ [cond:clause body:clause] [conds:clause bodies:clause] ...+)
   #'(sieve cond body (partition [conds bodies] ...))])

(define-qi-syntax-rule (gate onex:clause)
  (if onex _ ⏚))

;;; Common utilities

(define-for-qi (count . args)
  (length args))

(define-for-qi (live? . args)
  (not (null? args)))

(define-qi-syntax-rule (rectify v:expr ...)
  (if live? _ (gen v ...)))

;;; High level circuit elements

;; aliases for inputs
(define-qi-syntax-parser 1>
  [_:id #'(select 1)])
(define-qi-syntax-parser 2>
  [_:id #'(select 2)])
(define-qi-syntax-parser 3>
  [_:id #'(select 3)])
(define-qi-syntax-parser 4>
  [_:id #'(select 4)])
(define-qi-syntax-parser 5>
  [_:id #'(select 5)])
(define-qi-syntax-parser 6>
  [_:id #'(select 6)])
(define-qi-syntax-parser 7>
  [_:id #'(select 7)])
(define-qi-syntax-parser 8>
  [_:id #'(select 8)])
(define-qi-syntax-parser 9>
  [_:id #'(select 9)])

;; high level routing
(define-qi-syntax-parser fanout
  [_:id #'-<]
  [(_ n:number)
   ;; a slightly more efficient compile-time implementation
   ;; for literally indicated N
   ;; TODO: move this to a compiler optimization
   #:with list-of-n-blanks #`#,(make-list (syntax->datum #'n) #'_)
   #'(-< . list-of-n-blanks)]
  [(_ n:expr)
   #'(~> (-< (gen n) _) -<)])

(define-qi-syntax-parser inverter
  [_:id #'(>< NOT)])

(define-qi-syntax-parser effect
  [(_ sidex:clause onex:clause)
   #'(-< (~> sidex ⏚)
         onex)]
  [(_ sidex:clause)
   #'(-< (~> sidex ⏚)
         _)])
