#lang racket

(require (prefix-in b: racket/base))

(provide do-with-value
         just-do
         sum
         sort
         true.)

(define-syntax-rule (do-with-value value code ...)
  (let ()
    code
    ...
    value))

(define-syntax-rule (just-do code ...)
  ;; do and ignore the result
  (do-with-value (void) code ...))

(define (sum lst)
  (apply + lst))

(define (sort less-than? #:key key . vs)
  (b:sort (map key vs) less-than?))

(define true.
  (procedure-rename (const #t)
                    'true.))
