#lang racket/base

(provide (for-syntax compile-flow
                     ;; TODO: only used in unit tests, maybe try
                     ;; using a submodule to avoid providing these usually
                     deforest-rewrite))

(require (for-syntax racket/base
                     syntax/parse
                     racket/match
                     (only-in racket/list make-list)
                     "syntax.rkt"
                     "../aux-syntax.rkt"
                     macro-debugger/emit)
         "impl.rkt"
         (only-in racket/list make-list)
         racket/function
         racket/undefined
         (prefix-in fancy: fancy-app)
         racket/list
         "deforest.rkt")

(begin-for-syntax

  ;; currently does not distinguish substeps of a parent expansion step
  (define-syntax-rule (qi-expansion-step name stx0 stx1)
    (let ()
      (emit-local-step stx0 stx1 #:id #'name)
      stx1))

  (define-syntax-rule (define-qi-expansion-step (name stx0)
                        body ...)
    (define (name stx0)
      (let ([stx1 (let () body ...)])
        (qi-expansion-step name stx0 stx1))))

  ;; note: this does not return compiled code but instead,
  ;; syntax whose expansion compiles the code
  (define (compile-flow stx)
    (process-bindings (optimize-flow stx)))

  (define-qi-expansion-step (normalize-rewrite stx)
    ;; TODO: the "active" components of the expansions should be
    ;; optimized, i.e. they should be wrapped with a recursive
    ;; call to the optimizer
    ;; TODO: eliminate outdated rules here
    (syntax-parse stx
      ;; restorative optimization for "all"
      [((~datum thread) ((~datum amp) onex) (~datum AND))
       #`(esc (give (curry andmap #,(compile-flow #'onex))))]
      ;; "deforestation" for values
      ;; (~> (pass f) (>< g)) → (>< (if f g ⏚))
      [((~datum thread) _0 ... ((~datum pass) f) ((~datum amp) g) _1 ...)
       #'(thread _0 ... (amp (if f g ground)) _1 ...)]
      ;; merge amps in sequence
      [((~datum thread) _0 ... ((~datum amp) f) ((~datum amp) g) _1 ...)
       #`(thread _0 ... #,(normalize-rewrite #'(amp (thread f g))) _1 ...)]
      ;; merge pass filters in sequence
      [((~datum thread) _0 ... ((~datum pass) f) ((~datum pass) g) _1 ...)
       #'(thread _0 ... (pass (and f g)) _1 ...)]
      ;; collapse deterministic conditionals
      [((~datum if) (~datum #t) f g) #'f]
      [((~datum if) (~datum #f) f g) #'g]
      ;; trivial threading form
      [((~datum thread) f)
       #'f]
      ;; associative laws for ~>
      [((~datum thread) _0 ... ((~datum thread) f ...) _1 ...) ; note: greedy matching
       #'(thread _0 ... f ... _1 ...)]
      ;; left and right identity for ~>
      [((~datum thread) _0 ... (~datum _) _1 ...)
       #'(thread _0 ... _1 ...)]
      ;; composition of identity flows is the identity flow
      [((~datum thread) (~datum _) ...)
       #'_]
      ;; identity flows composed using a relay
      [((~datum relay) (~datum _) ...)
       #'_]
      ;; amp and identity
      [((~datum amp) (~datum _))
       #'_]
      ;; trivial tee junction
      [((~datum tee) f)
       #'f]
      ;; merge adjacent gens
      [((~datum tee) _0 ... ((~datum gen) a ...) ((~datum gen) b ...) _1 ...)
       #'(tee _0 ... (gen a ... b ...) _1 ...)]
      ;; prism identities
      ;; Note: (~> ... △ ▽ ...) can't be rewritten to `values` since that's
      ;; only valid if the input is in fact a list, and is an error otherwise,
      ;; and we can only know this at runtime.
      [((~datum thread) _0 ... (~datum collect) (~datum sep) _1 ...)
       #'(thread _0 ... _1 ...)]
      ;; return syntax unchanged if there are no known optimizations
      [_ stx]))

  ;; Applies f repeatedly to the init-val terminating the loop if the
  ;; result of f is #f or the new syntax object is eq? to the previous
  ;; (possibly initial) one.
  ;;
  ;; Caveats:
  ;;   * the syntax object is not inspected, only eq? is used
  ;;   * comparison is performed only between consecutive steps (does not handle cyclic occurences)
  (define ((fix f) init-val)
    (let ([new-val (f init-val)])
      (if (or (not new-val)
              (eq? new-val init-val))
          init-val
          ((fix f) new-val))))

  (define (deforest-pass stx)
    ;; Note: deforestation happens only for threading,
    ;; and the normalize pass strips the threading form
    ;; if it contains only one expression, so this would not be hit.
    (find-and-map/qi (fix deforest-rewrite)
                     stx))

  (define (normalize-pass stx)
    (find-and-map/qi (fix normalize-rewrite)
                     stx))

  (define (optimize-flow stx)
    ;; (deforest-pass (normalize-pass stx))
    (deforest-pass (normalize-pass stx))))

;; Transformation rules for the `as` binding form:
;;
;; 1. escape to wrap outermost ~> with let and re-enter
;;
;;   (~> flo ... (... (as name) ...))
;;   ...
;;    ↓
;;   ...
;;   (esc (let ([name (void)])
;;          (☯ original-flow)))
;;
;; 2. as → set!
;;
;;   (as name)
;;   ...
;;    ↓
;;   ...
;;   (~> (esc (λ (x) (set! name x))) ⏚)
;;
;; 3. Overall transformation:
;;
;;   (~> flo ... (... (as name) ...))
;;   ...
;;    ↓
;;   ...
;;   (esc (let ([name (void)])
;;          (☯ (~> flo ... (... (~> (esc (λ (x) (set! name x))) ⏚) ...)))))

(begin-for-syntax

  (define (find-and-map f stx)
    ;; f : syntax? -> (or/c syntax? #f)
    (match stx
      [(? syntax?) (let ([stx^ (f stx)])
                     (or stx^ (datum->syntax stx
                                (find-and-map f (syntax-e stx))
                                stx
                                stx)))]
      [(cons a d) (cons (find-and-map f a)
                        (find-and-map f d))]
      [_ stx]))

  (define (find-and-map/qi f stx)
    ;; #%host-expression is a Racket macro defined by syntax-spec
    ;; that resumes expansion of its sub-expression with an
    ;; expander environment containing the original surface bindings
    (find-and-map (syntax-parser [((~datum #%host-expression) e:expr) this-syntax]
                                 [_ (f this-syntax)])
                  stx))

  ;; (as name) → (~> (esc (λ (x) (set! name x))) ⏚)
  ;; TODO: use a box instead of set!
  (define (rewrite-all-bindings stx)
    (find-and-map/qi (syntax-parser
                       [((~datum as) x ...)
                        #:with (x-val ...) (generate-temporaries (attribute x))
                        #'(thread (esc (λ (x-val ...) (set! x x-val) ...)) ground)]
                       [_ #f])
                     stx))

  (define (bound-identifiers stx)
    (let ([ids null])
      (find-and-map/qi (syntax-parser
                         [((~datum as) x ...)
                          (set! ids
                                (append (attribute x) ids))]
                         [_ #f])
                       stx)
      ids))

  ;; wrap stx with (let ([v undefined] ...) stx) for v ∈ ids
  (define (wrap-with-scopes stx ids)
    (with-syntax ([(v ...) ids])
      #`(let ([v undefined] ...) #,stx)))

  (define-qi-expansion-step (process-bindings stx)
    ;; TODO: use syntax-parse and match ~> specifically.
    ;; Since macros are expanded "outside in," presumably
    ;; it will naturally wrap the outermost ~>
    (wrap-with-scopes #`(qi0->racket #,(rewrite-all-bindings stx))
                      (bound-identifiers stx))))

(define-syntax (qi0->racket stx)
  ;; this is a macro so it receives the entire expression
  ;; (qi0->racket ...). We use cadr here to parse the
  ;; contained expression.
  (syntax-parse (cadr (syntax->list stx))

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;; Core language forms ;;;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    [((~datum gen) ex:expr ...)
     #'(λ _ (values ex ...))]
    ;; pass-through (identity flow)
    [(~datum _) #'values]
    ;; routing
    [(~or* (~datum ⏚) (~datum ground)) ; NOTE: technically not core
     #'(qi0->racket (select))]
    [((~or* (~datum ~>) (~datum thread)) onex:clause ...)
     #`(compose . #,(reverse
                     (syntax->list
                      #'((qi0->racket onex) ...))))]
    [e:relay-form (relay-parser #'e)]
    [e:tee-form (tee-parser #'e)]
    ;; map and filter
    [e:amp-form (amp-parser #'e)] ; NOTE: technically not core
    [e:pass-form (pass-parser #'e)] ; NOTE: technically not core
    ;; prisms
    [e:sep-form (sep-parser #'e)]
    [(~or* (~datum ▽) (~datum collect))
     #'list]
    ;; predicates
    [(~or* (~datum NOT) (~datum !))
     #'not]
    [(~datum XOR)
     #'parity-xor]
    [((~datum and) onex:clause ...)
     #'(conjoin (qi0->racket onex) ...)]
    [((~datum or) onex:clause ...)
     #'(disjoin (qi0->racket onex) ...)]
    [((~datum not) onex:clause) ; NOTE: technically not core
     #'(negate (qi0->racket onex))]
    [((~datum all) onex:clause)
     #`(give (curry andmap (qi0->racket onex)))]
    [((~datum any) onex:clause)
     #'(give (curry ormap (qi0->racket onex)))]

    ;; selection
    [e:select-form (select-parser #'e)]
    [e:block-form (block-parser #'e)]
    [e:group-form (group-parser #'e)]
    ;; conditionals
    [e:if-form (if-parser #'e)]
    [e:sieve-form (sieve-parser #'e)]
    [e:partition-form (partition-parser #'e)]
    ;; exceptions
    [e:try-form (try-parser #'e)]
    ;; folds
    [e:fold-left-form (fold-left-parser #'e)]
    [e:fold-right-form (fold-right-parser #'e)]
    ;; high-level routing
    [e:fanout-form (fanout-parser #'e)]
    ;; looping
    [e:feedback-form (feedback-parser #'e)]
    [e:loop-form (loop-parser #'e)]
    [((~datum loop2) pred:clause mapex:clause combex:clause)
     #'(letrec ([loop2 (qi0->racket (if pred
                                        (~> (== (-< (esc cdr)
                                                    (~> (esc car) mapex)) _)
                                            (group 1 _ combex)
                                            (esc loop2))
                                        (select 2)))])
         loop2)]
    ;; towards universality
    [(~datum appleye)
     #'call]
    [e:clos-form (clos-parser #'e)]
    ;; escape hatch for racket expressions or anything
    ;; to be "passed through"
    [((~datum esc) ex:expr)
     #'ex]

    ;;; Miscellaneous

    ;; Partial application with syntactically pre-supplied arguments
    ;; in a blanket template
    ;; Note: at this point it's already been parsed/validated
    ;; by the expander and we don't need to worry about checking
    ;; the syntax at the compiler level
    [((~datum #%blanket-template) e)
     (blanket-template-form-parser this-syntax)]

    ;; Fine-grained template-based application
    ;; This handles templates that indicate a specific number of template
    ;; variables (i.e. expected arguments). The semantics of template-based
    ;; application here is fulfilled by the fancy-app module. In order to use
    ;; it, we simply use the #%app macro provided by fancy-app instead of the
    ;; implicit one used for function application in racket/base.
    ;; "prarg" = "pre-supplied argument"
    [((~datum #%fine-template) (prarg-pre ... (~datum _) prarg-post ...))
     #'(fancy:#%app prarg-pre ... _ prarg-post ...)]

    ;; Pre-supplied arguments without a template
    [((~datum #%partial-application) (natex prarg ...+))
     ;; we use currying instead of templates when a template hasn't
     ;; explicitly been indicated since in such cases, we cannot
     ;; always infer the appropriate arity for a template (e.g. it
     ;; may change under composition within the form), while a
     ;; curried function will accept any number of arguments
     #:do [(define chirality (syntax-property this-syntax 'chirality))]
     (if (and chirality (eq? chirality 'right))
         #'(lambda args
             (apply natex prarg ... args))
         ;; TODO: keyword arguments don't work for the left-chiral case
         ;; since we can't just blanket place the pre-supplied args
         ;; and need to handle the keyword arguments differently
         ;; from the positional arguments.
         #'(lambda args
             ((kw-helper natex args) prarg ...)))]))

;; The form-specific parsers, which are delegated to from
;; the qi0->racket macro:

#|
A note on error handling:

Some forms, in addition to handling legitimate syntax, also have
catch-all versions that exist purely to provide a helpful message
indicating a syntax error. We do this since a priori the qi0->racket macro
would ignore syntax that doesn't match any pattern. Yet, for all of
these named forms, we know that (or at least, it is prudent to assume
that) the user intended to employ that particular form of the DSL. So
instead of allowing it to fall through for interpretation as Racket
code, which would yield potentially inscrutable errors, the catch-all
forms allow us to provide appropriate error messages at the level of
the DSL.

|#

(begin-for-syntax

  (define (sep-parser stx)
    (syntax-parse stx
      [_:id
       #'(qi0->racket (if (esc list?)
                          (#%fine-template (apply values _))
                          (#%fine-template (raise-argument-error '△
                                                                 "list?"
                                                                 _))))]
      [(_ onex:clause)
       #'(λ (v . vs)
           ((qi0->racket (~> △ (>< (#%fine-template (apply (qi0->racket onex) _ vs))))) v))]))

  (define (select-parser stx)
    (syntax-parse stx
      [(_ n:number ...) #'(qi0->racket (-< (esc (arg n)) ...))]))

  (define (block-parser stx)
    (syntax-parse stx
      [(_ n:number ...)
       #'(qi0->racket (~> (esc (except-args n ...))
                          △))]))

  (define (group-parser stx)
    (syntax-parse stx
      [(_ n:expr
          selection-onex:clause
          remainder-onex:clause)
       #'(loom-compose (qi0->racket selection-onex)
                       (qi0->racket remainder-onex)
                       n)]
      [_:id
       #'(λ (n selection-flo remainder-flo . vs)
           (apply (qi0->racket (group n
                                      (esc selection-flo)
                                      (esc remainder-flo))) vs))]))

  (define (sieve-parser stx)
    (syntax-parse stx
      [(_ condition:clause
          sonex:clause
          ronex:clause)
       #'(qi0->racket (-< (~> (pass condition) sonex)
                          (~> (pass (not condition)) ronex)))]
      [_:id
       ;; sieve can be a core form once bindings
       ;; are introduced into the language
       #'(λ (condition sonex ronex . args)
           (apply (qi0->racket (-< (~> (pass (esc condition)) (esc sonex))
                                   (~> (pass (not (esc condition))) (esc ronex))))
                  args))]))

  (define (partition-parser stx)
    (syntax-parse stx
      [(_:id)
       #'(qi0->racket ground)]
      [(_ [cond:clause body:clause])
       #'(qi0->racket (~> (pass cond) body))]
      [(_ [cond:clause body:clause]  ...+)
       #:with c+bs #'(list (cons (qi0->racket cond) (qi0->racket body)) ...)
       #'(qi0->racket (#%blanket-template (partition-values c+bs __)))]))

  (define (try-parser stx)
    (syntax-parse stx
      [(_ flo
          [error-condition-flo error-handler-flo]
          ...+)
       #'(λ args
           (with-handlers ([(qi0->racket error-condition-flo)
                            (λ (e)
                              ;; TODO: may be good to support reference to the
                              ;; error via a binding / syntax parameter
                              (apply (qi0->racket error-handler-flo) args))]
                           ...)
             (apply (qi0->racket flo) args)))]))

  (define (if-parser stx)
    (syntax-parse stx
      [(_ consequent:clause
          alternative:clause)
       #'(λ (f . args)
           (if (apply f args)
               (apply (qi0->racket consequent) args)
               (apply (qi0->racket alternative) args)))]
      [(_ condition:clause
          consequent:clause
          alternative:clause)
       #'(λ args
           (if (apply (qi0->racket condition) args)
               (apply (qi0->racket consequent) args)
               (apply (qi0->racket alternative) args)))]))

  (define (fanout-parser stx)
    (syntax-parse stx
      [_:id #'repeat-values]
      [(_ n:number)
       ;; a slightly more efficient compile-time implementation
       ;; for literally indicated N
       ;; TODO: implement this as an optimization instead
       #`(λ args
           (apply values
                  (append #,@(make-list (syntax->datum #'n) #'args))) )]
      [(_ n:expr)
       #'(lambda args
           (apply values
                  (apply append
                         (make-list n args))))]))

  (define (feedback-parser stx)
    (syntax-parse stx
      [(_ ((~datum while) tilex:clause)
          ((~datum then) thenex:clause)
          onex:clause)
       #'(feedback-while (qi0->racket onex)
                         (qi0->racket tilex)
                         (qi0->racket thenex))]
      [(_ ((~datum while) tilex:clause)
          ((~datum then) thenex:clause))
       #'(λ (f . args)
           (apply (qi0->racket (feedback (while tilex) (then thenex) (esc f)))
                  args))]
      [(_ ((~datum while) tilex:clause) onex:clause)
       #'(qi0->racket (feedback (while tilex) (then _) onex))]
      [(_ ((~datum while) tilex:clause))
       #'(qi0->racket (feedback (while tilex) (then _)))]
      [(_ n:expr
          ((~datum then) thenex:clause)
          onex:clause)
       #'(lambda args
           (apply (feedback-times (qi0->racket onex) n (qi0->racket thenex))
                  args))]
      [(_ n:expr
          ((~datum then) thenex:clause))
       #'(λ (f . args)
           (apply (qi0->racket (feedback n (then thenex) (esc f))) args))]
      [(_ n:expr onex:clause)
       #'(qi0->racket (feedback n (then _) onex))]
      [(_ onex:clause)
       #'(λ (n . args)
           (apply (qi0->racket (feedback n onex)) args))]
      [_:id
       #'(λ (n flo . args)
           (apply (qi0->racket (feedback n (esc flo)))
                  args))]))

  (define (tee-parser stx)
    (syntax-parse stx
      [((~or* (~datum -<) (~datum tee)) onex:clause ...)
       #'(λ args
           (apply values
                  (append (values->list
                           (apply (qi0->racket onex) args))
                          ...)))]
      [(~or* (~datum -<) (~datum tee))
       #'repeat-values]))

  (define (relay-parser stx)
    (syntax-parse stx
      [((~or* (~datum ==) (~datum relay)) onex:clause ...)
       #'(relay (qi0->racket onex) ...)]
      [(~or* (~datum ==) (~datum relay))
       ;; review this – this "map" behavior may not be natural
       ;; for relay. And map-values should probably end up being
       ;; used in a compiler optimization
       #'map-values]))

  (define (amp-parser stx)
    (syntax-parse stx
      [_:id
       #'(qi0->racket ==)]
      [(_ onex:clause)
       #'(curry map-values (qi0->racket onex))]))

  (define (pass-parser stx)
    (syntax-parse stx
      [_:id
       #'filter-values]
      [(_ onex:clause)
       #'(curry filter-values (qi0->racket onex))]))

  (define (fold-left-parser stx)
    (syntax-parse stx
      [_:id
       #'foldl-values]
      [(_ fn init)
       #'(qi0->racket (~> (-< (gen (qi0->racket fn)
                                   (qi0->racket init))
                              _)
                          >>))]
      [(_ fn)
       #'(qi0->racket (>> fn (gen ((qi0->racket fn)))))]))

  (define (fold-right-parser stx)
    (syntax-parse stx
      [_:id
       #'foldr-values]
      [(_ fn init)
       #'(qi0->racket (~> (-< (gen (qi0->racket fn)
                                   (qi0->racket init))
                              _)
                          <<))]
      [(_ fn)
       #'(qi0->racket (<< fn (gen ((qi0->racket fn)))))]))

  (define (loop-parser stx)
    (syntax-parse stx
      [(_ pred:clause mapex:clause combex:clause retex:clause)
       #'(letrec ([loop (qi0->racket (if pred
                                         (~> (group 1 mapex (esc loop))
                                             combex)
                                         retex))])
           loop)]
      [(_ pred:clause mapex:clause combex:clause)
       #'(qi0->racket (loop pred mapex combex ⏚))]
      [(_ pred:clause mapex:clause)
       #'(qi0->racket (loop pred mapex _ ⏚))]
      [(_ mapex:clause)
       #'(qi0->racket (loop (gen #t) mapex _ ⏚))]
      [_:id #'(λ (predf mapf combf retf . args)
                (apply (qi0->racket (loop (esc predf)
                                          (esc mapf)
                                          (esc combf)
                                          (esc retf)))
                       args))]))

  (define (clos-parser stx)
    (syntax-parse stx
      [_:id
       #:do [(define chirality (syntax-property stx 'chirality))]
       (if (and chirality (eq? chirality 'right))
           #'(λ (f . args) (apply curryr f args))
           #'(λ (f . args) (apply curry f args)))]
      [(_ onex:clause)
       #:do [(define chirality (syntax-property stx 'chirality))]
       (if (and chirality (eq? chirality 'right))
           #'(λ args
               (qi0->racket (~> (-< _ (~> (gen args) △))
                                onex)))
           #'(λ args
               (qi0->racket (~> (-< (~> (gen args) △) _)
                                onex))))]))

  (define (literal-parser stx)
    (syntax-parse stx
      [val:literal #'(qi0->racket (gen val))]))

  (define (blanket-template-form-parser stx)
    (syntax-parse stx
      ;; "prarg" = "pre-supplied argument"
      [((~datum #%blanket-template)
        (natex prarg-pre ...+ (~datum __) prarg-post ...+))
       #'(curry (curryr natex
                        prarg-post ...)
                prarg-pre ...)]
      [((~datum #%blanket-template) (natex prarg-pre ...+ (~datum __)))
       #'(curry natex prarg-pre ...)]
      [((~datum #%blanket-template)
        (natex (~datum __) prarg-post ...+))
       #'(curryr natex prarg-post ...)]
      ;; TODO: this should be a compiler optimization
      [((~datum #%blanket-template) (natex (~datum __)))
       #'natex])))
