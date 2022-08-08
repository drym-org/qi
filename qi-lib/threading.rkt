#lang racket/base

(provide ~>
         ~>>)

(require syntax/parse/define
         (for-syntax racket/base
                     "flow.rkt"
                     (only-in "private/util.rkt"
                              report-syntax-error))
         "flow.rkt"
         "on.rkt")

(define-syntax-parser ~>
  [(_ (arg0 arg ...+) (~or* (~datum sep) (~datum △)) clause:clause ...)
   ;; catch a common usage error
   (report-syntax-error '~>
                        (syntax->datum #'((arg0 arg ...) sep clause ...))
                        "(~> (arg ...) flo ...)"
                        "Attempted to separate multiple values."
                        "Note that the inputs to ~> must be wrapped in parentheses.")]
  [(_ args:subject clause:clause ...)
   #:with ags (attribute args.args)
   #'(on ags (~> clause ...))])

(define-syntax-parser ~>>
  [(_ (arg0 arg ...+) (~or* (~datum sep) (~datum △)) clause:clause ...)
   ;; catch a common usage error
   (report-syntax-error '~>>
                        (syntax->datum #'((arg0 arg ...) sep clause ...))
                        "(~>> (arg ...) flo ...)"
                        "Attempted to separate multiple values."
                        "Note that the inputs to ~>> must be wrapped in parentheses.")]
  [(_ args:subject clause:clause ...)
   #:with ags (attribute args.args)
   #'(on ags (~>> clause ...))])
