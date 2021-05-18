#lang racket/base

(require syntax/parse/define
         mischief/shorthand
         (for-syntax racket/base
                     "base.rkt")
         "base.rkt")

(provide on
         lambda/subject
         define/subject
         predicate-lambda
         define-predicate
         lambdap
         π)

(define-syntax-parser on
  [(_ args:subject) #'(void)]
  [(_ args:subject clause:clause)
   #:with ags (attribute args.args)
   #`((on-clause clause) #,@(syntax->list #'ags))])

(define-syntax-parser lambda/subject
  [(_ (arg:id ...) expr:expr ...)
   #'(lambda (arg ...)
       (on (arg ...)
           expr ...))]
  [(_ rest-args:id expr:expr ...)
   #'(lambda rest-args
       (on (rest-args)
           expr ...))])

(define-alias predicate-lambda lambda/subject)

(define-alias lambdap predicate-lambda)

(define-alias π predicate-lambda)

(define-syntax-parser define/subject
  [(_ (name:id arg:id ...) expr:expr ...)
   #'(define name
       (lambda/subject (arg ...)
         expr ...))])

(define-alias define-predicate define/subject)
