#lang racket/base

(provide flow
         ☯
         (for-syntax subject
                     clause))

(require syntax/parse/define
         (prefix-in fancy: fancy-app)
         (only-in adjutor
                  values->list)
         racket/function
         (only-in racket/list
                  make-list)
         mischief/shorthand
         (for-syntax racket/base
                     racket/string
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
A note on error handling:

The `flow` macro specifies the forms of the DSL. Some forms, in
addition to handling legitimate syntax, also have catch-all versions
that exist purely to provide a helpful message indicating a syntax
error. We do this since a priori the macro would ignore syntax that
doesn't match the pattern. Yet, for all of these named forms, we know
that (or at least, it is prudent to assume that) the user intended to
employ that particular form of the DSL. So instead of allowing it to
fall through for interpretation as Racket code, which would yield
potentially inscrutable errors, the catch-all forms allow us to
provide appropriate error messages at the level of the DSL.

|#

(define-syntax-parser flow

  ;; Check first whether the form is a macro. If it is, expand it.
  ;; This is prioritized over other forms so that extensions may
  ;; override built-in Qi forms.
  [(_ stx)
   #:with (~or (m:id expr ...) m:id) #'stx
   #:do [(define space-m ((make-interned-syntax-introducer 'qi) #'m))
         (define threading-side (syntax-property this-syntax 'threading-side))]
   #:when (qi-macro? (syntax-local-value space-m (λ () #f)))
   #:with expanded (syntax-local-apply-transformer
                    (qi-macro-transformer (syntax-local-value space-m))
                    space-m
                    'expression
                    #f
                    ;; propagate the side on which arguments are to
                    ;; be threaded, so that foreign macro expansion
                    ;; is aware of it.
                    (syntax-property #'stx 'threading-side threading-side))
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
  [(_ (~or (~datum NOT) (~datum !)))
   #'not]
  [(_ (~or (~datum AND) (~datum &)))
   #'all?]
  [(_ (~or (~datum OR) (~datum ∥)))
   #'any?]
  [(_ (~datum NOR))
   #'(flow (~> OR NOT))]
  [(_ (~datum NAND))
   #'(flow (~> AND NOT))]
  [(_ (~datum XOR))
   #'parity-xor]
  [(_ (~datum XNOR))
   #'(flow (~> XOR NOT))]
  [(_ ((~datum and%) expr ...))
   #'(and%-parser expr ...)]
  [(_ ((~datum or%) expr ...))
   #'(or%-parser expr ...)]
  [(_ (~datum any?)) #'any?]
  [(_ (~datum all?)) #'all?]
  [(_ (~datum none?)) #'none?]
  [(_ (~or (~datum ▽) (~datum collect)))
   #'list]
  [(_ e:sep-form) (sep-parser #'e)]

  ;;; Core routing elements

  [(_ (~or (~datum ⏚) (~datum ground)))
   #'(flow (select))]
  [(_ ((~or (~datum ~>) (~datum thread)) onex:clause ...))
   (datum->syntax this-syntax
     (cons 'compose
           (reverse
            (syntax->list
             #'((flow onex) ...)))))]
  [(_ ((~or (~datum ~>>) (~datum thread-right)) onex:clause ...))
   #'(flow (~> (esc (right-threading-clause onex)) ...))]
  [(_ (~or (~datum X) (~datum crossover)))
   #'(flow (~> ▽ reverse △))]
  [(_ ((~or (~datum ==) (~datum relay)) onex:clause ...))
   #'(relay (flow onex) ...)]
  [(_ ((~or (~datum ==*) (~datum relay*)) onex:clause ... rest-onex:clause))
   (with-syntax ([len (datum->syntax this-syntax
                        (length (syntax->list #'(onex ...))))])
     #'(flow (group len (== onex ...) rest-onex) ))]
  [(_ ((~or (~datum -<) (~datum tee)) onex:clause ...))
   #'(λ args
       (apply values
              (append (values->list
                       (apply (flow onex) args))
                      ...)))]
  [(_ ((~datum select) n:number ...))
   #'(flow (-< (esc (arg n)) ...))]
  [(_ ((~datum select) arg ...))  ; error handling catch-all
   (report-syntax-error 'select
                        (syntax->datum #'(arg ...))
                        "(select <number> ...)")]
  [(_ ((~datum block) n:number ...))
   #'(flow (~> (esc (except-args n ...))
               △))]
  [(_ ((~datum block) arg ...))  ; error handling catch-all
   (report-syntax-error 'block
                        (syntax->datum #'(arg ...))
                        "(block <number> ...)")]
  [(_ ((~datum bundle) (n:number ...)
                       selection-onex:clause
                       remainder-onex:clause))
   #'(flow (-< (~> (select n ...) selection-onex)
               (~> (block n ...) remainder-onex)))]
  [(_ e:group-form) (group-parser #'e)]

  ;;; Conditionals

  [(_ e:if-form) (if-parser #'e)]
  [(_ ((~datum when) condition:clause
                     consequent:clause))
   #'(flow (if condition consequent ⏚))]
  [(_ ((~datum unless) condition:clause
                       alternative:clause))
   #'(flow (if condition ⏚ alternative))]
  [(_ e:switch-form) (switch-parser #'e)]
  [(_ e:sieve-form) (sieve-parser #'e)]
  [(_ ({~datum partition}))
   #'(flow ground)]
  [(_ ({~datum partition} [cond:clause body:clause]))
   #'(flow (~> (pass cond) body))]
  [(_ ({~datum partition} [cond:clause body:clause]  ...+))
   #:with c+bs #'(list (cons (flow cond) (flow body)) ...)
   #'(flow (~>> (partition-values c+bs)))]
  [(_ ((~datum gate) onex:clause))
   #'(flow (if onex _ ⏚))]

  ;;; Exceptions

  [(_ e:try-form) (try-parser #'e)]

  ;;; High level circuit elements

  ;; aliases for inputs
  [(_ e:input-alias) (input-alias-parser #'e)]

  ;; common utilities
  [(_ (~datum count))
   #'(λ args (length args))]
  [(_ (~datum live?))
   #'(λ args (not (null? args)))]
  [(_ ((~datum rectify) v:expr ...))
   #'(flow (if live? _ (gen v ...)))]

  ;; high level routing
  [(_ e:fanout-form) (fanout-parser #'e)]
  [(_ e:feedback-form) (feedback-parser #'e)]
  [(_ (~datum inverter))
   #'(flow (>< NOT))]
  [(_ e:side-effect-form) (side-effect-parser #'e)]

  ;;; Higher-order flows

  ;; map, filter, and fold
  [(_ e:amp-form) (amp-parser #'e)]
  [(_ e:pass-form) (pass-parser #'e)]
  [(_ e:fold-left-form) (fold-left-parser #'e)]
  [(_ e:fold-right-form) (fold-right-parser #'e)]

  ;; looping
  [(_ e:loop-form) (loop-parser #'e)]
  [(_ ((~datum loop2) pred:clause mapex:clause combex:clause))
   #'(letrec ([loop2 (☯ (if pred
                            (~> (== (-< cdr
                                        (~> car mapex)) _)
                                (group 1 _ combex)
                                loop2)
                            2>))])
       loop2)]

  ;; towards universality
  [(_ (~datum apply))
   #'call]
  [(_ ((~datum clos) flo:clause))
   #:do [(define threading-side (syntax-property this-syntax 'threading-side))]
   (if (and threading-side (eq? threading-side 'right))
       #'(λ args
           (flow (~> (-< _ (~> (gen args) △))
                     flo)))
       #'(λ args
           (flow (~> (-< (~> (gen args) △) _)
                     flo))))]

  ;;; Miscellaneous

  ;; escape hatch for racket expressions or anything
  ;; to be "passed through"
  [(_ ((~datum esc) ex:expr))
   #'ex]

  ;; backwards compat macro extensibility via Racket macros
  [(_ ((~var ext-form (starts-with "qi:")) expr ...))
   #'(ext-form expr ...)]

  ;; a literal is interpreted as a flow generating it
  [(_ val:literal) #'(flow (gen val))]

  ;; We'd like to treat quoted forms as literals as well.
  ;; This includes symbols, and would also include, for instance, syntactic
  ;; specifications of flows, since flows are syntactically lists as
  ;; they inherit the elementary syntax of the underlying language (Racket).
  ;; Quoted forms are read as (quote ...), so we match against this
  [(_ ((~datum quote) val)) #'(flow (gen 'val))]
  [(_ ((~datum quasiquote) val)) #'(flow (gen `val))]
  [(_ ((~datum quote-syntax) val)) #'(flow (gen (quote-syntax val)))]
  [(_ ((~datum syntax) val)) #'(flow (gen (syntax val)))]

  ;; Partial application with syntactically pre-supplied arguments
  ;; in a simple template
  ;; "prarg" = "pre-supplied argument"
  [(_ (natex prarg-pre ...+ (~datum __) prarg-post ...+))
   #'(curry (curryr natex
                    prarg-post ...)
            prarg-pre ...)]
  [(_ (natex prarg-pre ...+ (~datum __)))
   #'(curry natex prarg-pre ...)]
  [(_ (natex (~datum __) prarg-post ...+))
   #'(curryr natex prarg-post ...)]
  [(_ (natex (~datum __)))
   #'natex]

  ;; Fine-grained template-based application
  ;; This handles templates that indicate a specific number of template
  ;; variables (i.e. expected arguments). The semantics of template-based
  ;; application here is fulfilled by the fancy-app module. In order to use
  ;; it, we simply use the #%app macro provided by fancy-app instead of the
  ;; implicit one used for function application in racket/base.
  [(_ (natex prarg-pre ... (~datum _) prarg-post ...))
   #'(fancy:#%app natex prarg-pre ...
                  _
                  prarg-post ...)]

  ;; Pre-supplied arguments without a template
  [(_ (natex prarg ...+))
   ;; we use currying instead of templates when a template hasn't
   ;; explicitly been indicated since in such cases, we cannot
   ;; always infer the appropriate arity for a template (e.g. it
   ;; may change under composition within the form), while a
   ;; curried function will accept any number of arguments
   #:do [(define threading-side (syntax-property this-syntax 'threading-side))]
   (if (and threading-side (eq? threading-side 'right))
       #'(curry natex prarg ...)
       #'(curryr natex prarg ...))]

  ;; pass-through (identity flow)
  [(_ (~datum _)) #'values]

  ;; literally indicated function identifier
  [(_ natex:expr) #'natex]

  ;; a non-flow
  [(_) #'values]

  [(flow expr0 expr ...+)  ; error handling catch-all
   (report-syntax-error
    'flow
    (syntax->datum #'(expr0 expr ...))
    "(flow flo)"
    "flow expects a single flow specification, but it received many.")])

(define-syntax-parser right-threading-clause
  [(_ onex:clause)
   (datum->syntax this-syntax
     (list 'flow #'onex)
     #f
     (syntax-property this-syntax 'threading-side 'right))])

(define-syntax-parser conjux-clause  ; "juxtaposed" conjoin
  [(_ (~datum _)) #'true.]
  [(_ onex:clause) #'(flow onex)])

(define-syntax-parser disjux-clause  ; "juxtaposed" disjoin
  [(_ (~datum _)) #'false.]
  [(_ onex:clause) #'(flow onex)])

(define-syntax-parser and%-parser
  [(_ onex:clause ...)
   #'(flow (~> (== (esc (conjux-clause onex)) ...)
               all?))])

(define-syntax-parser or%-parser
  [(_ onex:clause ...)
   #'(flow (~> (== (esc (disjux-clause onex)) ...)
               any?))])

(begin-for-syntax

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
       ;; we split the flow ahead of time to avoid evaluating
       ;; the condition more than once
       #'(flow (~> (-< (~> condition-gate condition0) _)
                   (if 1>
                       (~> consequent-gate consequent0 ...)
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
       #'(λ args
           ;; the first argument is the predicate flow here
           (if (apply (car args) (cdr args))
               (apply (flow consequent) (cdr args))
               (apply (flow alternative) (cdr args))))]
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
       #'(letrec ([loop (☯ (~> (if tilex
                                   (~> onex loop)
                                   thenex)))])
           loop)]
      [(_ ((~datum while) tilex:clause) onex:clause)
       #'(flow (feedback (while tilex) (then _) onex))]
      [(_ n:expr
          ((~datum then) thenex:clause)
          onex:clause)
       #'(flow (~> (esc (power n (flow onex))) thenex))]
      [(_ n:expr onex:clause)
       #'(flow (feedback n (then _) onex))]
      [_:id
       #'(letrec ([loop (☯ (~> (if (~> (-< 1> (block 1 2 3)) apply)
                                   (~> (-< (select 1 2 3)
                                           (~> (block 1 2)
                                               apply))
                                       loop)
                                   (~> (-< 2> (block 1 2 3))
                                       apply))))])
           loop)]))

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
       #'(flow (~> (-< (gen (flow fn)) (gen (flow init)) _) >>))]
      [((~datum >>) fn)
       #'(flow (>> fn (gen ((flow fn)))))]))

  (define (fold-right-parser stx)
    (syntax-parse stx
      [(~datum <<)
       #'foldr-values]
      [((~datum <<) fn init)
       #'(flow (~> (-< (gen (flow fn)) (gen (flow init)) _) <<))]
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
       #'(flow (loop #t mapex _ ⏚))])))
