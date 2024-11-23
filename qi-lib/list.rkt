#lang racket/base

(provide (for-space qi
                    (all-defined-out)))

(require (for-syntax racket/base
                     "private/util.rkt")
         syntax/parse/define
         "flow/extended/expander.rkt"
         (only-in "flow/space.rkt"
                  define-qi-alias)
         "macro.rkt"
         (prefix-in r: racket/base)
         (prefix-in r: racket/list))

(define-deforestable (map [f f])
  #'(lambda (vs)  ; single list arg
      (r:map f vs)))

(define-deforestable (filter [f f])
  #'(λ (vs)
      (r:filter f vs)))

(define-deforestable (filter-map [f f])
  #'(λ (vs)
      (r:filter-map f vs)))

(define-deforestable (foldl [f f] [e init])
  #'(λ (vs)
      (r:foldl f init vs)))

(define-deforestable (foldr [f f] [e init])
  #'(λ (vs)
      (r:foldr f init vs)))

(define-qi-syntax-parser range
  [(_ low:expr high:expr step:expr) #'(#%deforestable range () (low high step))]
  [(_ low:expr high:expr) #'(#%deforestable range () (low high 1))]
  [(_ high:expr) #'(#%deforestable range () (0 high 1))]
  ;; not strictly necessary but this provides a better error
  ;; message than simply "range: bad syntax" that's warranted
  ;; to differentiate from racket/list's `range`
  [_:id (report-syntax-error this-syntax
          "(range arg ...)"
          "range expects at least one argument")])

(define-deforestable (take [e n])
  #'(λ (vs)
      (r:take vs n)))

(define-deforestable car
  #'r:car)

(define-deforestable cadr
  #'r:cadr)

(define-deforestable caddr
  #'r:caddr)

(define-deforestable cadddr
  #'r:cadddr)

(define-deforestable (list-ref [e n])
  #'(λ (vs)
      (r:list-ref vs n)))

(define-deforestable length
  #'r:length)

(define-deforestable empty?
  #'r:empty?)

(define-qi-alias null? empty?)
