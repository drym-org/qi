#lang racket/base

(require (only-in racket/function
                  const))

(provide ->boolean
         true.
         false.
         ~all?
         ~any?)

(define (->boolean v) (and v #t))

(define true.
  (procedure-rename (const #t)
                    'true.))

(define false.
  (procedure-rename (const #f)
                    'false.))

(define (~all? . args)
  (for/and ([v (in-list args)]) v))

(define (~any? . args)
  (for/or ([v (in-list args)]) v))
