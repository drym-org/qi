#lang racket/base

(require (only-in racket/function
                  const))

(provide ->boolean
         true.
         false.)

(define (->boolean v)
  (not (not v)))

(define true.
  (procedure-rename (const #t)
                    'true.))

(define false.
  (procedure-rename (const #f)
                    'false.))
