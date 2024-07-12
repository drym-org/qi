#lang racket/base

(provide fsp-syntax
         fst-syntax0
         fst-syntax
         fsc-syntax

         fsp-range
         fsp-default

         fst-filter
         fst-map
         fst-filter-map
         fst-take

         fsc-foldr
         fsc-foldl
         fsc-list-ref
         fsc-length
         fsc-empty?
         fsc-default

         )

(require syntax/parse
         "../../passes.rkt"
         "../../strategy.rkt"
         (for-template racket/base
                       "../../passes.rkt"
                       "../../strategy.rkt"
                       "templates.rkt"
                       (prefix-in qi: "bindings.rkt"))
         (for-syntax racket/base
                     syntax/parse))

;; Literals set used for matching Fusable Stream Literals
(define-literal-set fs-literals
  #:datum-literals (esc #%host-expression #%fine-template #%blanket-template _ __)
  ())

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Fusable Stream Producers
;;
;; Syntax classes used for matching functions that produce a sequence
;; of values and they annotate the syntax with attributes that will be
;; used in the compiler to apply optimizations.
;;
;; All are prefixed with fsp- for clarity.

(define-syntax-class fsp-range
  #:attributes (blanket? fine? arg pre-arg post-arg)
  #:literal-sets (fs-literals)
  #:datum-literals (range)
  (pattern (#%deforestable (range the-arg ...))
    #:attr arg #'(the-arg ...)
    #:attr pre-arg #f
    #:attr post-arg #f
    #:attr blanket? #f
    #:attr fine? #t))

(define-syntax-class fsp-default
  #:datum-literals (list->cstream)
  (pattern list->cstream
           #:attr contract #'(-> list? any)
           #:attr name #''list->cstream))

(define-syntax-class fsp-syntax
  (pattern (~or _:fsp-range
                _:fsp-default)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Fusable Stream Transformers
;;
;; Syntax classes matching functions acting as transformers of the
;; sequence of values passing through.
;;
;; All are prefixed with fst- for clarity.

(define-syntax-class fst-filter
  #:attributes (f)
  #:literal-sets (fs-literals)
  #:datum-literals (filter)
  (pattern (#%deforestable (filter (#%host-expression f)))))

(define-syntax-class fst-map
  #:attributes (f)
  #:literal-sets (fs-literals)
  #:datum-literals (map)
  (pattern (#%deforestable (map (#%host-expression f)))))

(define-syntax-class fst-filter-map
  #:attributes (f)
  #:literal-sets (fs-literals)
  #:datum-literals (filter-map)
  (pattern (#%deforestable (filter-map (#%host-expression f)))))

(define-syntax-class fst-take
  #:attributes (n)
  #:literal-sets (fs-literals)
  #:datum-literals (take)
  (pattern (#%deforestable (take (#%host-expression n)))))

(define-syntax-class fst-syntax0
  (pattern (~or _:fst-filter
                _:fst-filter-map)))

(define-syntax-class fst-syntax
  (pattern (~or _:fst-filter
                _:fst-map
                _:fst-filter-map
                _:fst-take)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Fusable Stream Consumers
;;
;; Syntax classes used for matching functions that can consume all
;; values from a sequence and create a single value from those.
;;
;; Prefixed with fsc- for clarity.

(define-syntax-class fsc-foldr
  #:attributes (op init)
  #:literal-sets (fs-literals)
  #:datum-literals (foldr)
  (pattern (#%deforestable
            (foldr
             (#%host-expression op)
             (#%host-expression init)))))

(define-syntax-class fsc-foldl
  #:attributes (op init)
  #:literal-sets (fs-literals)
  #:datum-literals (foldl)
  (pattern (#%deforestable
            (foldl
             (#%host-expression op)
             (#%host-expression init)))))

(define-syntax-class cad*r-datum
  #:attributes (countdown)
  (pattern (#%deforestable (~datum car)) #:attr countdown #'0)
  (pattern (#%deforestable (~datum cadr)) #:attr countdown #'1)
  (pattern (#%deforestable (~datum caddr)) #:attr countdown #'2)
  (pattern (#%deforestable (~datum cadddr)) #:attr countdown #'3))

(define-syntax-class fsc-list-ref
  #:attributes (pos name)
  #:literal-sets (fs-literals)
  #:datum-literals (list-ref)
  (pattern (#%deforestable (list-ref idx))
           #:attr pos #'idx
           #:attr name #'list-ref)
  (pattern cad*r:cad*r-datum
           #:attr pos #'cad*r.countdown
           #:attr name #'cad*r))

(define-syntax-class fsc-length
  #:literal-sets (fs-literals)
  #:datum-literals (length)
  (pattern (#%deforestable length)))

(define-syntax-class fsc-empty?
  #:literal-sets (fs-literals)
  #:datum-literals (null? empty?)
  (pattern (#%deforestable (~or empty?
                                null?))))

(define-syntax-class fsc-default
  #:datum-literals (cstream->list)
  (pattern cstream->list))

(define-syntax-class fsc-syntax
  (pattern (~or _:fsc-foldr
                _:fsc-foldl
                _:fsc-list-ref
                _:fsc-length
                _:fsc-empty?
                _:fsc-default
                )))