#lang racket/base

(require syntax/parse/define
         mischief/shorthand
         (for-syntax racket/base)
         "base.rkt"
         (for-syntax "base.rkt"))

(provide on
         lambda/subject
         define/subject
         predicate-lambda
         define-predicate
         lambdap
         π)

(define-syntax-parser on
  [(_ args:subject) #'(void)]
  [(_ args:subject clause)
   ;; forward the subject arity in case it's necessary to
   ;; the compilation of the clause
   #:do [(define arity (attribute args.arity))]
   #`((on-clause clause #,arity) #,@(syntax->list (attribute args.args)))])

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
