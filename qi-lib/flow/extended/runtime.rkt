#lang racket/base

(require (only-in racket/function
                  const))

(provide ->boolean
         true.
         false.
         ~all?
         ~any?
         ~none?
         ~count
         ~live?
         ~zip)

(define (->boolean v) (and v #t))

(define true.
  (procedure-rename (const #t)
                    'true.))

(define false.
  (procedure-rename (const #f)
                    'false.))

(define (~all? . args)
  (for/and ([v (in-list args)]) v))

(define (~any?-helper args)
  (for/or ([v (in-list args)]) v))

(define (~any? . args)
  (~any?-helper args))

(define (~none? . args)
  (not (~any?-helper args)))

(define (~count . args)
  (length args))

(define (~live? . args)
  (not (null? args)))

(define (zip-lists op lsts)
  (if (null? lsts)
      null
      (if (ormap null? lsts)
       null
       (let ([vs (map car lsts)])
         (cons (apply op vs)
               (zip-lists op (map cdr lsts)))))))

(define (~zip op . lsts)
  (apply values (zip-lists op lsts)))
