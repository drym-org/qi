#lang racket/base

(require racket/match
         (only-in racket/function
                  const
                  negate)
         racket/bool
         racket/list
         (only-in adjutor values->list))

(provide give
         ->boolean
         true.
         false.
         any?
         all?
         none?
         map-values
         relay
         loom-compose
         parity-xor
         arg)

;; we use a lambda to capture the arguments at runtime
;; since they aren't available at compile time
(define (loom-compose f g [n #f])
  (let ([n (or n (procedure-arity f))])
    (λ args
      (apply values
             (append (values->list (apply f (take args n)))
                     (values->list (apply g (drop args n))))))))

(define (parity-xor . args)
  (not
   (not
    (foldl xor
           #f
           args))))

(define (arg n)
  (λ args
    (list-ref args n)))

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

(define exists ormap)

(define for-all andmap)

(define (zip-with op . seqs)
  (if (exists empty? seqs)
      (if (for-all empty? seqs)
          null
          (apply raise-arity-error
                 'zip-with
                 0
                 (first (filter (negate empty?) seqs))))
      (let ([vs (map first seqs)])
        (append (values->list (apply op vs))
                (apply zip-with op (map rest seqs))))))

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
