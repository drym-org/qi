#lang racket/base

(provide (for-space qi
                    (except-out (all-defined-out)
                                range2
                                range)
                    (rename-out [range2 range])))

(require (for-syntax racket/base
                     "private/util.rkt")
         syntax/parse/define
         "flow/extended/expander.rkt"
         (only-in "flow/space.rkt"
                  define-qi-alias)
         "macro.rkt"
         (prefix-in r: racket/base)
         (prefix-in r: racket/list))

(define-deforestable (map [floe f])
  #'(lambda (vs)  ; single list arg
      (r:map f vs)))

(define-deforestable (filter [floe f])
  #'(λ (vs)
      (r:filter f vs)))

(define-deforestable (filter-map [floe f])
  #'(λ (vs)
      (r:filter-map f vs)))

(define-deforestable (foldl [floe f] [expr init])
  #'(λ (vs)
      (r:foldl f init vs)))

(define-deforestable (foldr [floe f] [expr init])
  #'(λ (vs)
      (r:foldr f init vs)))

(define-deforestable (range [expr low] [expr high] [expr step])
  #'(λ ()
      (r:range low high step)))

;; We'd like to indicate multiple surface variants for `range` that
;; expand to a canonical form, and provide a single codegen just for the
;; canonical form.
;; Since `define-deforestable` doesn't support indicating multiple cases
;; yet, we use the ordinary macro machinery to expand surface variants of
;; `range` to a canonical form that is defined using
;; `define-deforestable`.
(define-qi-syntax-parser range2
  [(_ low:expr high:expr step:expr) #'(range low high step)]
  [(_ low:expr high:expr) #'(range low high 1)]
  [(_ high:expr) #'(range 0 high 1)]
  ;; not strictly necessary but this provides a better error
  ;; message than simply "range: bad syntax" that's warranted
  ;; to differentiate from racket/list's `range`
  [_:id (report-syntax-error this-syntax
          "(range arg ...)"
          "range expects at least one argument")])

(define-deforestable (take [expr n])
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

(define-deforestable (list-ref [expr n])
  #'(λ (vs)
      (r:list-ref vs n)))

(define-deforestable length
  #'r:length)

(define-deforestable empty?
  #'r:empty?)

(define-qi-alias null? empty?)
