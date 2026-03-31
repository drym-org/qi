#lang racket/base

(provide (for-syntax deforest-pass))

(require (for-syntax racket/base
                     syntax/parse
                     "syntax.rkt"
                     "../../../extended/util.rkt"
                     syntax/srcloc
                     racket/syntax-srcloc
                     "fusion.rkt"
                     "../../private/form-property.rkt")
         racket/contract/base)

;; "Composes" higher-order functions inline by directly applying them
;; to the result of each subsequent application, with the last argument
;; being passed to the penultimate application as a (single) argument.
;; This is specialized to our implementation of stream fusion in the
;; arguments it expects and how it uses them.
(define-syntax inline-compose1
  (syntax-rules ()
    [(_ f) f]
    [(_ [op (f ...) g ...] rest ...) (op f ... (inline-compose1 rest ...) g ...)]
    ))

;; Adds the initial states of all stateful transformers in the
;; required order to the initial producer state. Uses (cons Tx S)
;; where Tx is the transformer's initial state and S is the producer's
;; initial state with all preceding transformer states already
;; added. Nothing is added for stateless transformers which pass () as
;; their initial state expression. For example: (inline-consing (T1)
;; () (T2) P) -> (cons T2 (cons T1 P))
(define-syntax inline-consing
  (syntax-rules ()
    [(_ state () rest ...) (inline-consing state rest ...)]
    [(_ state (arg) rest ...) (inline-consing (cons arg state) rest ...)]
    [(_ state) state]
    ))

(define-syntax (#%host-expression stx)
  (syntax-parse stx
    ((_ expr)
     #'expr)))

(begin-for-syntax

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; The pass

  ;; Performs deforestation rewrite on the whole syntax tree.
  (define-and-register-deforest-pass (deforest-pass ops ctx)
    (syntax-parse (reverse ops)
      [(c:fsc-new
        t:fst-new ...
        p:fsp-new)
       ;; A static runtime contract is placed at the beginning of the
       ;; fused sequence. And runtime checks for consumers are in
       ;; their respective implementation procedure.
       #:with (rt ...) (reverse (attribute t.state))
       #:with (pcontract ...) (attribute p.contract)
       #:with the-contract (if (attribute p.rcontract)
                               #'(->* (pcontract ...) () #:rest p.rcontract any)
                               #'(-> pcontract ... any))
       (attach-form-property
        #`(esc
           (#%host-expression
            (contract the-contract
                      (p.prepare
                       (lambda (state)
                         (inline-consing state rt ...))
                       (#,@#'c.end
                        (inline-compose1 [t.next t.f
                                                 '#,(prettify-flow-syntax ctx)
                                                 '#,(build-source-location-vector
                                                     (syntax-srcloc ctx))
                                                 ] ...
                                         p.next
                                         )
                        '#,(prettify-flow-syntax ctx)
                        '#,(build-source-location-vector
                            (syntax-srcloc ctx))))
                      p.name
                      '#,(prettify-flow-syntax ctx)
                      #f
                      '#,(build-source-location-vector
                          (syntax-srcloc ctx)))
            )
           ))]))

  )
