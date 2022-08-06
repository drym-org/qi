#lang racket/base

(provide (for-syntax compile-flow))

(require (for-syntax racket/base
                     syntax/parse
                     racket/match
                     (only-in racket/list
                              make-list)
                     "syntax.rkt"
                     "aux-syntax.rkt"
                     (only-in "../private/util.rkt"
                              report-syntax-error))
         (only-in "../macro.rkt"
                  qi-macro?
                  qi-macro-transformer)
         "impl.rkt"
         racket/function
         (prefix-in fancy: fancy-app)
         (only-in racket/list
                  make-list))

(begin-for-syntax
  ;; note: this does not return compiled code but instead,
  ;; syntax whose expansion compiles the code
  (define (compile-flow stx)
    #`(qi0->racket #,(optimize-flow stx)))

  (define (optimize-flow stx)
    stx))

(define-syntax (qi0->racket stx)
  (syntax-parse (cadr (syntax->list stx))
    ;; Check first whether the form is a macro. If it is, expand it.
    ;; This is prioritized over other forms so that extensions may
    ;; override built-in Qi forms.
    [stx
     #:with (~or (m:id expr ...) m:id) #'stx
     #:do [(define space-m ((make-interned-syntax-introducer 'qi) #'m))]
     #:when (qi-macro? (syntax-local-value space-m (λ () #f)))
     #:with expanded (syntax-local-apply-transformer
                      (qi-macro-transformer (syntax-local-value space-m))
                      space-m
                      'expression
                      #f
                      #'stx)
     #'(qi0->racket expanded)]

    ;;; Special words
    [((~datum one-of?) v:expr ...)
     #'(compose
        ->boolean
        (curryr member (list v ...)))]
    [((~datum all) onex:clause)
     #`(give (curry andmap (qi0->racket onex)))]
    [((~datum any) onex:clause)
     #'(give (curry ormap (qi0->racket onex)))]
    [((~datum none) onex:clause)
     #'(qi0->racket (not (any onex)))]
    [((~datum and) onex:clause ...)
     #'(conjoin (qi0->racket onex) ...)]
    [((~datum or) onex:clause ...)
     #'(disjoin (qi0->racket onex) ...)]
    [((~datum not) onex:clause)
     #'(negate (qi0->racket onex))]
    [((~datum gen) ex:expr ...)
     #'(λ _ (values ex ...))]
    [(~or (~datum NOT) (~datum !))
     #'not]
    [(~or (~datum AND) (~datum &))
     #'all?]
    [(~or (~datum OR) (~datum ∥))
     #'any?]
    [(~datum NOR)
     #'(qi0->racket (~> OR NOT))]
    [(~datum NAND)
     #'(qi0->racket (~> AND NOT))]
    [(~datum XOR)
     #'parity-xor]
    [(~datum XNOR)
     #'(qi0->racket (~> XOR NOT))]
    [e:and%-form (and%-parser #'e)]
    [e:or%-form (or%-parser #'e)]
    [(~datum any?) #'any?]
    [(~datum all?) #'all?]
    [(~datum none?) #'none?]
    [(~or (~datum ▽) (~datum collect))
     #'list]
    [e:sep-form (sep-parser #'e)]

    ;;; Core routing elements

    [(~or (~datum ⏚) (~datum ground))
     #'(qi0->racket (select))]
    [((~or (~datum ~>) (~datum thread)) onex:clause ...)
     #'(reverse-compose (qi0->racket onex) ...)]
    [e:right-threading-form (right-threading-parser #'e)]
    [(~or (~datum X) (~datum crossover))
     #'(qi0->racket (~> ▽ reverse △))]
    [((~or (~datum ==) (~datum relay)) onex:clause ...)
     #'(relay (qi0->racket onex) ...)]
    [((~or (~datum ==*) (~datum relay*)) onex:clause ... rest-onex:clause)
     (with-syntax ([len (datum->syntax this-syntax
                          (length (syntax->list #'(onex ...))))])
       #'(qi0->racket (group len (== onex ...) rest-onex) ))]
    [((~or (~datum -<) (~datum tee)) onex:clause ...)
     #'(λ args
         (apply values
                (append (values->list
                         (apply (qi0->racket onex) args))
                        ...)))]
    [e:select-form (select-parser #'e)]
    [e:block-form (block-parser #'e)]
    [((~datum bundle) (n:number ...)
                      selection-onex:clause
                      remainder-onex:clause)
     #'(qi0->racket (-< (~> (select n ...) selection-onex)
                        (~> (block n ...) remainder-onex)))]
    [e:group-form (group-parser #'e)]

    ;;; Conditionals

    [e:if-form (if-parser #'e)]
    [((~datum when) condition:clause
                    consequent:clause)
     #'(qi0->racket (if condition consequent ⏚))]
    [((~datum unless) condition:clause
                      alternative:clause)
     #'(qi0->racket (if condition ⏚ alternative))]
    [e:switch-form (switch-parser #'e)]
    [e:sieve-form (sieve-parser #'e)]
    [e:partition-form (partition-parser #'e)]
    [((~datum gate) onex:clause)
     #'(qi0->racket (if onex _ ⏚))]

    ;;; Exceptions

    [e:try-form (try-parser #'e)]

    ;;; High level circuit elements

    ;; aliases for inputs
    [e:input-alias (input-alias-parser #'e)]

    ;; common utilities
    [(~datum count)
     #'(λ args (length args))]
    [(~datum live?)
     #'(λ args (not (null? args)))]
    [((~datum rectify) v:expr ...)
     #'(qi0->racket (if live? _ (gen v ...)))]

    ;; high level routing
    [e:fanout-form (fanout-parser #'e)]
    [e:feedback-form (feedback-parser #'e)]
    [(~datum inverter)
     #'(qi0->racket (>< NOT))]
    [e:side-effect-form (side-effect-parser #'e)]

    ;;; Higher-order flows

    ;; map, filter, and fold
    [e:amp-form (amp-parser #'e)]
    [e:pass-form (pass-parser #'e)]
    [e:fold-left-form (fold-left-parser #'e)]
    [e:fold-right-form (fold-right-parser #'e)]

    ;; looping
    [e:loop-form (loop-parser #'e)]
    [((~datum loop2) pred:clause mapex:clause combex:clause)
     #'(letrec ([loop2 (qi0->racket (if pred
                                        (~> (== (-< cdr
                                                    (~> car mapex)) _)
                                            (group 1 _ combex)
                                            loop2)
                                        2>))])
         loop2)]

    ;; towards universality
    [(~datum apply)
     #'call]
    [e:clos-form (clos-parser #'e)]

    ;;; Miscellaneous

    ;; escape hatch for racket expressions or anything
    ;; to be "passed through"
    [((~datum esc) ex:expr)
     #'ex]

    ;; backwards compat macro extensibility via Racket macros
    [((~var ext-form (starts-with "qi:")) expr ...)
     #'(ext-form expr ...)]

    ;; a literal is interpreted as a flow generating it
    [e:literal (literal-parser #'e)]

    ;; Partial application with syntactically pre-supplied arguments
    ;; in a blanket template
    [e:blanket-template-form (blanket-template-form-parser #'e)]

    ;; Fine-grained template-based application
    ;; This handles templates that indicate a specific number of template
    ;; variables (i.e. expected arguments). The semantics of template-based
    ;; application here is fulfilled by the fancy-app module. In order to use
    ;; it, we simply use the #%app macro provided by fancy-app instead of the
    ;; implicit one used for function application in racket/base.
    ;; "prarg" = "pre-supplied argument"
    [(prarg-pre ... (~datum _) prarg-post ...)
     #'(fancy:#%app prarg-pre ... _ prarg-post ...)]

    ;; Pre-supplied arguments without a template
    [(natex prarg ...+)
     ;; we use currying instead of templates when a template hasn't
     ;; explicitly been indicated since in such cases, we cannot
     ;; always infer the appropriate arity for a template (e.g. it
     ;; may change under composition within the form), while a
     ;; curried function will accept any number of arguments
     #:do [(define chirality (syntax-property this-syntax 'chirality))]
     (if (and chirality (eq? chirality 'right))
         #'(curry natex prarg ...)
         #'(curryr natex prarg ...))]

    ;; pass-through (identity flow)
    [(~datum _) #'values]

    ;; literally indicated function identifier
    [natex:expr #'natex]))

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
  (define-syntax-class disjux-clause ; "juxtaposed" disjoin
    #:attributes (parsed)
    (pattern
     (~datum _)
     #:with parsed #'false.)
    (pattern
     onex:clause
     #:with parsed #'onex))

  (define-syntax-class conjux-clause ; "juxtaposed" conjoin
    #:attributes (parsed)
    (pattern
     (~datum _)
     #:with parsed #'true.)
    (pattern
     onex:clause
     #:with parsed #'onex))

  (define (and%-parser stx)
    (syntax-parse stx
      [(_ onex:conjux-clause ...)
       #'(qi0->racket (~> (== onex.parsed ...)
                          all?))]))

  (define (or%-parser stx)
    (syntax-parse stx
      [(_ onex:disjux-clause ...)
       #'(qi0->racket (~> (== onex.parsed ...)
                          any?))]))

  (define (make-right-chiral stx)
    (syntax-property stx 'chirality 'right))

  (define-syntax-class right-threading-clause
    (pattern
     onex:clause
     #:with chiral (make-right-chiral #'onex)))

  (define (right-threading-parser stx)
    ;; right-threading is just normal threading
    ;; but with a syntax property attached to
    ;; the components indicating the chirality
    (syntax-parse stx
      [(_ onex:right-threading-clause ...)
       #'(qi0->racket (~> onex.chiral ...))]))

  (define (sep-parser stx)
    (syntax-parse stx
      [_:id
       #'(qi0->racket (if list?
                          (apply values _)
                          (raise-argument-error '△
                                                "list?"
                                                _)))]
      [(_ onex:clause)
       #'(λ (v . vs)
           ((qi0->racket (~> △ (>< (apply (qi0->racket onex) _ vs)))) v))]))

  (define (select-parser stx)
    (syntax-parse stx
      [(_ n:number ...) #'(qi0->racket (-< (esc (arg n)) ...))]
      [(_ arg ...) ; error handling catch-all
       (report-syntax-error 'select
                            (syntax->datum #'(arg ...))
                            "(select <number> ...)")]))

  (define (block-parser stx)
    (syntax-parse stx
      [(_ n:number ...)
       #'(qi0->racket (~> (esc (except-args n ...))
                          △))]
      [(_ arg ...) ; error handling catch-all
       (report-syntax-error 'block
                            (syntax->datum #'(arg ...))
                            "(block <number> ...)")]))

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
           (apply (qi0->racket (group n selection-flo remainder-flo)) vs))]
      [(_ arg ...) ; error handling catch-all
       (report-syntax-error 'group
                            (syntax->datum #'(arg ...))
                            "(group <number> <selection qi0->racket> <remainder qi0->racket>)")]))

  (define (switch-parser stx)
    (syntax-parse stx
      [(_) #'(qi0->racket _)]
      [(_ ((~or (~datum divert) (~datum %))
           condition-gate:clause
           consequent-gate:clause))
       #'(qi0->racket consequent-gate)]
      [(_ [(~datum else) alternative:clause])
       #'(qi0->racket alternative)]
      [(_ ((~or (~datum divert) (~datum %))
           condition-gate:clause
           consequent-gate:clause)
          [(~datum else) alternative:clause])
       #'(qi0->racket (~> consequent-gate alternative))]
      [(_ [condition0:clause ((~datum =>) consequent0:clause ...)]
          [condition:clause consequent:clause]
          ...)
       ;; we split the flow ahead of time to avoid evaluating
       ;; the condition more than once
       #'(qi0->racket (~> (-< condition0 _)
                          (if 1>
                              (~> consequent0 ...)
                              (group 1 ⏚
                                     (switch [condition consequent]
                                       ...)))))]
      [(_ ((~or (~datum divert) (~datum %))
           condition-gate:clause
           consequent-gate:clause)
          [condition0:clause ((~datum =>) consequent0:clause ...)]
          [condition:clause consequent:clause]
          ...)
       ;; both divert as well as => clauses. Here, the divert clause
       ;; operates on the original inputs, not including the result
       ;; of the condition flow.
       ;; as before, we split the flow ahead of time to avoid evaluating
       ;; the condition more than once
       #'(qi0->racket (~> (-< (~> condition-gate condition0) _)
                          (if 1>
                              (~> (group 1 _ consequent-gate)
                                  consequent0 ...)
                              (group 1 ⏚
                                     (switch (divert condition-gate consequent-gate)
                                       [condition consequent]
                                       ...)))))]
      [(_ [condition0:clause consequent0:clause]
          [condition:clause consequent:clause]
          ...)
       #'(qi0->racket (if condition0
                          consequent0
                          (switch [condition consequent]
                            ...)))]
      [(_ ((~or (~datum divert) (~datum %))
           condition-gate:clause
           consequent-gate:clause)
          [condition0:clause consequent0:clause]
          [condition:clause consequent:clause]
          ...)
       #'(qi0->racket (if (~> condition-gate condition0)
                          (~> consequent-gate consequent0)
                          (switch (divert condition-gate consequent-gate)
                            [condition consequent]
                            ...)))]))

  (define (sieve-parser stx)
    (syntax-parse stx
      [(_ condition:clause
          sonex:clause
          ronex:clause)
       #'(qi0->racket (-< (~> (pass condition) sonex)
                          (~> (pass (not condition)) ronex)))]
      [_:id
       #'(λ (condition sonex ronex . args)
           (apply (qi0->racket (-< (~> (pass condition) sonex)
                                   (~> (pass (not condition)) ronex)))
                  args))]
      [(_ arg ...) ; error handling catch-all
       (report-syntax-error 'sieve
                            (syntax->datum #'(arg ...))
                            "(sieve <predicate qi0->racket> <selection qi0->racket> <remainder qi0->racket>)")]))

  (define (partition-parser stx)
    (syntax-parse stx
      [(_:id)
       #'(qi0->racket ground)]
      [(_ [cond:clause body:clause])
       #'(qi0->racket (~> (pass cond) body))]
      [(_ [cond:clause body:clause]  ...+)
       #:with c+bs #'(list (cons (qi0->racket cond) (qi0->racket body)) ...)
       #'(qi0->racket (~>> (partition-values c+bs)))]))

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
             (apply (qi0->racket flo) args)))]
      [(_ arg ...)
       (report-syntax-error 'try
                            (syntax->datum #'(arg ...))
                            "(try <flo> [error-predicate-flo error-handler-flo] ...)")]))

  (define (input-alias-parser stx)
    (syntax-parse stx
      [(~datum 1>)
       #'(qi0->racket (select 1))]
      [(~datum 2>)
       #'(qi0->racket (select 2))]
      [(~datum 3>)
       #'(qi0->racket (select 3))]
      [(~datum 4>)
       #'(qi0->racket (select 4))]
      [(~datum 5>)
       #'(qi0->racket (select 5))]
      [(~datum 6>)
       #'(qi0->racket (select 6))]
      [(~datum 7>)
       #'(qi0->racket (select 7))]
      [(~datum 8>)
       #'(qi0->racket (select 8))]
      [(~datum 9>)
       #'(qi0->racket (select 9))]))

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
       #`(λ args
           (apply values
                  (append #,@(make-list (syntax->datum #'n) 'args))) )]
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
           (apply (qi0->racket (feedback (while tilex) (then thenex) f))
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
           (apply (qi0->racket (feedback n (then thenex) f)) args))]
      [(_ n:expr onex:clause)
       #'(qi0->racket (feedback n (then _) onex))]
      [(_ onex:clause)
       #'(λ (n . args)
           (apply (qi0->racket (feedback n onex)) args))]
      [_:id
       #'(λ (n flo . args)
           (apply (qi0->racket (feedback n flo))
                  args))]))

  (define (side-effect-parser stx)
    (syntax-parse stx
      [((~or (~datum ε) (~datum effect)) sidex:clause onex:clause)
       #'(qi0->racket (-< (~> sidex ⏚)
                          onex))]
      [((~or (~datum ε) (~datum effect)) sidex:clause)
       #'(qi0->racket (-< (~> sidex ⏚)
                          _))]))

  (define (amp-parser stx)
    (syntax-parse stx
      [(~or (~datum ><) (~datum amp))
       #'map-values]
      [((~or (~datum ><) (~datum amp)) onex:clause)
       #'(curry map-values (qi0->racket onex))]
      [((~or (~datum ><) (~datum amp)) onex0:clause onex:clause ...)
       (report-syntax-error
        'amp
        (syntax->datum #'(onex0 onex ...))
        "(>< flo)"
        "amp expects a single qi0->racket specification, but it received many.")]))

  (define (pass-parser stx)
    (syntax-parse stx
      [_:id
       #'filter-values]
      [(_ onex:clause)
       #'(curry filter-values (qi0->racket onex))]))

  (define (fold-left-parser stx)
    (syntax-parse stx
      [(~datum >>)
       #'foldl-values]
      [((~datum >>) fn init)
       #'(qi0->racket (~> (-< (gen (qi0->racket fn))
                              (gen (qi0->racket init))
                              _)
                          >>))]
      [((~datum >>) fn)
       #'(qi0->racket (>> fn (gen ((qi0->racket fn)))))]))

  (define (fold-right-parser stx)
    (syntax-parse stx
      [(~datum <<)
       #'foldr-values]
      [((~datum <<) fn init)
       #'(qi0->racket (~> (-< (gen (qi0->racket fn))
                              (gen (qi0->racket init))
                              _)
                          <<))]
      [((~datum <<) fn)
       #'(qi0->racket (<< fn (gen ((qi0->racket fn)))))]))

  (define (loop-parser stx)
    (syntax-parse stx
      [((~datum loop) pred:clause mapex:clause combex:clause retex:clause)
       #'(letrec ([loop (qi0->racket (if pred
                                         (~> (group 1 mapex loop)
                                             combex)
                                         retex))])
           loop)]
      [((~datum loop) pred:clause mapex:clause combex:clause)
       #'(qi0->racket (loop pred mapex combex ⏚))]
      [((~datum loop) pred:clause mapex:clause)
       #'(qi0->racket (loop pred mapex _ ⏚))]
      [((~datum loop) mapex:clause)
       #'(qi0->racket (loop #t mapex _ ⏚))]))

  (define (clos-parser stx)
    (syntax-parse stx
      [(~datum clos)
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
      [(natex prarg-pre ...+ (~datum __) prarg-post ...+)
       #'(curry (curryr natex
                        prarg-post ...)
                prarg-pre ...)]
      [(natex prarg-pre ...+ (~datum __))
       #'(curry natex prarg-pre ...)]
      [(natex (~datum __) prarg-post ...+)
       #'(curryr natex prarg-post ...)]
      [(natex (~datum __))
       #'natex])))
