#lang racket/base

(provide (for-syntax deforest-rewrite))

(require (for-syntax racket/base
                     syntax/parse
                     racket/syntax-srcloc)
         racket/performance-hint
         racket/match
         racket/function
         racket/list
         racket/contract/base)

;; These bindings are used for ~literal matching to introduce implicit
;; producer/consumer when none is explicitly given in the flow.
(define-syntax cstream->list #'-cstream->list)
(define-syntax list->cstream #'-list->cstream)

;; "Composes" higher-order functions inline by directly applying them
;; to the result of each subsequent application, with the last argument
;; being passed to the penultimate application as a (single) argument.
;; This is specialized to our implementation of stream fusion in the
;; arguments it expects and how it uses them.
(define-syntax inline-compose1
  (syntax-rules ()
    [(_ f) f]
    [(_ [op f] rest ...) (op f (inline-compose1 rest ...))]))

(begin-for-syntax

  ;; Used for producing the stream from particular
  ;; expressions. Implicit producer is list->cstream-next and it is
  ;; not created by using this class but rather explicitly used when
  ;; no syntax class producer is matched.
  (define-syntax-class fusable-stream-producer
    #:attributes (next prepare contract name)
    #:datum-literals (#%host-expression #%partial-application esc)
    ;; Explicit range producers. We have to conver all four variants
    ;; as they all come with different runtime contracts!
    (pattern (esc (#%host-expression (~literal range)))
             #:attr next #'range->cstream-next
             #:attr prepare #'range->cstream-prepare
             #:attr contract #'(->* (real?) (real? real?) any)
             #:attr name #''range)
    (pattern (~and (#%partial-application
                    ((#%host-expression (~literal range))
                     (#%host-expression arg1)))
                   stx)
             #:do [(define chirality (syntax-property #'stx 'chirality))]
             #:with vindaloo (if (and chirality (eq? chirality 'right))
                                 #'curry
                                 #'curryr)
             #:attr next #'range->cstream-next
             #:attr prepare #'(vindaloo range->cstream-prepare arg1)
             #:attr contract #'(->* () (real? real?) any)
             #:attr name #''range)
    (pattern (~and (#%partial-application
                    ((#%host-expression (~literal range))
                     (#%host-expression arg1)
                     (#%host-expression arg2)))
                   stx)
             #:do [(define chirality (syntax-property #'stx 'chirality))]
             #:with vindaloo (if (and chirality (eq? chirality 'right))
                                 #'curry
                                 #'curryr)
             #:attr next #'range->cstream-next
             #:attr prepare #'(vindaloo range->cstream-prepare arg1 arg2)
             #:attr contract #'(->* () (real?) any)
             #:attr name #''range)
    (pattern (#%partial-application
              ((#%host-expression (~literal range))
               (#%host-expression arg1)
               (#%host-expression arg2)
               (#%host-expression arg3)))
             #:attr next #'range->cstream-next
             #:attr prepare #'(λ () (range->cstream-prepare arg1 arg2 arg3))
             #:attr contract #'(-> any)
             #:attr name #''range)

    ;; The implicit stream producer from plain list.
    (pattern (~literal list->cstream)
             #:attr next #'list->cstream-next
             #:attr prepare #'values
             #:attr contract #'(-> list? any)
             #:attr name #''list->cstream))

  ;; Matches any stream transformer that can be in the head position
  ;; of the fused sequence even when there is no explicit
  ;; producer. Procedures accepting variable number of arguments like
  ;; `map` cannot be in this class.
  (define-syntax-class fusable-stream-transformer0
    #:attributes (f next)
    #:datum-literals (#%host-expression #%partial-application)
    (pattern (~and (#%partial-application
                    ((#%host-expression (~literal filter))
                     (#%host-expression f)))
                   stx)
             #:do [(define chirality (syntax-property #'stx 'chirality))]
             #:when (and chirality (eq? chirality 'right))
             #:attr next #'filter-cstream-next))

  ;; All implemented stream transformers - within the stream, only
  ;; single value is being passed and therefore procedures like `map`
  ;; can (and should) be matched.
  (define-syntax-class fusable-stream-transformer
    #:attributes (f next)
    #:datum-literals (#%host-expression #%partial-application)
    (pattern (~and (#%partial-application
                    ((#%host-expression (~literal map))
                     (#%host-expression f)))
                   stx)
             #:do [(define chirality (syntax-property #'stx 'chirality))]
             #:when (and chirality (eq? chirality 'right))
             #:attr next #'map-cstream-next)
    (pattern (~and (#%partial-application
                    ((#%host-expression (~literal filter))
                     (#%host-expression f)))
                   stx)
             #:do [(define chirality (syntax-property #'stx 'chirality))]
             #:when (and chirality (eq? chirality 'right))
             #:attr next #'filter-cstream-next))

  ;; Terminates the fused sequence (consumes the stream) and produces
  ;; an actual result value. The implicit consumer is cstream->list is
  ;; not part of this class as it is added explicitly when generating
  ;; the fused operation.
  (define-syntax-class fusable-stream-consumer
    #:attributes (end)
    #:datum-literals (#%host-expression #%partial-application)
    (pattern (~and (#%partial-application
                    ((#%host-expression (~literal foldr))
                     (#%host-expression op)
                     (#%host-expression init)))
                   stx)
             #:do [(define chirality (syntax-property #'stx 'chirality))]
             #:when (and chirality (eq? chirality 'right))
             #:attr end #'(foldr-cstream-next op init))
    (pattern (~and (#%partial-application
                    ((#%host-expression (~literal foldl))
                     (#%host-expression op)
                     (#%host-expression init)))
                   stx)
             #:do [(define chirality (syntax-property #'stx 'chirality))]
             #:when (and chirality (eq? chirality 'right))
             #:attr end #'(foldl-cstream-next op init))
    (pattern (~literal cstream->list)
             #:attr end #'(cstream-next->list))
    (pattern (esc (#%host-expression (~literal car)))
             #:attr end #'(car-cstream-next)))

  (define-syntax-class non-fusable
    (pattern (~not (~or _:fusable-stream-transformer
                        _:fusable-stream-producer
                        _:fusable-stream-consumer))))

  ;; Generates a syntax for the fused operation for given
  ;; sequence. The syntax list must already conform to the rule that
  ;; if the first operation is a fusable-stream-transformer, it must
  ;; be a fusable-stream-transformer0 as well!
  (define (generate-fused-operation ops ctx)
    (syntax-parse (reverse ops)
      [(c:fusable-stream-consumer
        t:fusable-stream-transformer ...
        p:fusable-stream-producer)
       ;; A static runtime contract is placed at the beginning of the
       ;; fused sequence.
       #`(esc (λ args
                ((#,@#'c.end
                  (inline-compose1 [t.next t.f] ...
                                   p.next))
                 (apply (contract p.contract
                                  p.prepare
                                  p.name
                                  '#,ctx
                                  #f
                                  #,(syntax-srcloc ctx))
                        args))))]))

  ;; 0. "Qi-normal form"
  ;; 1. deforestation pass
  ;; 2. other passes ...
  ;; e.g.:
  ;; changing internal representation to lists from values - may affect passes
  ;; passes as distinct stages is safe and interesting, a conservative start
  ;; one challenge: traversing the syntax tree
  (define (deforest-rewrite stx)
    (syntax-parse stx
      [((~datum thread) _0:non-fusable ...
                        p:fusable-stream-producer
                        ;; There can be zero transformers here:
                        t:fusable-stream-transformer ...
                        c:fusable-stream-consumer
                        _1 ...)
       #:with fused (generate-fused-operation
                     (syntax->list #'(p t ... c))
                     stx)
       #'(thread _0 ... fused _1 ...)]
      [((~datum thread) _0:non-fusable ...
                        t1:fusable-stream-transformer0
                        t:fusable-stream-transformer ...
                        c:fusable-stream-consumer
                        _1 ...)
       #:with fused (generate-fused-operation
                     (syntax->list #'(list->cstream t1 t ... c))
                      stx)
       #'(thread _0 ... fused _1 ...)]
      [((~datum thread) _0:non-fusable ...
                        p:fusable-stream-producer
                        ;; Must be 1 or more transformers here:
                        t:fusable-stream-transformer ...+
                        _1 ...)
       #:with fused (generate-fused-operation
                     (syntax->list #'(p t ... cstream->list))
                     stx)
       #'(thread _0 ... fused _1 ...)]
      [((~datum thread) _0:non-fusable ...
                        f1:fusable-stream-transformer0
                        f:fusable-stream-transformer ...+
                        _1 ...)
       #:with fused (generate-fused-operation
                     (syntax->list #'(list->cstream f1 f ... cstream->list))
                     stx)
       #'(thread _0 ... fused _1 ...)]
      [_ this-syntax]))

  )

(begin-encourage-inline

  ;; Producers

  (define-inline (list->cstream-next done skip yield)
    (λ (state)
      (cond [(null? state) (done)]
            [else (yield (car state) (cdr state))])))

  (define-inline (range->cstream-next done skip yield)
    (λ (state)
      (match-define (list l h s) state)
      (cond [(< l h)
             (yield l (cons (+ l s) (cdr state)))]
            [else (done)])))

  (define range->cstream-prepare
    (case-lambda
      [(h) (list 0 h 1)]
      [(l h) (list l h 1)]
      [(l h s) (list l h s)]))

  ;; Transformers

  (define-inline (map-cstream-next f next)
    (λ (done skip yield)
      (next done
            skip
            (λ (value state)
              (yield (f value) state)))))

  (define-inline (filter-cstream-next f next)
    (λ (done skip yield)
      (next done
            skip
            (λ (value state)
              (if (f value)
                  (yield value state)
                  (skip state))))))

  ;; Consumers

  (define-inline (cstream-next->list next)
    (λ (state)
      (let loop ([state state])
        ((next (λ () null)
               (λ (state) (loop state))
               (λ (value state)
                 (cons value (loop state))))
         state))))

  (define-inline (foldr-cstream-next op init next)
    (λ (state)
      (let loop ([state state])
        ((next (λ () init)
               (λ (state) (loop state))
               (λ (value state)
                 (op value (loop state))))
         state))))

  (define-inline (foldl-cstream-next op init next)
    (λ (state)
      (let loop ([acc init] [state state])
        ((next (λ () acc)
               (λ (state) (loop acc state))
               (λ (value state)
                 (loop (op value acc) state)))
         state))))

  (define-inline (car-cstream-next next)
    (λ (state)
      (let loop ([state state])
        ((next (λ () (error 'car "Empty list!"))
               (λ (state) (loop state))
               (λ (value state)
                 value))
         state))))

  )
