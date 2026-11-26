#lang racket/base

(provide flow
         ☯
         (all-from-out "flow/extended/expander.rkt")
         (all-from-out "flow/extended/forms.rkt")
         ;; Needed due to binding spaces "quirk"
         ;; See https://github.com/drym-org/qi/wiki/Qi-Compiler-Sync-Sept-2-2022#binding-spaces-quirk
         (for-space qi
                    (rename-out [~flow flow]
                                [~☯ ☯])))

(require syntax-spec-v3
         (for-syntax racket/base
                     syntax/parse
                     (only-in "private/util.rkt"
                              report-syntax-error))
         "flow/extended/expander.rkt"
         "flow/core/compiler.rkt"
         (rename-in "flow/extended/forms.rkt"
                    [flow ~flow]
                    [☯ ~☯])
         (for-syntax "flow/extended/util.rkt")
         (only-in "private/util.rkt"
                  define-alias))

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

(syntax-spec
  (host-interface/expression
    (flow f:closed-floe ...)
    (syntax-parse #'(f ...)
      [(f) (compile-flow #'f)]
      ;; a non-flow
      [() #'values]
      ;; error handling catch-all
      [(expr0 expr ...+)
       (report-syntax-error
           (datum->syntax this-syntax
             (cons 'flow
                   (map prettify-flow-syntax
                        (syntax->list this-syntax))))
         "(flow flo)"
         "flow expects a single flow specification, but it received many.")])))
