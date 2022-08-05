#lang racket/base

(provide flow
         ☯
         (for-syntax subject
                     clause))

(require syntax/parse/define
         (prefix-in fancy: fancy-app)
         racket/function
         (only-in racket/list
                  make-list)
         (for-syntax racket/base
                     syntax/parse
                     racket/match
                     (only-in racket/list
                              make-list)
                     (only-in "private/util.rkt"
                              report-syntax-error)
                     "flow/syntax.rkt")
         (only-in qi/macro
                  qi-macro?
                  qi-macro-transformer))

(require "private/util.rkt")

(define-alias ☯ flow)

#|
The `flow` macro specifies the Qi language. In cases where there is
more than one expansion rule for a particular form of the language,
the expansion is delegated to a syntax class and a parser dedicated to
that form, so that the form is still represented as a single rule in
the flow macro, with the nuanced handling defined in the form-specific
parser.

The syntax classes for matching individual forms are in the
flow/syntax module, while the form-specific parsers are in the present
module, defined after the flow macro. They are all invoked as needed
in the flow macro.
|#


(begin-for-syntax
  (define (optimize-flow stx)
    stx)
  (define (qi0->racket stx)
    (syntax-parse stx

      [((~or (~datum ~>) (~datum thread)) onex:clause ...)
       (datum->syntax this-syntax
         (cons 'compose
               (reverse
                (syntax->list
                 #'((flow onex) ...)))))]


      [e:right-threading-form (right-threading-parser #'e)]
      [(~or (~datum X) (~datum crossover))
       #'(flow (~> ▽ reverse △))]
      [((~or (~datum ==) (~datum relay)) onex:clause ...)
       #'(relay (flow onex) ...)]

      [((~or (~datum ==*) (~datum relay*)) onex:clause ... rest-onex:clause)
       (with-syntax ([len (datum->syntax this-syntax
                            (length (syntax->list #'(onex ...))))])
         #'(flow (group len (== onex ...) rest-onex) ))]
      [((~or (~datum -<) (~datum tee)) onex:clause ...)
       #'(λ args
           (apply values
                  (append (values->list
                           (apply (flow onex) args))
                          ...)))]
      [e:select-form (select-parser #'e)]
      [e:block-form (block-parser #'e)]
      [((~datum bundle) (n:number ...)
                        selection-onex:clause
                        remainder-onex:clause)
       #'(flow (-< (~> (select n ...) selection-onex)
                   (~> (block n ...) remainder-onex)))]
      [e:group-form (group-parser #'e)]


      [(~or (~datum NOT) (~datum !))
       #'not]
      [(~or (~datum AND) (~datum &))
       #'all?]
      [(~or (~datum OR) (~datum ∥))
       #'any?]
      [(~datum NOR)
       #'(flow (~> OR NOT))]
      [(~datum NAND)
       #'(flow (~> AND NOT))]
      [(~datum XOR)
       #'parity-xor]
      [(~datum XNOR)
       #'(flow (~> XOR NOT))]
      [e:and%-form (and%-parser #'e)]
      [e:or%-form (or%-parser #'e)]
      [(~datum any?) #'any?]
      [(~datum all?) #'all?]
      [(~datum none?) #'none?]
      [(~or (~datum ▽) (~datum collect))
       #'list]
      [e:sep-form (sep-parser #'e)]


      ;;; Conditionals

      [e:if-form (if-parser #'e)]
      [((~datum when) condition:clause
                      consequent:clause)
       #'(flow (if condition consequent ⏚))]
      [((~datum unless) condition:clause
                        alternative:clause)
       #'(flow (if condition ⏚ alternative))]
      [e:switch-form (switch-parser #'e)]
      [e:sieve-form (sieve-parser #'e)]
      [e:partition-form (partition-parser #'e)]
      [((~datum gate) onex:clause)
       #'(flow (if onex _ ⏚))]

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
       #'(flow (if live? _ (gen v ...)))]

      ;; high level routing
      [e:fanout-form (fanout-parser #'e)]
      [e:feedback-form (feedback-parser #'e)]
      [(~datum inverter)
       #'(flow (>< NOT))]
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
       #'(letrec ([loop2 (☯ (if pred
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
      [natex:expr #'natex]

      ))
  (define (compile-flow stx)
    ((compose qi0->racket optimize-flow) stx))
  (define (expand-flow stx)
    stx))

(define-syntax-parser flow


  ;; Check first whether the form is a macro. If it is, expand it.
  ;; This is prioritized over other forms so that extensions may
  ;; override built-in Qi forms.
  [(_ stx)
   #:with (~or (m:id expr ...) m:id) #'stx
   #:do [(define space-m ((make-interned-syntax-introducer 'qi) #'m))]
   #:when (qi-macro? (syntax-local-value space-m (λ () #f)))
   #:with expanded (syntax-local-apply-transformer
                    (qi-macro-transformer (syntax-local-value space-m))
                    space-m
                    'expression
                    #f
                    #'stx)
   #'(flow expanded)]

  ;;; Special words
  [(_ ((~datum one-of?) v:expr ...))
   #'(compose
      ->boolean
      (curryr member (list v ...)))]
  [(_ ((~datum all) onex:clause))
   #'(give (curry andmap (flow onex)))]
  [(_ ((~datum any) onex:clause))
   #'(give (curry ormap (flow onex)))]
  [(_ ((~datum none) onex:clause))
   #'(flow (not (any onex)))]
  [(_ ((~datum and) onex:clause ...))
   #'(conjoin (flow onex) ...)]
  [(_ ((~datum or) onex:clause ...))
   #'(disjoin (flow onex) ...)]
  [(_ ((~datum not) onex:clause))
   #'(negate (flow onex))]
  [(_ ((~datum gen) ex:expr ...))
   #'(λ _ (values ex ...))]

  ;;; Core routing elements

  [(_ (~or (~datum ⏚) (~datum ground)))
       #'(flow (select))]


  ;; refactored way
  [(_ onex) ((compose compile-flow expand-flow) #'onex)]

  ;; a non-flow
  [(_) #'values]

  [(flow expr0 expr ...+)  ; error handling catch-all
   (report-syntax-error
    'flow
    (syntax->datum #'(expr0 expr ...))
    "(flow flo)"
    "flow expects a single flow specification, but it received many.")]

  )

#|
A note on error handling:

Some forms, in addition to handling legitimate syntax, also have
catch-all versions that exist purely to provide a helpful message
indicating a syntax error. We do this since a priori the flow macro
would ignore syntax that doesn't match any pattern. Yet, for all of
these named forms, we know that (or at least, it is prudent to assume
that) the user intended to employ that particular form of the DSL. So
instead of allowing it to fall through for interpretation as Racket
code, which would yield potentially inscrutable errors, the catch-all
forms allow us to provide appropriate error messages at the level of
the DSL.

|#

(begin-for-syntax

  ;; The form-specific parsers, which are delegated to from
  ;; the flow macro:

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
       #'(flow (~> (== onex.parsed ...)
                   all?))]))

  (define (or%-parser stx)
    (syntax-parse stx
      [(_ onex:disjux-clause ...)
       #'(flow (~> (== onex.parsed ...)
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
       #'(flow (~> onex.chiral ...))]))

  (define (sep-parser stx)
    (syntax-parse stx
      [_:id
       #'(flow (if list?
                   (apply values _)
                   (raise-argument-error '△
                                         "list?"
                                         _)))]
      [(_ onex:clause)
       #'(λ (v . vs)
           ((flow (~> △ (>< (apply (flow onex) _ vs)))) v))]))

  (define (select-parser stx)
    (syntax-parse stx
      [(_ n:number ...) #'(flow (-< (esc (arg n)) ...))]
      [(_ arg ...) ; error handling catch-all
       (report-syntax-error 'select
                            (syntax->datum #'(arg ...))
                            "(select <number> ...)")]))

  (define (block-parser stx)
    (syntax-parse stx
      [(_ n:number ...)
       #'(flow (~> (esc (except-args n ...))
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
       #'(loom-compose (flow selection-onex)
                       (flow remainder-onex)
                       n)]
      [_:id
       #'(λ (n selection-flo remainder-flo . vs)
           (apply (flow (group n selection-flo remainder-flo)) vs))]
      [(_ arg ...) ; error handling catch-all
       (report-syntax-error 'group
                            (syntax->datum #'(arg ...))
                            "(group <number> <selection flow> <remainder flow>)")]))

  (define (switch-parser stx)
    (syntax-parse stx
      [(_) #'(flow)]
      [(_ ((~or (~datum divert) (~datum %))
           condition-gate:clause
           consequent-gate:clause))
       #'(flow consequent-gate)]
      [(_ [(~datum else) alternative:clause])
       #'(flow alternative)]
      [(_ ((~or (~datum divert) (~datum %))
           condition-gate:clause
           consequent-gate:clause)
          [(~datum else) alternative:clause])
       #'(flow (~> consequent-gate alternative))]
      [(_ [condition0:clause ((~datum =>) consequent0:clause ...)]
          [condition:clause consequent:clause]
          ...)
       ;; we split the flow ahead of time to avoid evaluating
       ;; the condition more than once
       #'(flow (~> (-< condition0 _)
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
       #'(flow (~> (-< (~> condition-gate condition0) _)
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
       #'(flow (if condition0
                   consequent0
                   (switch [condition consequent]
                     ...)))]
      [(_ ((~or (~datum divert) (~datum %))
           condition-gate:clause
           consequent-gate:clause)
          [condition0:clause consequent0:clause]
          [condition:clause consequent:clause]
          ...)
       #'(flow (if (~> condition-gate condition0)
                   (~> consequent-gate consequent0)
                   (switch (divert condition-gate consequent-gate)
                     [condition consequent]
                     ...)))]))

  (define (sieve-parser stx)
    (syntax-parse stx
      [(_ condition:clause
          sonex:clause
          ronex:clause)
       #'(flow (-< (~> (pass condition) sonex)
                   (~> (pass (not condition)) ronex)))]
      [_:id
       #'(λ (condition sonex ronex . args)
           (apply (flow (-< (~> (pass condition) sonex)
                            (~> (pass (not condition)) ronex)))
                  args))]
      [(_ arg ...) ; error handling catch-all
       (report-syntax-error 'sieve
                            (syntax->datum #'(arg ...))
                            "(sieve <predicate flow> <selection flow> <remainder flow>)")]))

  (define (partition-parser stx)
    (syntax-parse stx
      [(_:id)
       #'(flow ground)]
      [(_ [cond:clause body:clause])
       #'(flow (~> (pass cond) body))]
      [(_ [cond:clause body:clause]  ...+)
       #:with c+bs #'(list (cons (flow cond) (flow body)) ...)
       #'(flow (~>> (partition-values c+bs)))]))

  (define (try-parser stx)
    (syntax-parse stx
      [(_ flo
          [error-condition-flo error-handler-flo]
          ...+)
       #'(λ args
           (with-handlers ([(flow error-condition-flo)
                            (λ (e)
                              ;; TODO: may be good to support reference to the
                              ;; error via a binding / syntax parameter
                              (apply (flow error-handler-flo) args))]
                           ...)
             (apply (flow flo) args)))]
      [(_ arg ...)
       (report-syntax-error 'try
                            (syntax->datum #'(arg ...))
                            "(try <flo> [error-predicate-flo error-handler-flo] ...)")]))

  (define (input-alias-parser stx)
    (syntax-parse stx
      [(~datum 1>)
       #'(flow (select 1))]
      [(~datum 2>)
       #'(flow (select 2))]
      [(~datum 3>)
       #'(flow (select 3))]
      [(~datum 4>)
       #'(flow (select 4))]
      [(~datum 5>)
       #'(flow (select 5))]
      [(~datum 6>)
       #'(flow (select 6))]
      [(~datum 7>)
       #'(flow (select 7))]
      [(~datum 8>)
       #'(flow (select 8))]
      [(~datum 9>)
       #'(flow (select 9))]))

  (define (if-parser stx)
    (syntax-parse stx
      [(_ consequent:clause
          alternative:clause)
       #'(λ (f . args)
           ;; the first argument is the predicate flow here
           (if (apply f args)
               (apply (flow consequent) args)
               (apply (flow alternative) args)))]
      [(_ condition:clause
          consequent:clause
          alternative:clause)
       #'(λ args
           (if (apply (flow condition) args)
               (apply (flow consequent) args)
               (apply (flow alternative) args)))]))

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
       #'(feedback-while (flow onex) (flow tilex) (flow thenex))]
      [(_ ((~datum while) tilex:clause)
          ((~datum then) thenex:clause))
       #'(λ (f . args)
           (apply (flow (feedback (while tilex) (then thenex) f))
                  args))]
      [(_ ((~datum while) tilex:clause) onex:clause)
       #'(flow (feedback (while tilex) (then _) onex))]
      [(_ ((~datum while) tilex:clause))
       #'(flow (feedback (while tilex) (then _)))]
      [(_ n:expr
          ((~datum then) thenex:clause)
          onex:clause)
       #'(feedback-times (flow onex) n (flow thenex))]
      [(_ n:expr
          ((~datum then) thenex:clause))
       #'(λ (f . args)
           (apply (flow (feedback n (then thenex) f)) args))]
      [(_ n:expr onex:clause)
       #'(flow (feedback n (then _) onex))]
      [(_ onex:clause)
       #'(λ (n . args)
           (apply (flow (feedback n onex)) args))]
      [_:id
       #'(λ (n flo . args)
           (apply (flow (feedback n flo))
                  args))]))

  (define (side-effect-parser stx)
    (syntax-parse stx
      [((~or (~datum ε) (~datum effect)) sidex:clause onex:clause)
       #'(flow (-< (~> sidex ⏚)
                   onex))]
      [((~or (~datum ε) (~datum effect)) sidex:clause)
       #'(flow (-< (~> sidex ⏚)
                   _))]))

  (define (amp-parser stx)
    (syntax-parse stx
      [(~or (~datum ><) (~datum amp))
       #'map-values]
      [((~or (~datum ><) (~datum amp)) onex:clause)
       #'(curry map-values (flow onex))]
      [((~or (~datum ><) (~datum amp)) onex0:clause onex:clause ...)
       (report-syntax-error
        'amp
        (syntax->datum #'(onex0 onex ...))
        "(>< flo)"
        "amp expects a single flow specification, but it received many.")]))

  (define (pass-parser stx)
    (syntax-parse stx
      [_:id
       #'filter-values]
      [(_ onex:clause)
       #'(curry filter-values (flow onex))]))

  (define (fold-left-parser stx)
    (syntax-parse stx
      [(~datum >>)
       #'foldl-values]
      [((~datum >>) fn init)
       #'(flow (~> (-< (gen (flow fn))
                       (gen (flow init))
                       _)
                   >>))]
      [((~datum >>) fn)
       #'(flow (>> fn (gen ((flow fn)))))]))

  (define (fold-right-parser stx)
    (syntax-parse stx
      [(~datum <<)
       #'foldr-values]
      [((~datum <<) fn init)
       #'(flow (~> (-< (gen (flow fn))
                       (gen (flow init))
                       _)
                   <<))]
      [((~datum <<) fn)
       #'(flow (<< fn (gen ((flow fn)))))]))

  (define (loop-parser stx)
    (syntax-parse stx
      [((~datum loop) pred:clause mapex:clause combex:clause retex:clause)
       #'(letrec ([loop (☯ (if pred
                               (~> (group 1 mapex loop)
                                   combex)
                               retex))])
           loop)]
      [((~datum loop) pred:clause mapex:clause combex:clause)
       #'(flow (loop pred mapex combex ⏚))]
      [((~datum loop) pred:clause mapex:clause)
       #'(flow (loop pred mapex _ ⏚))]
      [((~datum loop) mapex:clause)
       #'(flow (loop #t mapex _ ⏚))]))

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
               (flow (~> (-< _ (~> (gen args) △))
                         onex)))
           #'(λ args
               (flow (~> (-< (~> (gen args) △) _)
                         onex))))]))

  (define (literal-parser stx)
    (syntax-parse stx
      [val:literal #'(flow (gen val))]))

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
