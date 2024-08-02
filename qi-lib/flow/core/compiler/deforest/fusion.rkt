#lang racket/base

(provide define-and-register-deforest-pass)

(require (for-syntax racket/base
                     syntax/parse)
         syntax/parse
         "syntax.rkt"
         "../../passes.rkt"
         "../../strategy.rkt"
         (for-template "../../passes.rkt")
         "../../private/form-property.rkt")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; The actual fusion generator implementation

;; Used only in deforest-rewrite to properly recognize the end of
;; fusable sequence.
(define-syntax-class non-fusable
  (pattern (~not (~or _:fst-syntax
                      _:fsp-syntax
                      _:fsc-syntax))))

(define (make-deforest-rewrite generate-fused-operation)
  (lambda (stx)
    (attach-form-property
     (syntax-parse stx
       [((~datum thread) _0:non-fusable ...
                         p:fsp-syntax
                         ;; There can be zero transformers here:
                         t:fst-syntax ...
                         c:fsc-syntax
                         _1 ...)
        #:with fused (generate-fused-operation
                      (syntax->list #'(p t ... c))
                      stx)
        #'(thread _0 ... fused _1 ...)]
       [((~datum thread) _0:non-fusable ...
                         t1:fst-syntax0
                         t:fst-syntax ...
                         c:fsc-syntax
                         _1 ...)
        #:with fused (generate-fused-operation
                      (syntax->list #'(list->cstream t1 t ... c))
                      stx)
        #'(thread _0 ... fused _1 ...)]
       [((~datum thread) _0:non-fusable ...
                         p:fsp-syntax
                         ;; Must be 1 or more transformers here:
                         t:fst-syntax ...+
                         _1 ...)
        #:with fused (generate-fused-operation
                      (syntax->list #'(p t ... cstream->list))
                      stx)
        #'(thread _0 ... fused _1 ...)]
       [((~datum thread) _0:non-fusable ...
                         f1:fst-syntax0
                         f:fst-syntax ...+
                         _1 ...)
        #:with fused (generate-fused-operation
                      (syntax->list #'(list->cstream f1 f ... cstream->list))
                      stx)
        #'(thread _0 ... fused _1 ...)]
       ;; return the input syntax unchanged if no rules
       ;; are applicable
       [_ stx]))))

;; This syntax is actively used only once as it is intended to be used
;; by alternative implementations. Currently only the CPS
;; implementation uses it, however in the near future the named-let
;; implementation will use it as well.
(define-syntax (define-and-register-deforest-pass stx)
  (syntax-parse stx
    ((_ (deforest-pass ops ctx) expr ...)
     #'(define-and-register-pass 100 (deforest-pass stx)
         (find-and-map/qi
          (make-deforest-rewrite
           (lambda (ops ctx)
             expr ...))
          stx)))))
