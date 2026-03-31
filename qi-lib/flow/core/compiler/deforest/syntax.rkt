#lang racket/base

(provide fst-new
         fsp-new
         fsc-new)

(require syntax/parse
         "../../../aux-syntax.rkt"
         (for-template racket/base
                       "../../passes.rkt"))

;; Literals set used for matching Fusable Stream Literals
(define-literal-set fs-literals
  #:datum-literals (#%deforestable)
  ())

(define-syntax-class fsa
  #:attributes (expr const?)
  #:description "fusable stream formal argument specification"
  (pattern ((~datum floe) f-uncompiled)
           #:attr expr #`#,(run-passes #'f-uncompiled)
           #:attr const? #t)
  (pattern ((~datum expr) expr)
           #:attr const? #f)
  (pattern ((~datum const) expr)
           #:attr const? #t))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Fusable Stream Producers
;;
;; Syntax classes used for matching functions that produce a sequence
;; of values and they annotate the syntax with attributes that will be
;; used in the compiler to apply optimizations.
;;

(define-syntax-class fsp-new
  #:attributes (contract prepare next name rcontract)
  #:literal-sets (fs-literals)
  (pattern (#%deforestable _name _info arg:fsa ...)
           #:do ((define is (syntax-local-value #'_info)))
           #:when (and (deforestable-info? is)
                       (eq? (deforestable-info-kind is) 'P))
           #:attr contract #`(#,@(deforestable-info-rtacontract is))
           #:with (const:fsa ...)
           (for/list ((stx (in-list (syntax->list #'(arg ...))))
                      (const? (in-list (attribute arg.const?)))
                      #:when const?)
             stx)
           #:with (expr:fsa ...)
           (for/list ((stx (in-list (syntax->list #'(arg ...))))
                      (const? (in-list (attribute arg.const?)))
                      #:when (not const?))
             stx)
           #:attr prepare (apply (deforestable-info-prepare is) (syntax->list #'(arg.expr ...)))
           #:with runtime (deforestable-info-runtime is)
           #:attr next #'(runtime const.expr ...)
           #:attr name #''name
           #:attr rcontract (deforestable-info-restcontract is)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Fusable Stream Transformers
;;
;; Syntax class matching all transformers defined by
;; (define-deforestable #:transformer ...)
;;
;; It provides the `next`, `f`, and `state` attributes as needed by
;; the deforest pass (see cps.rkt).
;;
;; It also allows `make-deforest-rewrire` to match it directly.
;;

(define-syntax-class fst-new
  #:attributes (next f state)
  #:literal-sets (fs-literals)
  (pattern (#%deforestable name _info arg:fsa ...)
           #:do ((define is (syntax-local-value #'_info)))
           #:when (and (deforestable-info? is)
                       (eq? (deforestable-info-kind is) 'T))
           #:attr next (deforestable-info-runtime is)
           #:with (const:fsa ...)
           (for/list ((stx (in-list (syntax->list #'(arg ...))))
                      (const? (in-list (attribute arg.const?)))
                      #:when const?)
             stx)
           #:with (expr:fsa ...)
           (for/list ((stx (in-list (syntax->list #'(arg ...))))
                      (const? (in-list (attribute arg.const?)))
                      #:when (not const?))
             stx)
           #:attr state #'(expr.expr ...)
           #:attr f #'(const.expr ...)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Fusable Stream Consumers
;;
;; Syntax classes used for matching functions that can consume all
;; values from a sequence and create a single value from those.
;;

(define-syntax-class fsc-new
  #:attributes (end)
  #:literal-sets (fs-literals)
  (pattern (#%deforestable name _info arg:fsa ...)
           #:do ((define is (syntax-local-value #'_info)))
           #:when (and (deforestable-info? is)
                       (eq? (deforestable-info-kind is) 'C))
           #:with next (deforestable-info-runtime is)
           #:attr end #'(next arg.expr ...)))
