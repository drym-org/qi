#lang racket

(provide sum
         flip
         sort
         true.
         my-and
         my-or
         also-or
         also-and
         (for-space qi
                    also-and
                    double-me
                    add-two))

(require (prefix-in b: racket/base)
         qi)

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

;; to test providing registered foreign syntaxes "for space"
(define-syntax-rule (double-me x) (* 2 x))

(define-syntax-rule (add-two x y) (+ x y))

(define-qi-foreign-syntaxes double-me)

(define-qi-foreign-syntaxes add-two)
