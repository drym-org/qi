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
                                [collect ▽]
                                [NOT !])))

(require syntax-spec-v3
         "../space.rkt"
         (for-syntax "../aux-syntax.rkt"
                     "syntax.rkt"
                     racket/base
                     syntax/parse
                     "../../private/util.rkt"))

#|
This module implements the Qi expander using Syntax Spec.  Here, we
notate the core language grammar from which Syntax Spec infers and
constructs an appropriate expander.  As part of this, we annotate the
grammar with binding scope rules (e.g. for the `as` form) which allows
the expander to propagate scope in accordance with these specified
rules and also raise errors at compile time when identifiers used are
unbound.

In addition to the core language grammar and scoping rules, we also
specify a few ad hoc expansion rules here (via Syntax Spec "rewrite
productions") in order to expand surface syntax that may not be neatly
expressible as a macro to an appropriate use of a core form. Such
rules are necessary so that the core language can be uniformly
expressed in terms of such prefix forms (it's similar to the Racket
core language's use of #%app, etc.).
|#

(syntax-spec

  ;; Declare a compile-time datatype by which qi macros may
  ;; be identified.
  (extension-class qi-macro
                   #:binding-space qi)

  (nonterminal closed-floe
    #:description "a flow expression"

    f:floe
    #:binding (nest f []))

  ;; "floe" stands for "FLOw Expression" and is a _nonterminal_ that
  ;; expresses valid syntax for Qi expressions. It's analogous
  ;; to `expr` for Racket expressions (e.g. as used in syntax-parse).
  ;; Not to be confused with `flow` which is a Racket _form_
  ;; that extends Racket syntax by introducing a `floe` position
  ;; whose expansion is specified here.
  (nonterminal/nesting floe (nested)
    #:description "a flow expression"
    #:allow-extension qi-macro
    #:binding-space qi

    (as v:racket-var ...+)
    #:binding (scope (bind v) ... nested)

    (thread f:floe ...)
    #:binding (nest f ... nested)

    (~>/form (tee f ...)
             #:when (eq? 'right (syntax-property this-syntax 'chirality))
             #:with (ff ...) (map make-right-chiral (syntax->list #'(f ...)))
             (syntax-property #'(tee ff ...) 'chirality 'wrong))
    (tee f:floe ...)
    #:binding (nest f ... nested)
    tee
    ;; Note: `#:binding nested` is the implicit binding rule here

    (~>/form (relay f ...)
             #:when (eq? 'right (syntax-property this-syntax 'chirality))
             #:with (ff ...) (map make-right-chiral (syntax->list #'(f ...)))
             (syntax-property #'(relay ff ...) 'chirality 'wrong))
    (relay f:floe ...)
    #:binding (nest f ... nested)
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
    (~>/form (amp f)
             #:when (eq? 'right (syntax-property this-syntax 'chirality))
             #:with ff (make-right-chiral #'f)
             (syntax-property #'(amp ff) 'chirality 'wrong))
    amp
    (amp f:closed-floe)
    (~>/form (amp f0:clause f:clause ...)
             ;; potentially pull out as a phase 1 function
             ;; just a stopgap until better error messages
             (report-syntax-error this-syntax
               "(>< flo)"
               "amp expects a single flow specification, but it received many."))
    (~>/form (pass f)
             #:when (eq? 'right (syntax-property this-syntax 'chirality))
             #:with ff (make-right-chiral #'f)
             (syntax-property #'(pass ff) 'chirality 'wrong))
    pass
    (pass f:closed-floe)
    (~>/form (sep f)
             #:when (eq? 'right (syntax-property this-syntax 'chirality))
             #:with ff (make-right-chiral #'f)
             (syntax-property #'(sep ff) 'chirality 'wrong))
    sep
    (sep f:closed-floe)
    collect
    NOT
    XOR
    (~>/form (and f ...)
             #:when (eq? 'right (syntax-property this-syntax 'chirality))
             #:with (ff ...) (map make-right-chiral (syntax->list #'(f ...)))
             (syntax-property #'(and ff ...) 'chirality 'wrong))
    (and f:closed-floe ...)
    (~>/form (or f ...)
             #:when (eq? 'right (syntax-property this-syntax 'chirality))
             #:with (ff ...) (map make-right-chiral (syntax->list #'(f ...)))
             (syntax-property #'(or ff ...) 'chirality 'wrong))
    (or f:closed-floe ...)
    (~>/form (not f)
             #:when (eq? 'right (syntax-property this-syntax 'chirality))
             #:with ff (make-right-chiral #'f)
             (syntax-property #'(not ff) 'chirality 'wrong))
    (not f:floe)
    #:binding (nest f nested)
    (~>/form (all f)
             #:when (eq? 'right (syntax-property this-syntax 'chirality))
             #:with ff (make-right-chiral #'f)
             (syntax-property #'(all ff) 'chirality 'wrong))
    (all f:closed-floe)
    (~>/form (any f)
             #:when (eq? 'right (syntax-property this-syntax 'chirality))
             #:with ff (make-right-chiral #'f)
             (syntax-property #'(any ff) 'chirality 'wrong))
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
    (~>/form (group n f1 f2)
             #:when (eq? 'right (syntax-property this-syntax 'chirality))
             #:with ff1 (make-right-chiral #'f1)
             #:with ff2 (make-right-chiral #'f2)
             (syntax-property #'(group n ff1 ff2) 'chirality 'wrong))
    (group n:racket-expr e1:floe e2:floe)
    #:binding (nest e1 e2 nested)
    group
    (~>/form (group arg ...)
             (report-syntax-error this-syntax
               "(group <number> <selection flow> <remainder flow>)"))
    (~>/form (if f ...)
             #:when (eq? 'right (syntax-property this-syntax 'chirality))
             #:with (ff ...) (map make-right-chiral (syntax->list #'(f ...)))
             (syntax-property #'(if ff ...) 'chirality 'wrong))
    (if consequent:closed-floe
        alternative:closed-floe)
    (if condition:floe
        consequent:closed-floe
        alternative:closed-floe)
    #:binding (nest condition [consequent alternative nested])
    (~>/form (sieve f ...)
             #:when (eq? 'right (syntax-property this-syntax 'chirality))
             #:with (ff ...) (map make-right-chiral (syntax->list #'(f ...)))
             (syntax-property #'(sieve ff ...) 'chirality 'wrong))
    (sieve condition:closed-floe
           sonex:closed-floe
           ronex:closed-floe)
    sieve
    (~>/form (sieve arg ...)
             (report-syntax-error this-syntax
               "(sieve <predicate flow> <selection flow> <remainder flow>)"))
    (~>/form (partition [f g] ...)
             #:when (eq? 'right (syntax-property this-syntax 'chirality))
             #:with (ff ...) (map make-right-chiral (syntax->list #'(f ...)))
             #:with (gg ...) (map make-right-chiral (syntax->list #'(g ...)))
             (syntax-property #'(partition [ff gg] ...) 'chirality 'wrong))
    (partition)
    (partition [cond:closed-floe body:closed-floe] ...+)
    (~>/form (try f [e h] ...)
             #:when (eq? 'right (syntax-property this-syntax 'chirality))
             #:with ff (make-right-chiral #'f)
             #:with (ee ...) (map make-right-chiral (syntax->list #'(e ...)))
             #:with (hh ...) (map make-right-chiral (syntax->list #'(h ...)))
             (syntax-property #'(try ff [ee hh] ...) 'chirality 'wrong))
    (try flo:closed-floe
      [error-condition-flo:closed-floe error-handler-flo:closed-floe]
      ...+)
    (~>/form (try arg ...)
             (report-syntax-error this-syntax
               "(try <flo> [error-predicate-flo error-handler-flo] ...)"))
    (~>/form (>> f ...)
             #:when (eq? 'right (syntax-property this-syntax 'chirality))
             #:with (ff ...) (map make-right-chiral (syntax->list #'(f ...)))
             (syntax-property #'(>> ff ...) 'chirality 'wrong))
    >>
    (>> fn:closed-floe init:closed-floe)
    (>> fn:closed-floe)
    (~>/form (<< f ...)
             #:when (eq? 'right (syntax-property this-syntax 'chirality))
             #:with (ff ...) (map make-right-chiral (syntax->list #'(f ...)))
             (syntax-property #'(<< ff ...) 'chirality 'wrong))
    <<
    (<< fn:closed-floe init:closed-floe)
    (<< fn:closed-floe)
    (~>/form (feedback (p f) ... g)
             #:when (eq? 'right (syntax-property this-syntax 'chirality))
             #:with (ff ...) (map make-right-chiral (syntax->list #'(f ...)))
             #:with gg (make-right-chiral #'g)
             (syntax-property #'(feedback (p ff) ... gg) 'chirality 'wrong))
    (~>/form (feedback n:number (p f) ... g)
             #:when (eq? 'right (syntax-property this-syntax 'chirality))
             #:with (ff ...) (map make-right-chiral (syntax->list #'(f ...)))
             #:with gg (make-right-chiral #'g)
             (syntax-property #'(feedback n (p ff) ... gg) 'chirality 'wrong))
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
    (~>/form (loop f ...)
             #:when (eq? 'right (syntax-property this-syntax 'chirality))
             #:with (ff ...) (map make-right-chiral (syntax->list #'(f ...)))
             (syntax-property #'(loop ff ...) 'chirality 'wrong))
    (loop pred:closed-floe mapex:closed-floe combex:closed-floe retex:closed-floe)
    (loop pred:closed-floe mapex:closed-floe combex:closed-floe)
    (loop pred:closed-floe mapex:closed-floe)
    (loop mapex:closed-floe)
    loop
    (~>/form (loop2 f ...)
             #:when (eq? 'right (syntax-property this-syntax 'chirality))
             #:with (ff ...) (map make-right-chiral (syntax->list #'(f ...)))
             (syntax-property #'(loop2 ff ...) 'chirality 'wrong))
    (loop2 pred:closed-floe mapex:closed-floe combex:closed-floe)
    appleye
    (~> (~literal apply) #'appleye)
    clos
    (clos onex:closed-floe)
    (esc ex:racket-expr)
    (~> ((~literal lambda) e ...)
        #'(esc (lambda e ...)))
    (~> ((~literal λ) e ...)
        #'(lambda e ...))

    ;; core form to express deforestable operations
    (#%deforestable name:id info:id e:deforestable-clause ...)

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
    (~> ((~datum __) _e ...) (report-syntax-error this-syntax
                               "(f pre-arg ... __ post-arg ...)"))

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
        #:with spaced-f (introduce-qi-syntax #'f)
        #'(esc spaced-f)))

  (nonterminal deforestable-clause
    ((~datum floe) e:closed-floe)
    ((~datum expr) g:racket-expr)
    ((~datum const) g:racket-expr))

  (nonterminal arg-stx
    (~datum _)
    (~datum __)
    k:keyword

    e:racket-expr))


(module+ invoke
  (provide (for-syntax expand-flow))

  (begin-for-syntax
    (define (expand-flow stx)
      ((nonterminal-expander closed-floe) stx))))
