#lang racket/base

(provide (for-syntax inline-pass
                     flowdef))

(require (for-syntax racket/base
                     syntax/parse
                     "../strategy.rkt"
                     "../private/form-property.rkt")
         "../passes.rkt")

(begin-for-syntax
  (struct flowdef (name def)
    #:transparent
    #:property prop:set!-transformer
    (λ (flowdef-instance stx)
      ;; stx is either (flow-name arg ...) or simply flow-name
      (syntax-parse stx
        [_:id (flowdef-name flowdef-instance)]
        ;; use . args instead of ... to be agnostic to the possibility
        ;; of any #%app transformers being at play
        [(id:id . args) (datum->syntax stx
                          (cons #'(#%expression id) #'args) stx)]
        [((~literal set!) _1 _2)
         (raise-syntax-error #f "set! not allowed!")]))))

(begin-for-syntax
  (define (inline-rewrite stx)
    (syntax-parse stx
      #:datum-literals (#%host-expression
                        esc)
      [(esc (#%host-expression id))
       #:declare id (static flowdef? "flow name")
       ;; def is now bound to the flowdef struct instance
       (define def (attribute id.value))
       (syntax-property (flowdef-def def)
                        'qi-do-not-recurse
                        #t)]
      [_ stx]))

  (define-and-register-pass 5 (inline-pass stx)
    (attach-form-property
     (find-and-map/qi
      ;; "knapsack" problem
      inline-rewrite ; don't use fixed-point finding
      ;; check if identifier
      ;; check if bound to flowdef struct
      ;; then do inlining
      ;; can probably use syntax-local-apply-transformer, should do everything that we need.
      stx))))
