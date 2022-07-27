#lang racket/base

(provide on
         flow-lambda
         define-flow
         π)

(require syntax/parse/define
         (for-syntax racket/base
                     syntax/parse/lib/function-header
                     "flow.rkt")
         "flow.rkt"
         (only-in "private/util.rkt" define-alias))

(define-syntax-parser on
  [(_ args:subject)
   #:with ags (attribute args.args)
   #`((flow) #,@(syntax->list #'ags))]
  [(_ args:subject clause:clause)
   #:with ags (attribute args.args)
   #`((flow clause) #,@(syntax->list #'ags))])

(define-syntax-parser flow-lambda
  [(_ args:formals clause:clause)
   #:with ags (attribute args.params)
   #'(lambda args
       (on ags
           clause))])

(define-alias π flow-lambda)

(define-syntax-parser define-flow
  [(_ ((~or head:id head:function-header) . args:formals)
      clause:clause)
   #'(define head
       (flow-lambda args
         clause))]
  [(_ name:id clause:clause)
   #'(define name
       (flow clause))])
