#lang racket/base

;; This name juggling is necessary since the Racket macros would
;; otherwise collide with the Qi forms with the same name in the qi
;; binding space, since Qi forms are now exported literals and not simply
;; matched as datum patterns as they were formerly.
(provide (rename-out [%~> ~>]
                     [%~>> ~>>]))

(require syntax/parse/define
         (for-syntax racket/base
                     (only-in "private/util.rkt"
                              report-syntax-error)
                     "flow/aux-syntax.rkt")
         "flow.rkt"
         "on.rkt")

(define-syntax-parser %~>
  [(_ args:subject clause:clause ...)
   #:with ags (attribute args.args)
   #'(on ags (~> clause ...))])

(define-syntax-parser %~>>
  [(_ args:subject clause:clause ...)
   #:with ags (attribute args.args)
   #'(on ags (~>> clause ...))])
