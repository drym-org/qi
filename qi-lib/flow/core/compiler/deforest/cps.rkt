#lang racket/base

(provide (for-syntax deforest-pass))

(require (for-syntax racket/base
                     syntax/parse
                     "syntax.rkt"
                     "../../../extended/util.rkt"
                     syntax/srcloc
                     racket/syntax-srcloc)
         "templates.rkt"
         racket/performance-hint
         racket/match
         racket/contract/base)

;; "Composes" higher-order functions inline by directly applying them
;; to the result of each subsequent application, with the last argument
;; being passed to the penultimate application as a (single) argument.
;; This is specialized to our implementation of stream fusion in the
;; arguments it expects and how it uses them.
(define-syntax inline-compose1
  (syntax-rules ()
    [(_ f) f]
    [(_ [op (f ...)] rest ...) (op f ... (inline-compose1 rest ...))]))

(define-syntax inline-consing
  (syntax-rules ()
    [(_ state () rest ...) (inline-consing state rest ...)]
    [(_ state (arg) rest ...) (inline-consing (cons arg state) rest ...)]
    [(_ state) state]
    ))

(begin-for-syntax

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; Producers

  ;; Special "curry"ing for #%fine-templates. All #%host-expressions are
  ;; passed as they are and all (~datum _) are replaced by wrapper
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
      #'(lambda (proc)
          (lambda (carg ...)
            (proc aarg ...)))))

  ;; Special curry for #%blanket-template. Raises syntax error if there
  ;; are too many arguments. If the number of arguments is exactly the
  ;; maximum, wraps into lambda without any arguments. If less than
  ;; maximum, curries it from both left and right.
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
         #'(lambda (v)
             (lambda ()
               (v pre-arg ... post-arg ...)))]
        [else
         #'(lambda (v)
             (lambda rest
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
          (make-blanket-curry pre-arg
                              post-arg
                              max-args
                              #'form-stx
                              )]
         [(attribute fine?)
          (make-fine-curry arg min-args max-args #'form-stx)]
         [else
          (lambda (ctx name) #'(lambda (v) v))])]))

  (define-syntax-class fsp
    #:attributes (curry name contract prepare next)
    (pattern range:fsp-range
             #:attr name #''range
             #:attr contract #'(->* (real?) (real? real?) any)
             #:attr prepare #'range->cstream-prepare
             #:attr next #'range->cstream-next
             #:attr curry (make-producer-curry 1 3
                                               range.blanket? #'range.pre-arg #'range.post-arg
                                               range.fine? #'range.arg
                                               range))
    (pattern default:fsp-default
             #:attr name #''list->cstream
             #:attr contract #'(-> list? any)
             #:attr prepare #'list->cstream-prepare
             #:attr next #'list->cstream-next
             #:attr curry (lambda (ctx name) #'(lambda (v) v)))
    )

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; Transformers

  (define-syntax-class fst
    #:attributes (next f state)
    (pattern filter:fst-filter
             #:attr f #'(filter.f)
             #:attr next #'filter-cstream-next
             #:attr state #'())
    (pattern map:fst-map
             #:attr f #'(map.f)
             #:attr next #'map-cstream-next
             #:attr state #'())
    (pattern filter-map:fst-filter-map
             #:attr f #'(filter-map.f)
             #:attr next #'filter-map-cstream-next
             #:attr state #'())
    (pattern take:fst-take
             #:attr f #'()
             #:attr next #'take-cstream-next
             #:attr state #'(take.n))
    )

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; Consumers

  (define-syntax-class fsc
    #:attributes (end)
    (pattern foldr:fsc-foldr
             #:attr end #'(foldr-cstream-next foldr.op foldr.init))
    (pattern foldl:fsc-foldl
             #:attr end #'(foldl-cstream-next foldl.op foldl.init))
    (pattern list-ref:fsc-list-ref
             #:attr end #'(list-ref-cstream-next list-ref.pos 'list-ref.name))
    (pattern length:fsc-length
             #:attr end #'(length-cstream-next))
    (pattern empty?:fsc-empty?
             #:attr end #'(empty?-cstream-next))
    (pattern default:fsc-default
             #:attr end #'(cstream-next->list))
    )

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; The pass

  ;; Performs deforestation rewrite on the whole syntax tree.
  (define-and-register-deforest-pass (deforest-pass ops ctx)
    (syntax-parse (reverse ops)
      [(c:fsc
        t:fst ...
        p:fsp)
       ;; A static runtime contract is placed at the beginning of the
       ;; fused sequence. And runtime checks for consumers are in
       ;; their respective implementation procedure.
       #`(esc
          (#,((attribute p.curry) ctx (attribute p.name))
           (contract p.contract
                     (p.prepare
                      (lambda (state)
                        (define cstate (inline-consing state t.state ...))
                        cstate)
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

  )

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Runtime

(begin-encourage-inline

  ;; Producers

  (define-inline (list->cstream-next done skip yield)
    (λ (state)
      (cond [(null? state) (done)]
            [else (yield (car state) (cdr state))])))

  (define-inline (list->cstream-prepare consing next)
    (case-lambda
      [(lst) (next (consing lst))]
      [rest (void)]))

  (define-inline (range->cstream-next done skip yield)
    (λ (state)
      (match-define (list l h s) state)
      (cond [(< l h)
             (yield l (cons (+ l s) (cdr state)))]
            [else (done)])))

  (define-inline (range->cstream-prepare consing next)
    (case-lambda
      [(h) (next (consing (list 0 h 1)))]
      [(l h) (next (consing (list l h 1)))]
      [(l h s) (next (consing (list l h s)))]
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

  (define-inline (filter-map-cstream-next f next)
    (λ (done skip yield)
      (next done
            skip
            (λ (value state)
              (let ([fv (f value)])
                (if fv
                    (yield fv state)
                    (skip state)))))))

  (define-inline (take-cstream-next next)
    (λ (done skip yield)
      (λ (take-state)
        (define n (car take-state))
        (define state (cdr take-state))
        (cond ((zero? n)
               (done))
              (else
               ((next (λ ()
                        (error 'take-cstream-next "not enough"))
                      skip
                      (λ (value state)
                        (define new-state (cons (sub1 n) state))
                        (yield value new-state)))
                state))))))

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

  (define-inline (list-ref-cstream-next init-countdown name next ctx src)
    (λ (state)
      (let loop ([state state]
                 [countdown init-countdown])
        ((next (λ () ((contract (-> pair? any)
                                (λ (v) v)
                                name ctx #f
                                src) '()))
               (λ (state) (loop state countdown))
               (λ (value state)
                 (if (zero? countdown)
                     value
                     (loop state (sub1 countdown)))))
         state))))

  (define-inline (length-cstream-next next ctx src)
    (λ (state)
      (let loop ([state state]
                 [the-length 0])
        ((next (λ () the-length)
               (λ (state) (loop state the-length))
               (λ (value state)
                 (loop state (add1 the-length))))
         state))))

  (define-inline (empty?-cstream-next next ctx src)
    (λ (state)
      (let loop ([state state])
        ((next (λ () #t)
               (λ (state) (loop state))
               (λ (value state) #f))
         state))))

  )
