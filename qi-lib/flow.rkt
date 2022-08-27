#lang racket/base

(provide flow
         ☯
         (all-from-out "flow/extended/expander.rkt"))

(require syntax/parse/define
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

(define-syntax-parser flow
  [(_ onex) ((compose compile-flow expand-flow) #'onex)]
  ;; a non-flow
  [_ #'values]
  ;; error handling catch-all
  [(_ expr0 expr ...+)
   (report-syntax-error
    'flow
    (syntax->datum #'(expr0 expr ...))
    "(flow flo)"
    "flow expects a single flow specification, but it received many.")])
