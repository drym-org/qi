#lang racket/base

(provide give
         ->boolean
         true.
         false.
         any?
         all?
         none?
         map-values
         filter-values
         relay
         loom-compose
         parity-xor
         arg
         except-args
         call
         repeat
         repeat-values
         power
         foldl-values
         foldr-values)

(require racket/match
         (only-in racket/function
                  const
                  negate)
         racket/bool
         racket/list
         racket/format
         typed-stack
         (only-in adjutor values->list))

;; we use a lambda to capture the arguments at runtime
;; since they aren't available at compile time
(define (loom-compose f g [n #f])
  (let ([n (or n (procedure-arity f))])
    (λ args
      (let ([num-args (length args)])
        (if (< num-args n)
           (if (= 0 num-args)
               (values)
               (error 'group (~a "Can't select "
                                 n
                                 " arguments from "
                                 args)))
           (let ([sargs (take args n)]
                 [rargs (drop args n)])
             (apply values
                    (append (values->list (apply f sargs))
                            (values->list (apply g rargs))))))))))

(define (parity-xor . args)
  (not
   (not
    (foldl xor
           #f
           args))))

(define (counting-string n)
  (let ([d (remainder n 10)]
        [ns (number->string n)])
    (cond [(= d 1) (string-append ns "st")]
          [(= d 2) (string-append ns "nd")]
          [(= d 3) (string-append ns "rd")]
          [else (string-append ns "th")])))

(define (arg n)
  (λ args
    (cond [(> n (length args))
           (error 'select (~a "Can't select "
                              (counting-string n)
                              " value in "
                              args))]
          [(= 0 n)
           (error 'select (~a "Can't select "
                              (counting-string n)
                              " value in "
                              args
                              " -- select is 1-indexed"))]
          [else (list-ref args (sub1 n))])))

(define (except-args . indices)
  (λ args
    (let ([indices (apply make-stack (sort indices <))])
      (if (and (not (stack-empty? indices))
               (<= (top indices) 0))
          (error 'block (~a "Can't block "
                            (counting-string (top indices))
                            " value in "
                            args
                            " -- block is 1-indexed"))
          (let loop ([rem-args args]
                     [cur-idx 1])
            (if (stack-empty? indices)
                rem-args
                (match rem-args
                  ['() (error 'block (~a "Can't block "
                                         (counting-string (top indices))
                                         " value in "
                                         args))]
                  [(cons v vs)
                   (if (stack-empty? indices)
                       rem-args
                       (if (= cur-idx (top indices))
                           (begin (pop! indices)
                                  (loop vs (add1 cur-idx)))
                           (cons v (loop vs (add1 cur-idx)))))])))))))

;; give a (list-)lifted function available arguments
;; directly instead of wrapping them with a list
;; related to `unpack`
(define (give f)
  (λ args
    (f args)))

(define (~map f vs)
  (match vs
    ['() null]
    [(cons v vs) (append (values->list (f v))
                         (~map f vs))]))

(define (map-values f . args)
  (apply values (~map f args)))

(define (filter-values f . args)
  (apply values (filter f args)))

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
                 'relay
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

(define (repeat n v)
  (if (= 0 n)
      null
      (cons v (repeat (sub1 n) v))))

(define (repeat-values n . vs)
  (apply values (apply append (repeat n vs))))

(define (power n f)
  (apply compose (repeat n f)))

(define (foldl-values f init . vs)
  (let loop ([vs vs]
             [accs (values->list (init))])
    (match vs
      ['() (apply values accs)]
      [(cons v rem-vs) (loop rem-vs (values->list (apply f v accs)))])))

(define (foldr-values f init . vs)
  (let loop ([vs (reverse vs)]
             [accs (values->list (init))])
    (match vs
      ['() (apply values accs)]
      [(cons v rem-vs) (loop rem-vs (values->list (apply f v accs)))])))
