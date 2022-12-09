#lang racket/base

(provide (rename-out [flow-interface flow])
         ☯
         (all-from-out "flow/extended/expander.rkt")
         (all-from-out "flow/extended/forms.rkt"))

(require syntax/parse/define
         bindingspec
         (prefix-in fancy: fancy-app)
         racket/function
         (only-in racket/list
                  make-list)
         (for-syntax racket/base
                     syntax/parse
                     (only-in "private/util.rkt"
                              report-syntax-error))
         "flow/extended/expander.rkt"
         "flow/core/compiler.rkt"
         "flow/extended/forms.rkt"
         (only-in "private/util.rkt"
                  define-alias))

(define-alias ☯ flow-interface)

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
    (flow f:floe)
    (compile-flow #'f)))

(define-syntax-parser flow-interface
  ;; we could define `flow` exclusively using syntax-spec if there weren't
  ;; these extra-linguistic cases to handle. Otherwise, if we did that now,
  ;; the multi-argument case would only report the intended error message
  ;; if the component expressions were valid flows
  [(_ onex) #'(flow onex)]
  [(_) #'values]
  [(_ expr0 expr ...+)
   (report-syntax-error
    this-syntax
    "(flow flo)"
    "flow expects a single flow specification, but it received many.")])
