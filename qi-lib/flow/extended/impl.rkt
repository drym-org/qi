#lang racket/base

(require (only-in racket/function
                  const))

(provide ->boolean
         true.
         false.)

(define (->boolean v) (and v #t))

(define true.
  (procedure-rename (const #t)
                    'true.))

(define false.
  (procedure-rename (const #f)
                    'false.))
