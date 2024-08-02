#lang racket/base

(provide (for-space qi
                    (all-defined-out)))

(require (for-syntax racket/base
                     "private/util.rkt")
         syntax/parse/define
         "flow/extended/expander.rkt"
         (only-in "flow/space.rkt"
                  define-qi-alias)
         "macro.rkt")

(define-qi-syntax-rule (map f:expr)
  (#%deforestable map (f)))

(define-qi-syntax-rule (filter f:expr)
  (#%deforestable filter (f)))

(define-qi-syntax-rule (filter-map f:expr)
  (#%deforestable filter-map (f)))

(define-qi-syntax-rule (foldl f:expr init:expr)
  (#%deforestable foldl (f) (init)))

(define-qi-syntax-rule (foldr f:expr init:expr)
  (#%deforestable foldr (f) (init)))

(define-qi-syntax-parser range
  [(_ low:expr high:expr step:expr) #'(#%deforestable range () (low high step))]
  [(_ low:expr high:expr) #'(#%deforestable range () (low high 1))]
  [(_ high:expr) #'(#%deforestable range () (0 high 1))]
  [_:id (report-syntax-error this-syntax
          "(range arg ...)"
          "range expects at least one argument")])

(define-qi-syntax-rule (take n:expr)
  (#%deforestable take () (n)))

(define-qi-syntax-parser car
  [_:id #'(#%deforestable car)])

(define-qi-syntax-parser cadr
  [_:id #'(#%deforestable cadr)])

(define-qi-syntax-parser caddr
  [_:id #'(#%deforestable caddr)])

(define-qi-syntax-parser cadddr
  [_:id #'(#%deforestable cadddr)])

(define-qi-syntax-rule (list-ref n:expr)
  (#%deforestable list-ref () (n)))

(define-qi-syntax-parser length
  [_:id #'(#%deforestable length)])

(define-qi-syntax-parser empty?
  [_:id #'(#%deforestable empty?)])

(define-qi-alias null? empty?)
