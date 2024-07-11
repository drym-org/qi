#lang racket/base

(provide (for-space qi
                    (all-defined-out)))

(require (for-syntax racket/base
                     "private/util.rkt")
         syntax/parse/define
         "flow/extended/expander.rkt"
         "macro.rkt")

(define-qi-syntax-rule (map f:expr)
  (#%deforestable (map f)))

(define-qi-syntax-rule (filter f:expr)
  (#%deforestable (filter f)))

(define-qi-syntax-rule (foldl f:expr init:expr)
  (#%deforestable (foldl f init)))

(define-qi-syntax-rule (foldr f:expr init:expr)
  (#%deforestable (foldr f init)))

(define-qi-syntax-parser range
  [(_ low:expr high:expr step:expr) #'(#%deforestable (range low high step))]
  [(_ low:expr high:expr) #'(range low high 1)]
  [(_ high:expr) #'(range 0 high 1)]
  [_:id (report-syntax-error this-syntax
          "(range arg ...)"
          "range expects at least one argument")])

(define-qi-syntax-rule (take n:expr)
  (#%deforestable (take n)))
