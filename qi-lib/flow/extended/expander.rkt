#lang racket/base

(provide (for-syntax qi-macro
                     floe)
         (for-space qi
                    (all-defined-out)
                    (rename-out [ground ⏚]
                                [thread ~>]
                                [relay ==]
                                [tee -<]
                                [amp ><]
                                [sep △]
                                [collect ▽])))

(require syntax-spec
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

  (nonterminal floe
    #:description "a flow expression"

    f:threading-floe
    #:binding (nest-one f []))

  (nonterminal/nesting binding-floe (nested)
    #:description "a flow expression"
    #:allow-extension qi-macro
    #:binding-space qi

    (as v:racket-var ...+)
    #:binding {(bind v) nested}

    f:threading-floe
    #:binding (nest-one f nested))

  (nonterminal/nesting threading-floe (nested)
    #:description "a flow expression"
    #:allow-extension qi-macro
    #:binding-space qi

    (thread f:binding-floe ...)
    #:binding (nest f nested)

    (tee f:binding-floe ...)
    #:binding (nest f nested)
    tee
    ;; Note: `#:binding nested` is the implicit binding rule here

    (relay f:binding-floe ...)
    #:binding (nest f nested)
    relay

    ;; [f nested] is the implicit binding rule
    ;; anything not mentioned (e.g. nested) is treated as a
    ;; subexpression that's not in any scope
    ;; Note: this could be at the top level floe after
    ;; binding-floe, but that isnt supported atm because
    ;; it doesn't backtrack
    _:simple-floe)

  (nonterminal simple-floe
    #:description "a flow expression"
    #:binding-space qi

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
    (amp f:floe)
    (~>/form (amp f0:clause f:clause ...)
             ;; potentially pull out as a phase 1 function
             ;; just a stopgap until better error messages
             (report-syntax-error this-syntax
               "(>< flo)"
               "amp expects a single flow specification, but it received many."))
    pass
    (pass f:floe)
    sep
    (sep f:floe)
    collect
    NOT
    XOR
    (and f:floe ...)
    (or f:floe ...)
    (not f:floe)
    (all f:floe)
    (any f:floe)
    (select n:number ...)
    (~>/form (select arg ...)
             (report-syntax-error this-syntax
               "(select <number> ...)"))
    (block n:number ...)
    (~>/form (block arg ...)
             (report-syntax-error this-syntax
               "(block <number> ...)"))
    (group n:racket-expr e1:floe e2:floe)
    group
    (~>/form (group arg ...)
             (report-syntax-error this-syntax
               "(group <number> <selection flow> <remainder flow>)"))
    (if consequent:floe
        alternative:floe)
    (if condition:floe
        consequent:floe
        alternative:floe)
    (sieve condition:floe
           sonex:floe
           ronex:floe)
    sieve
    (~>/form (sieve arg ...)
             (report-syntax-error this-syntax
               "(sieve <predicate flow> <selection flow> <remainder flow>)"))
    (try flo:floe
      [error-condition-flo:floe error-handler-flo:floe]
      ...+)
    (~>/form (try arg ...)
             (report-syntax-error this-syntax
               "(try <flo> [error-predicate-flo error-handler-flo] ...)"))
    >>
    (>> fn:floe init:floe)
    (>> fn:floe)
    <<
    (<< fn:floe init:floe)
    (<< fn:floe)
    (feedback ((~datum while) tilex:floe)
              ((~datum then) thenex:floe)
              onex:floe)
    (feedback ((~datum while) tilex:floe)
              ((~datum then) thenex:floe))
    (feedback ((~datum while) tilex:floe) onex:floe)
    (feedback ((~datum while) tilex:floe))
    (feedback n:racket-expr
              ((~datum then) thenex:floe)
              onex:floe)
    (feedback n:racket-expr
              ((~datum then) thenex:floe))
    (feedback n:racket-expr onex:floe)
    (feedback onex:floe)
    feedback
    (loop pred:floe mapex:floe combex:floe retex:floe)
    (loop pred:floe mapex:floe combex:floe)
    (loop pred:floe mapex:floe)
    (loop mapex:floe)
    loop
    (loop2 pred:floe mapex:floe combex:floe)
    appleye
    (~> (~literal apply) #'appleye)
    clos
    (clos onex:floe)
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
    (~> f:blanket-template-form
        #'(#%blanket-template f))

    (#%blanket-template (arg:arg-stx ...))

    (~> f:fine-template-form
        #'(#%fine-template f))
    (#%fine-template (arg:arg-stx ...))

    ;; The core rule must come before the tagging rule here since
    ;; the former as a production of the latter would still match
    ;; the latter (i.e. it is still a parenthesized expression),
    ;; which would lead to infinite code generation.
    (#%partial-application (arg:arg-stx ...))

    (~> f:partial-application-form
        #'(#%partial-application f))
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
