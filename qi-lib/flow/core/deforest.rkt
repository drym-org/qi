#lang racket/base

;; This module implements the stream fusion optimization to "deforest"
;; sequences of functional transformations (e.g. map, filter, fold, etc.)
;; so that they avoid constructing intermediate representations on the
;; way to producing the final result.
;;
;; See the wiki
;;   https://github.com/drym-org/qi/wiki/The-Compiler#stream-fusion
;; for an overview and some details of this implementation.

(provide (for-syntax deforest-pass))

(require (for-syntax racket/base
                     syntax/parse
                     racket/syntax-srcloc
                     syntax/srcloc
                     "../extended/util.rkt"
                     "strategy.rkt")
         "passes.rkt"
         racket/performance-hint
         racket/match
         racket/list
         racket/contract/base)

;; These bindings are used for ~literal matching to introduce implicit
;; producer/consumer when none is explicitly given in the flow.
(define cstream->list #'-cstream->list)
(define list->cstream #'-list->cstream)

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
  ;; Special "curry"ing for #%fine-templates. All #%host-expressions
  ;; are passed as they are and all (~datum _) are replaced by wrapper
  ;; lambda arguments.
  (define ((make-fine-curry argstx minargs maxargs form-stx) ctx name)
    (define argstxlst (syntax->list argstx))
    (define numargs (length argstxlst))
    (cond
      [(< numargs minargs)
       (raise-syntax-error (syntax->datum name)
                           (format "too few arguments - given ~a - accepts at least ~a"
                                   numargs minargs)
                           (prettify-flow-syntax ctx)
                           (prettify-flow-syntax form-stx))]
      [(> numargs maxargs)
       (raise-syntax-error (syntax->datum name)
                           (format "too many arguments - given ~a - accepts at most ~a"
                                   numargs maxargs)
                           (prettify-flow-syntax ctx)
                           (prettify-flow-syntax form-stx))])
    (define temporaries (generate-temporaries argstxlst))
    (define-values (allargs tmpargs)
      (for/fold ([all '()]
                 [tmps '()]
                 #:result (values (reverse all)
                                  (reverse tmps)))
                ([tmp (in-list temporaries)]
                 [arg (in-list argstxlst)])
        (syntax-parse arg
          #:datum-literals (#%host-expression)
          [(#%host-expression ex)
           (values (cons #'ex all)
                   tmps)]
          [(~datum _)
           (values (cons tmp all)
                   (cons tmp tmps))])))
    (with-syntax ([(carg ...) tmpargs]
                  [(aarg ...) allargs])
      #'(λ (proc)
          (λ (carg ...)
            (proc aarg ...)))))

  ;; Special curry for #%blanket-template. Raises syntax error if
  ;; there are too many arguments. If the number of arguments is
  ;; exactly the maximum, wraps into lambda without any arguments. If
  ;; less than maximum, curries it from both left and right.
  (define ((make-blanket-curry prestx poststx maxargs form-stx) ctx name)
    (define prelst (syntax->list prestx))
    (define postlst (syntax->list poststx))
    (define numargs (+ (length prelst) (length postlst)))
    (with-syntax ([(pre-arg ...) prelst]
                  [(post-arg ...) postlst])
      (cond
        [(> numargs maxargs)
         (raise-syntax-error (syntax->datum name)
                             (format "too many arguments - given ~a - accepts at most ~a"
                                     numargs maxargs)
                             (prettify-flow-syntax ctx)
                             (prettify-flow-syntax form-stx))]
        [(= numargs maxargs)
         #'(λ (v)
             (λ ()
               (v pre-arg ... post-arg ...)))]
        [else
         #'(λ (v)
             (λ rest
               (apply v pre-arg ...
                      (append rest
                              (list post-arg ...)))))])))

  ;; Unifying producer curry makers. The ellipsis escaping allows for
  ;; simple specification of pattern variable names as bound in the
  ;; syntax pattern.
  (define-syntax make-producer-curry
    (syntax-rules ()
      [(_ min-args max-args
          blanket? pre-arg post-arg
          fine? arg
          form-stx)
       (cond
         [(attribute blanket?)
          (make-blanket-curry #'(pre-arg (... ...))
                              #'(post-arg (... ...))
                              max-args
                              #'form-stx
                              )]
         [(attribute fine?)
          (make-fine-curry #'(arg (... ...)) min-args max-args #'form-stx)]
         [else
          (λ (ctx name) #'(λ (v) v))])]))

  ;; Used for producing the stream from particular
  ;; expressions. Implicit producer is list->cstream-next and it is
  ;; not created by using this class but rather explicitly used when
  ;; no syntax class producer is matched.
  (define-syntax-class fusable-stream-producer
    #:attributes (next prepare contract name curry)
    #:datum-literals (#%host-expression #%blanket-template #%fine-template esc __)
    ;; Explicit range producers.
    (pattern (~and (~or (esc (#%host-expression (~datum range)))
                        (~and (#%fine-template
                               ((#%host-expression (~datum range))
                                arg ...))
                              fine?)
                        (~and (#%blanket-template
                               ((#%host-expression (~datum range))
                                (#%host-expression pre-arg) ...
                                __
                                (#%host-expression post-arg) ...))
                              blanket?))
                   form-stx)
             #:attr next #'range->cstream-next
             #:attr prepare #'range->cstream-prepare
             #:attr contract #'(->* (real?) (real? real?) any)
             #:attr name #'range
             #:attr curry (make-producer-curry 1 3
                                               blanket? pre-arg post-arg
                                               fine? arg
                                               form-stx))

    ;; The implicit stream producer from plain list.
    (pattern (~literal list->cstream)
             #:attr next #'list->cstream-next
             #:attr prepare #'list->cstream-prepare
             #:attr contract #'(-> list? any)
             #:attr name #''list->cstream
             #:attr curry (λ (ctx name) #'(λ (v) v))))

  ;; Matches any stream transformer that can be in the head position
  ;; of the fused sequence even when there is no explicit
  ;; producer. Procedures accepting variable number of arguments like
  ;; `map` cannot be in this class.
  (define-syntax-class fusable-stream-transformer0
    #:attributes (f next)
    #:datum-literals (#%host-expression #%blanket-template __ _ #%fine-template)
    (pattern (~or (#%blanket-template
                   ((#%host-expression (~datum filter))
                    (#%host-expression f)
                    __))
                  (#%fine-template
                   ((#%host-expression (~datum filter))
                    (#%host-expression f)
                    _)))
             #:attr next #'filter-cstream-next))

  ;; All implemented stream transformers - within the stream, only
  ;; single value is being passed and therefore procedures like `map`
  ;; can (and should) be matched.
  (define-syntax-class fusable-stream-transformer
    #:attributes (f next)
    #:datum-literals (#%host-expression #%blanket-template __ _ #%fine-template)
    (pattern (~or (#%blanket-template
                   ((#%host-expression (~datum map))
                    (#%host-expression f)
                    __))
                  (#%fine-template
                   ((#%host-expression (~datum map))
                    (#%host-expression f)
                    _)))
             #:attr next #'map-cstream-next)

    (pattern (~or (#%blanket-template
                   ((#%host-expression (~datum filter))
                    (#%host-expression f)
                    __))
                  (#%fine-template
                   ((#%host-expression (~datum filter))
                    (#%host-expression f)
                    _)))
             #:attr next #'filter-cstream-next))

  ;; Terminates the fused sequence (consumes the stream) and produces
  ;; an actual result value.
  (define-syntax-class fusable-stream-consumer
    #:attributes (end)
    #:datum-literals (#%host-expression #%blanket-template _ __ #%fine-template esc)
    (pattern (~or (#%blanket-template
                   ((#%host-expression (~datum foldr))
                    (#%host-expression op)
                    (#%host-expression init)
                    __))
                  (#%fine-template
                   ((#%host-expression (~datum foldr))
                    (#%host-expression op)
                    (#%host-expression init)
                    _)))
             #:attr end #'(foldr-cstream-next op init))

    (pattern (~or (#%blanket-template
                   ((#%host-expression (~datum foldl))
                    (#%host-expression op)
                    (#%host-expression init)
                    __))
                  (#%fine-template
                   ((#%host-expression (~datum foldl))
                    (#%host-expression op)
                    (#%host-expression init)
                    _)))
             #:attr end #'(foldl-cstream-next op init))

    (pattern (~or (esc (#%host-expression (~datum car)))
                  (#%fine-template
                   ((#%host-expression (~datum car))
                    _))
                  (#%blanket-template
                   ((#%host-expression (~datum car))
                    __)))
             #:attr end #'(car-cstream-next))

    (pattern (~literal cstream->list)
             #:attr end #'(cstream-next->list)))

  ;; Used only in deforest-rewrite to properly recognize the end of
  ;; fusable sequence.
  (define-syntax-class non-fusable
    (pattern (~not (~or _:fusable-stream-transformer
                        _:fusable-stream-producer
                        _:fusable-stream-consumer))))

  ;; Generates a syntax for the fused operation for given
  ;; sequence. The syntax list must already be in the following form:
  ;; (producer transformer ... consumer)
  (define (generate-fused-operation ops ctx)
    (syntax-parse (reverse ops)
      [(c:fusable-stream-consumer
        t:fusable-stream-transformer ...
        p:fusable-stream-producer)
       ;; A static runtime contract is placed at the beginning of the
       ;; fused sequence. And runtime checks for consumers are in
       ;; their respective implementation procedure.
       #`(esc
          (#,((attribute p.curry) ctx (attribute p.name))
           (contract p.contract
                     (p.prepare
                      (#,@#'c.end
                       (inline-compose1 [t.next t.f] ...
                                        p.next)
                       '#,(prettify-flow-syntax ctx)
                       '#,(build-source-location-vector
                           (syntax-srcloc ctx))))
                     p.name
                     '#,(prettify-flow-syntax ctx)
                     #f
                     '#,(build-source-location-vector
                         (syntax-srcloc ctx)))))]))

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
      ;; return the input syntax unchanged if no rules
      ;; are applicable
      [_ stx]))

  ;; Performs deforestation rewrite on the whole syntax tree.
  (define-and-register-pass 100 (deforest-pass stx)
    (find-and-map/qi
     deforest-rewrite
     stx)))

(begin-encourage-inline

  ;; Producers

  (define-inline (list->cstream-next done skip yield)
    (λ (state)
      (cond [(null? state) (done)]
            [else (yield (car state) (cdr state))])))

  (define-inline (list->cstream-prepare next)
    (case-lambda
      [(lst) (next lst)]
      [rest (void)]))

  (define-inline (range->cstream-next done skip yield)
    (λ (state)
      (match-define (list l h s) state)
      (cond [(< l h)
             (yield l (cons (+ l s) (cdr state)))]
            [else (done)])))

  (define-inline (range->cstream-prepare next)
    (case-lambda
      [(h) (next (list 0 h 1))]
      [(l h) (next (list l h 1))]
      [(l h s) (next (list l h s))]
      [rest (void)]))

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

  (define-inline (cstream-next->list next ctx src)
    (λ (state)
      (let loop ([state state])
        ((next (λ () null)
               (λ (state) (loop state))
               (λ (value state)
                 (cons value (loop state))))
         state))))

  (define-inline (foldr-cstream-next op init next ctx src)
    (λ (state)
      (let loop ([state state])
        ((next (λ () init)
               (λ (state) (loop state))
               (λ (value state)
                 (op value (loop state))))
         state))))

  (define-inline (foldl-cstream-next op init next ctx src)
    (λ (state)
      (let loop ([acc init] [state state])
        ((next (λ () acc)
               (λ (state) (loop acc state))
               (λ (value state)
                 (loop (op value acc) state)))
         state))))

  (define-inline (car-cstream-next next ctx src)
    (λ (state)
      (let loop ([state state])
        ((next (λ () ((contract (-> pair? any)
                                (λ (v) v)
                                'car-cstream-next ctx #f
                                src) '()))
               (λ (state) (loop state))
               (λ (value state)
                 value))
         state))))

  )
