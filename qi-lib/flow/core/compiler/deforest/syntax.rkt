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
                       "templates.rkt")
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
  #:datum-literals (#%deforestable2 range2)
  (pattern (#%deforestable2 range2 _info ((~datum e) the-arg) ...)
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
  #:datum-literals (#%deforestable2 filter)
  (pattern (#%deforestable2 filter _info ((~datum f) f-uncompiled))
    #:attr f (run-passes #'f-uncompiled)))

(define-syntax-class fst-map
  #:attributes (f)
  #:literal-sets (fs-literals)
  #:datum-literals (#%deforestable2 map)
  (pattern (#%deforestable2 map _info ((~datum f) f-uncompiled))
    #:attr f (run-passes #'f-uncompiled)))

(define-syntax-class fst-filter-map
  #:attributes (f)
  #:literal-sets (fs-literals)
  #:datum-literals (#%deforestable2 filter-map)
  (pattern (#%deforestable2 filter-map _info ((~datum f) f-uncompiled))
    #:attr f (run-passes #'f-uncompiled)))

(define-syntax-class fst-take
  #:attributes (n)
  #:literal-sets (fs-literals)
  #:datum-literals (#%deforestable2 take)
  (pattern (#%deforestable2 take _info ((~datum e) n))))

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
  #:datum-literals (#%deforestable2 foldr)
  (pattern (#%deforestable2
            foldr
            _info
            ((~datum f) op-uncompiled)
            ((~datum e) init))
    #:attr op (run-passes #'op-uncompiled)))

(define-syntax-class fsc-foldl
  #:attributes (op init)
  #:literal-sets (fs-literals)
  #:datum-literals (#%deforestable2 foldl)
  (pattern (#%deforestable2
            foldl
            _info
            ((~datum f) op-uncompiled)
            ((~datum e) init))
    #:attr op (run-passes #'op-uncompiled)))

(define-syntax-class cad*r-datum
  #:attributes (countdown)
  #:datum-literals (#%deforestable2 car cadr caddr cadddr)
  (pattern (#%deforestable2 car _info) #:attr countdown #'0)
  (pattern (#%deforestable2 cadr _info) #:attr countdown #'1)
  (pattern (#%deforestable2 caddr _info) #:attr countdown #'2)
  (pattern (#%deforestable2 cadddr _info) #:attr countdown #'3))

(define-syntax-class fsc-list-ref
  #:attributes (pos name)
  #:literal-sets (fs-literals)
  #:datum-literals (#%deforestable2 list-ref)
  ;; TODO: need #%host-expression wrapping idx?
  (pattern (#%deforestable2 list-ref _info ((~datum e) idx))
    #:attr pos #'idx
    #:attr name #'list-ref)
  ;; TODO: bring wrapping #%deforestable out here?
  (pattern cad*r:cad*r-datum
    #:attr pos #'cad*r.countdown
    #:attr name #'cad*r))

(define-syntax-class fsc-length
  #:literal-sets (fs-literals)
  #:datum-literals (#%deforestable2 length)
  (pattern (#%deforestable2 length _info)))

(define-syntax-class fsc-empty?
  #:literal-sets (fs-literals)
  #:datum-literals (#%deforestable2 empty?) ; note: null? expands to empty?
  (pattern (#%deforestable2 empty? _info)))

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
