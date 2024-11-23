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
