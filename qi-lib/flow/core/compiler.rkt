#lang racket/base

(provide (for-syntax compile-flow))

(require (for-syntax racket/base
                     syntax/parse
                     racket/match
                     "syntax.rkt"
                     "../aux-syntax.rkt"
                     racket/format)
         "impl.rkt"
         racket/function
         (prefix-in fancy: fancy-app))

(begin-for-syntax
  ;; note: this does not return compiled code but instead,
  ;; syntax whose expansion compiles the code
  (define (compile-flow stx)
    #`(qi0->racket #,(optimize-flow stx)))

  (define (optimize-flow stx)
    stx))

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

(define-syntax (qi0->racket stx)
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
    [(~or* (~datum AND) (~datum &)) ; NOTE: technically not core
     #'(qi0->racket (>> (and (select 2) (select 1)) (gen #t)))]
    [(~or* (~datum OR) (~datum ∥)) ; NOTE: technically not core
     #'(qi0->racket (<< (or (select 1) (select 2)) (gen #f)))]
    [(~or* (~datum NOT) (~datum !))
     #'not]
    [(~datum XOR)
     #'parity-xor]
    [((~datum and) onex:clause ...)
     #'(conjoin (qi0->racket onex) ...)]
    [((~datum or) onex:clause ...)
     #'(disjoin (qi0->racket onex) ...)]
    [((~datum not) onex:clause) ; NOTE: technically not core
     #'(qi0->racket (~> onex NOT))]
    ;; selection
    [e:select-form (select-parser #'e)]
    [e:block-form (block-parser #'e)]
    [e:group-form (group-parser #'e)]
    ;; conditionals
    [e:if-form (if-parser #'e)]
    [e:sieve-form (sieve-parser #'e)]
    ;; exceptions
    [e:try-form (try-parser #'e)]
    ;; folds
    [e:fold-left-form (fold-left-parser #'e)]
    [e:fold-right-form (fold-right-parser #'e)]
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
         #'(curry natex prarg ...)
         #'(curryr natex prarg ...))]))

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
       #'(feedback-times (qi0->racket onex) n (qi0->racket thenex))]
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
       #'(qi0->racket (loop onex))]))

  (define (pass-parser stx)
    (syntax-parse stx
      [_:id
       #'(qi0->racket (~> (group 1 (clos (if _ ⏚)) _)
                          ><))]
      [(_ onex:clause)
       #'(qi0->racket (>< (if onex _ ⏚)))]))

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
      [((~datum #%blanket-template) (natex (~datum __)))
       #'natex])))
