#lang racket

(provide do-with-value
         just-do
         sum
         flip
         sort
         true.
         my-and
         my-or
         also-or
         also-and
         (for-space qi also-and))

(require (prefix-in b: racket/base)
         qi)

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

(define (flip f)
  (λ (x y . args)
    (apply f y x args)))

(define (sort less-than? #:key key . vs)
  (b:sort (map key vs) less-than?))

(define true.
  (procedure-rename (const #t)
                    'true.))

(define-syntax my-and
  (make-rename-transformer #'and))

(define-syntax my-or
  (make-rename-transformer #'or))

(define-syntax also-or
  (make-rename-transformer #'or))

(define-syntax also-and
  (make-rename-transformer #'and))

;; used to test defining and providing a qi macro "for space"
(define-qi-syntax-parser also-and
  [(_ flo ...) #''hello])
