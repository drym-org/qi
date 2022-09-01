#lang racket/base

(provide (rename-out [R~> ~>]
                     [R~>> ~>>]))

(require syntax/parse/define
         (for-syntax racket/base
                     (only-in "private/util.rkt"
                              report-syntax-error)
                     "flow/aux-syntax.rkt")
         "flow.rkt"
         "on.rkt")

(define-syntax-parser R~>
  [(_ (arg0 arg ...+) (~or* (~datum sep) (~datum △)) clause:clause ...)
   ;; catch a common usage error
   (report-syntax-error this-syntax
                        "(~> (arg ...) flo ...)"
                        "Attempted to separate multiple values."
                        "Note that the inputs to ~> must be wrapped in parentheses.")]
  [(_ args:subject clause:clause ...)
   #:with ags (attribute args.args)
   #'(on ags (~> clause ...))
   ;; tweak report-syntax-error to give srcloc
   ;; (raise-syntax-error #f "Error!" this-syntax)
   ])

;; (raise-syntax-error #f "Error!" this-syntax)

(define-syntax-parser R~>>
  [(_ (arg0 arg ...+) (~or* (~datum sep) (~datum △)) clause:clause ...)
   ;; catch a common usage error
   (report-syntax-error this-syntax
                        "(~>> (arg ...) flo ...)"
                        "Attempted to separate multiple values."
                        "Note that the inputs to ~>> must be wrapped in parentheses.")]
  [(_ args:subject clause:clause ...)
   #:with ags (attribute args.args)
   #'(on ags (~>> clause ...))
   ;; (report-syntax-error '~>>
   ;;                      (syntax->datum #'((args) sep clause ...))
   ;;                      "(~>> (arg ...) flo ...)"
   ;;                      "ERROR"
   ;;                      "Note that the inputs to ~>> must be wrapped in parentheses.")
   ])
