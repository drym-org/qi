#lang racket/base

(require racket/match
         (only-in racket/function const))

(provide give
         ->boolean
         true.
         false.
         any?
         all?
         none?
         conjux
         disjux
         map-values
         relay)

;; give a (list-)lifted function available arguments
;; directly instead of wrapping them with a list
;; related to `unpack`
(define (give f)
  (λ args
    (f args)))

(define (map-values f . args)
  (apply values (map f args)))

(define (->boolean v)
  (not (not v)))

(define true.
  (procedure-rename (const #t)
                    'true.))

(define false.
  (procedure-rename (const #f)
                    'false.))

;; "juxtaposed conjoin"
(define (conjux . preds)
  (λ args
    (match* (preds args)
      [('() '()) #t]
      [((cons p ps) (cons v vs))
       (and (p v)
            (apply (apply conjux ps)
                   vs))]
      [(_ _) (apply raise-arity-error
                    'conjux
                    (length preds)
                    args)])))

;; "juxtaposed disjoin"
(define (disjux . preds)
  (λ args
    (match* (preds args)
      [('() '()) #f]
      [((cons p ps) (cons v vs))
       (or (p v)
           (apply (apply disjux ps)
                  vs))]
      [(_ _) (apply raise-arity-error
                    'disjux
                    (length preds)
                    args)])))

(define (zip-with f . vs)
  (apply map f vs))

;; from mischief/function - requiring it runs aground
;; of some "name is protected" error while building docs, not sure why;
;; so including the implementation directly here for now
(define call
  (make-keyword-procedure
   (lambda (ks vs f . xs)
     (keyword-apply f ks vs xs))))

(define (relay . fs)
  (λ args
    (apply values (zip-with call fs args))))

(define (~all? . args)
  (match args
    ['() #t]
    [(cons v vs)
     (match vs
       ['() v]
       [_ (and v (apply all? vs))])]))

(define all? (compose not not ~all?))

(define (~any? . args)
  (match args
    ['() #f]
    [(cons v vs)
     (match vs
       ['() v]
       [_ (or v (apply any? vs))])]))

(define any? (compose not not ~any?))

(define (~none? . args)
  (not (apply any? args)))

(define none? (compose not not ~none?))
