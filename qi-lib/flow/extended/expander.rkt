#lang racket/base

(provide (for-syntax qi-macro
                     closed-floe)
         (for-space qi
                    (all-defined-out)
                    (rename-out [ground ⏚]
                                [thread ~>]
                                [relay ==]
                                [tee -<]
                                [amp ><]
                                [sep △]
                                [collect ▽])))

(require syntax-spec-v1
         (for-syntax "../aux-syntax.rkt"
                     "syntax.rkt"
                     racket/base
                     syntax/parse
                     "../../private/util.rkt"))

(syntax-spec

  ;; Declare a compile-time datatype by which qi macros may
  ;; be identified.
  (extension-class qi-macro
                   #:binding-space qi)

  (nonterminal closed-floe
    #:description "a flow expression"

    f:floe
    #:binding (nest-one f []))

  (nonterminal/nesting floe (nested)
    #:description "a flow expression"
    #:allow-extension qi-macro
    #:binding-space qi

    (as v:racket-var ...+)
    #:binding {(bind v) nested}

    (thread f:floe ...)
    #:binding (nest f nested)

    (tee f:floe ...)
    #:binding (nest f nested)
    tee
    ;; Note: `#:binding nested` is the implicit binding rule here

    (relay f:floe ...)
    #:binding (nest f nested)
    relay

    ;; [f nested] is the implicit binding rule
    ;; anything not mentioned (e.g. nested) is treated as a
    ;; subexpression that's not in any scope
    ;; Note: once a nonterminal is chosen, it doesn't backtrack
    ;; to consider alternatives

    (gen e:racket-expr ...)
    ;; Ad hoc expansion rule to allow _ to be used in application
    ;; position in a template.
    ;; Without it, (_ v ...) would be treated as an error since
    ;; _ is an unrelated form of the core language having different
    ;; semantics. The expander would assume it is a syntax error
    ;; from that perspective.
    (~> ((~literal _) arg ...) #'(#%fine-template (_ arg ...)))
    _
    ground
    amp
    (amp f:closed-floe)
    (~>/form (amp f0:clause f:clause ...)
             ;; potentially pull out as a phase 1 function
             ;; just a stopgap until better error messages
             (report-syntax-error this-syntax
               "(>< flo)"
               "amp expects a single flow specification, but it received many."))
    pass
    (pass f:closed-floe)
    sep
    (sep f:closed-floe)
    collect
    NOT
    XOR
    (and f:closed-floe ...)
    (or f:closed-floe ...)
    (not f:closed-floe)
    (all f:closed-floe)
    (any f:closed-floe)
    (select n:number ...)
    (~>/form (select arg ...)
             (report-syntax-error this-syntax
               "(select <number> ...)"))
    (block n:number ...)
    (~>/form (block arg ...)
             (report-syntax-error this-syntax
               "(block <number> ...)"))
    (fanout n:number)
    (fanout n:racket-expr)
    fanout
    (group n:racket-expr e1:closed-floe e2:closed-floe)
    group
    (~>/form (group arg ...)
             (report-syntax-error this-syntax
               "(group <number> <selection flow> <remainder flow>)"))
    (if consequent:closed-floe
        alternative:closed-floe)
    (if condition:floe
        consequent:closed-floe
        alternative:closed-floe)
    #:binding (nest-one condition [consequent alternative])
    (sieve condition:closed-floe
           sonex:closed-floe
           ronex:closed-floe)
    sieve
    (~>/form (sieve arg ...)
             (report-syntax-error this-syntax
               "(sieve <predicate flow> <selection flow> <remainder flow>)"))
    (partition)
    (partition [cond:closed-floe body:closed-floe] ...+)
    (try flo:closed-floe
      [error-condition-flo:closed-floe error-handler-flo:closed-floe]
      ...+)
    (~>/form (try arg ...)
             (report-syntax-error this-syntax
               "(try <flo> [error-predicate-flo error-handler-flo] ...)"))
    >>
    (>> fn:closed-floe init:closed-floe)
    (>> fn:closed-floe)
    <<
    (<< fn:closed-floe init:closed-floe)
    (<< fn:closed-floe)
    (feedback ((~datum while) tilex:closed-floe)
              ((~datum then) thenex:closed-floe)
              onex:closed-floe)
    (feedback ((~datum while) tilex:closed-floe)
              ((~datum then) thenex:closed-floe))
    (feedback ((~datum while) tilex:closed-floe) onex:closed-floe)
    (feedback ((~datum while) tilex:closed-floe))
    (feedback n:racket-expr
              ((~datum then) thenex:closed-floe)
              onex:closed-floe)
    (feedback n:racket-expr
              ((~datum then) thenex:closed-floe))
    (feedback n:racket-expr onex:closed-floe)
    (feedback onex:closed-floe)
    feedback
    (loop pred:closed-floe mapex:closed-floe combex:closed-floe retex:closed-floe)
    (loop pred:closed-floe mapex:closed-floe combex:closed-floe)
    (loop pred:closed-floe mapex:closed-floe)
    (loop mapex:closed-floe)
    loop
    (loop2 pred:closed-floe mapex:closed-floe combex:closed-floe)
    appleye
    (~> (~literal apply) #'appleye)
    clos
    (clos onex:closed-floe)
    (esc ex:racket-expr)

    ;; backwards compat macro extensibility via Racket macros
    (~> ((~var ext-form (starts-with "qi:")) expr ...)
        #'(esc (ext-form expr ...)))
    ;; a literal is interpreted as a flow generating it
    (~> val:literal
        #'(gen val))
    ;; Certain rules of the language aren't determined by the "head"
    ;; position, so naively, these can't be core forms. In order to
    ;; treat them as core forms, we tag them at the expander level
    ;; by wrapping them with #%-prefixed forms, similar to Racket's
    ;; approach to a similiar case - "interposition points." These
    ;; new forms can then be treated as core forms in the compiler.
    ;;
    ;; Be careful with these tagging rules, though -- if they are too
    ;; lax in their match criteria they may produce infinite code
    ;; unless their output is matched prior to reaching the tagging rule.
    ;; So core forms expected to be produced by these tagging rules
    ;; should generally occur before the tagging rule
    (#%blanket-template (arg:arg-stx ...))
    (~> f:blanket-template-form
        #'(#%blanket-template f))

    (#%fine-template (arg:arg-stx ...))
    (~> f:fine-template-form
        #'(#%fine-template f))

    ;; When there is a partial application where a template hasn't
    ;; explicitly been indicated, we rewrite it to an equivalent use
    ;; of a blanket template.
    ;; We use a blanket rather than fine template since in such cases,
    ;; we cannot always infer the appropriate arity for a template
    ;; (e.g. it may change under composition within the form), while a
    ;; blanket template will accept any number of arguments
    (~> f:partial-application-form
        #:do [(define chirality (syntax-property this-syntax 'chirality))]
        (if (and chirality (eq? chirality 'right))
            (datum->syntax this-syntax
              (append (syntax->list this-syntax)
                      (list '__)))
            (datum->syntax this-syntax
              (let ([stx-list (syntax->list this-syntax)])
                (cons (car stx-list)
                      (cons '__ (cdr stx-list)))))))
    ;; literally indicated function identifier
    ;;
    ;; functions defined in the Qi binding space take precedence over
    ;; Racket definitions here, for cases of "library functions" like
    ;; `count` that we don't include in the core language but which
    ;; we'd like to treat as part of the language rather than as
    ;; functions which could be shadowed.
    (~> f:id
        #:with spaced-f ((make-interned-syntax-introducer 'qi) #'f)
        #'(esc spaced-f)))

  (nonterminal arg-stx
    (~datum _)
    (~datum __)
    k:keyword

    e:racket-expr))
