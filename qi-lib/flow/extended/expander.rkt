#lang racket/base

(provide (for-syntax expand-flow
                     qi-macro)
         (for-space qi
                    (all-defined-out)
                    (rename-out [ground ⏚]
                                [thread ~>]
                                [relay ==]
                                [tee -<]
                                [amp ><]
                                [sep △]
                                [collect ▽])))

(require bindingspec
         (for-syntax "../aux-syntax.rkt"
                     "syntax.rkt"
                     racket/base
                     syntax/parse
                     "../../private/util.rkt"))

(define-hosted-syntaxes
  ;; Declare a compile-time datatype by which qi macros may
  ;; be identified.
  (extension-class qi-macro
                   #:binding-space qi)
  (nonterminal floe
               ;; Check first whether the form is a macro. If it is, expand it.
               ;; This is prioritized over other forms so that extensions may
               ;; override built-in Qi forms.
               #:allow-extension qi-macro
               #:binding-space qi
               (gen e:expr ...)
               ;; Ad hoc expansion rule to allow _ to be used in application
               ;; position in a template.
               ;; Without it, (_ v ...) would be treated as an error since
               ;; _ is an unrelated form of the core language having different
               ;; semantics. The expander would assume it is a syntax error
               ;; from that perspective.
               (~> ((~literal _) arg ...) #'(#%fine-template (_ arg ...)))
               _
               ground
               (thread f:floe ...)
               (relay f:floe ...)
               relay
               (tee f:floe ...)
               tee
               amp
               (amp f:floe)
               (~>/form (amp f0:clause f:clause ...)
                        ;; potentially pull out as a phase 1 function
                        ;; just a stopgap until better error messages
                        (report-syntax-error
                         this-syntax
                         "(>< flo)"
                         "amp expects a single flow specification, but it received many."))
               pass
               (pass f:floe)
               sep
               (sep f:floe)
               collect
               AND
               OR
               NOT
               XOR
               (and f:floe ...)
               (or f:floe ...)
               (not f:floe)
               (select e:expr ...)
               (~>/form (select arg ...)
                        (report-syntax-error this-syntax
                                             "(select <number> ...)"))
               (block e:expr ...)
               (~>/form (block arg ...)
                        (report-syntax-error this-syntax
                                             "(block <number> ...)"))
               (group n:expr e1:floe e2:floe)
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
               (feedback n:expr
                         ((~datum then) thenex:floe)
                         onex:floe)
               (feedback n:expr
                         ((~datum then) thenex:floe))
               (feedback n:expr onex:floe)
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
               (esc ex:expr)
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
               (#%blanket-template (arg:any-stx ...))
               (~> f:fine-template-form
                   #'(#%fine-template f))
               (#%fine-template (arg:any-stx ...))
               ;; The core rule must come before the tagging rule here since
               ;; the former as a production of the latter would still match
               ;; the latter (i.e. it is still a parenthesized expression),
               ;; which would lead to infinite code generation.
               (#%partial-application (arg:any-stx ...))
               (~> f:partial-application-form
                   #'(#%partial-application f))
               ;; literally indicated function identifier
               ;; TODO: make this id rather than expr once
               ;; everything else is stable
               (~> f:expr #'(esc f))))

(begin-for-syntax
  (define (expand-flow stx)
    ((nonterminal-expander floe) stx)))
