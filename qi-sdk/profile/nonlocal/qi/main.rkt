#lang racket/base

(require racket/match)

(require racket/performance-hint)

(provide conditionals
         composition
         root-mean-square
         factorial
         pingala
         eratosthenes
         collatz
         filter-map
         filter-map-values
         range-map-sum
         double-list
         double-values)

(require (only-in math sqr)
         (only-in racket/list range)
         qi)

(define-switch conditionals
  [(< 5) sqr]
  [(> 5) add1]
  [else _])

(define-flow composition
  (~> add1 sqr sub1))

(define-flow root-mean-square
  (~> (-< (~>> △ (>< sqr) +)
          length) / sqrt))

(define-switch factorial
  [(< 2) 1]
  [else (~> (-< _ (~> sub1 factorial)) *)])

(define-switch pingala
  [(< 2) _]
  [else (~> (-< sub1
                (- 2)) (>< pingala) +)])

(define-flow (eratosthenes n)
  (~> (-< (gen null) (~>> add1 (range 2) △))
      (feedback (while (~> (block 1) live?))
                (then (~> 1> reverse))
                (-< (~> (select 1 2) X cons)
                    (~> (-< (~>> 2> (clos (~> remainder (not (= 0)))))
                            (block 1 2)) pass)))))

(define-flow collatz
  (switch
    [(<= 1) list]
    [odd? (~> (-< _ (~> (* 3) (+ 1) collatz))
              cons)]
    [even? (~> (-< _ (~> (quotient 2) collatz))
               cons)]))


;; (define-flow filter-map
;;   (~> △ (>< (if odd? sqr ⏚)) ▽))

;; (define-flow filter-map
;;   (~>> (filter odd?) (map sqr)))

;; (define (filter-map lst)
;;   (foldr (λ (v vs)
;;            (if (odd? v)
;;                (cons (sqr v) vs)
;;                vs))
;;          null
;;          lst))

(struct stream (next state)
  #:transparent)

(define (map-stream f s)
  (define (next state)
    (match ((stream-next s) state)
      ['done 'done]
      [(cons 'skip new-state) (cons 'skip new-state)]
      [(list 'yield value new-state)
       (list 'yield (f value) new-state)]))
  (stream next (stream-state s)))

(define (filter-stream f s)
  (define (next state)
    (match ((stream-next s) state)
      ['done 'done]
      [(cons 'skip new-state) (cons 'skip new-state)]
      [(list 'yield value new-state)
       (if (f value)
           (list 'yield value new-state)
           (cons 'skip new-state))]))
  (stream next (stream-state s)))

(define (list->stream lst)
  (define (next state)
    (cond [(null? state) 'done]
          [else (list 'yield (car state) (cdr state))]))
  (stream next lst))

;; continuation version
;; a lambda that does not escape is equivalent to a goto
;; lambda the ultimate goto by guy steele
;; (begin-encourage-inline
;;   (define-inline (cstream->list next)
;;     (λ (state)
;;       (let loop ([state state])
;;         ((next (λ () null)
;;                (λ (state) (loop state))
;;                (λ (value state)
;;                  (cons value (loop state))))
;;          state))))

;;   (define-inline (list->cstream-next done skip yield)
;;     (λ (state)
;;       (cond [(null? state) (done)]
;;             [else (yield (car state) (cdr state))])))

;;   (define-inline ((map-cstream-next f next) done skip yield)
;;     (next done
;;           skip
;;           (λ (value state)
;;             (yield (f value) state))))

;;   (define-inline ((filter-cstream-next f next) done skip yield)
;;     (next done
;;           skip
;;           (λ (value state)
;;             (if (f value)
;;                 (yield value state)
;;                 (skip state))))))

;; except for cstream->list, it's all CPS with tail recursion
;; (define (filter-map lst)
;;   ((cstream->list
;;     (map-cstream-next sqr
;;                       (filter-cstream-next odd?
;;                                            list->cstream-next)))
;;    lst))

(define-flow filter-map
  (~>> (filter odd?) (map sqr)))

(define (~sum vs)
  (apply + vs))

(define-flow range-map-sum
  (~>> (range 1) (map sqr) ~sum))

;; hand-coded iteration (representing the upper bound on performance)
;; (define (filter-map lst)
;;   (if (null? lst)
;;       '()
;;       (let ([v (car lst)])
;;         (if (odd? v)
;;             (cons (sqr v) (filter-map (cdr lst)))
;;             (filter-map (cdr lst))))))


;; (define (stream->list s)
;;   (match ((stream-next s) (stream-state s))
;;     ['done null]
;;     [(cons 'skip state)
;;      (stream->list (stream (stream-next s) state))]
;;     [(list 'yield value state)
;;      (cons value
;;            (stream->list (stream (stream-next s) state)))]))

(define (stream->list s)
  (let ([next (stream-next s)]
        [state (stream-state s)])
    (let loop ([state state])
      (match (next state)
        ['done null]
        [(cons 'skip state)
         (loop state)]
        [(list 'yield value state)
         (cons value
               (loop state))]))))

;; (define (filter-map lst)
;;   (let ([s (list->stream lst)])
;;     (stream->list (map-stream sqr (filter-stream odd? s)))))

;; This is the result of inline all of the stream operations
;; (define (filter-map lst)
;;   (define (next-list->stream state)
;;     (cond [(null? state) 'done]
;;           [else (list 'yield (car state) (cdr state))]))
;;   (let ([s (stream next-list->stream lst)])
;;     (define (next-filter-stream state)
;;       (match ((stream-next s) state)
;;         ['done 'done]
;;         [(cons 'skip new-state) (cons 'skip new-state)]
;;         [(list 'yield value new-state)
;;          (if (odd? value)
;;              (list 'yield value new-state)
;;              (cons 'skip new-state))]))
;;     (let ([s (stream next-filter-stream (stream-state s))])
;;       (define (next-map-stream state)
;;         (match ((stream-next s) state)
;;           ['done 'done]
;;           [(cons 'skip new-state) (cons 'skip new-state)]
;;           [(list 'yield value new-state)
;;            (list 'yield (sqr value) new-state)]))
;;       (let ([s (stream next-map-stream (stream-state s))])
;;         (stream->list s)))))

;; partially evaluate accessors to stream constructor
;; (define (filter-map lst)
;;   (define (next-list->stream state)
;;     (cond [(null? state) 'done]
;;           [else (list 'yield (car state) (cdr state))]))
;;   (let ([s (stream next-list->stream lst)])
;;     (define (next-filter-stream state)
;;       (match (next-list->stream state)
;;         ['done 'done]
;;         [(cons 'skip new-state) (cons 'skip new-state)]
;;         [(list 'yield value new-state)
;;          (if (odd? value)
;;              (list 'yield value new-state)
;;              (cons 'skip new-state))]))
;;     (let ([s (stream next-filter-stream lst)])
;;       (define (next-map-stream state)
;;         (match (next-filter-stream state)
;;           ['done 'done]
;;           [(cons 'skip new-state) (cons 'skip new-state)]
;;           [(list 'yield value new-state)
;;            (list 'yield (sqr value) new-state)]))
;;       (let ([s (stream next-map-stream lst)])
;;         (stream->list s)))))

;; dead code elimination (eliminate unused binding forms)
;; (define (filter-map lst)
;;   (define (next-list->stream state)
;;     (cond [(null? state) 'done]
;;           [else (list 'yield (car state) (cdr state))]))
;;   (define (next-filter-stream state)
;;     (match (next-list->stream state)
;;       ['done 'done]
;;       [(cons 'skip new-state) (cons 'skip new-state)]
;;       [(list 'yield value new-state)
;;        (if (odd? value)
;;            (list 'yield value new-state)
;;            (cons 'skip new-state))]))
;;   (define (next-map-stream state)
;;     (match (next-filter-stream state)
;;       ['done 'done]
;;       [(cons 'skip new-state) (cons 'skip new-state)]
;;       [(list 'yield value new-state)
;;        (list 'yield (sqr value) new-state)]))
;;   (let ([s (stream next-map-stream lst)])
;;     (stream->list s)))

;; inline stream->list as well
;; (define (filter-map lst)
;;   (define (next-list->stream state)
;;     (cond [(null? state) 'done]
;;           [else (list 'yield (car state) (cdr state))]))
;;   (define (next-filter-stream state)
;;     (match (next-list->stream state)
;;       ['done 'done]
;;       [(cons 'skip new-state) (cons 'skip new-state)]
;;       [(list 'yield value new-state)
;;        (if (odd? value)
;;            (list 'yield value new-state)
;;            (cons 'skip new-state))]))
;;   (define (next-map-stream state)
;;     (match (next-filter-stream state)
;;       ['done 'done]
;;       [(cons 'skip new-state) (cons 'skip new-state)]
;;       [(list 'yield value new-state)
;;        (list 'yield (sqr value) new-state)]))
;;   (let ([next next-map-stream]
;;         [state lst])
;;     (let loop ([state state])
;;       (match (next state)
;;         ['done null]
;;         [(cons 'skip state)
;;          (loop state)]
;;         [(list 'yield value state)
;;          (cons value
;;                (loop state))]))))

;; try with inlining macro
;; (require racket/performance-hint)

;; (define (filter-map lst)
;;   (define-inline (next-list->stream state)
;;     (cond [(null? state) 'done]
;;           [else (list 'yield (car state) (cdr state))]))
;;   (define-inline (next-filter-stream state)
;;     (match (next-list->stream state)
;;       ['done 'done]
;;       [(cons 'skip new-state) (cons 'skip new-state)]
;;       [(list 'yield value new-state)
;;        (if (odd? value)
;;            (list 'yield value new-state)
;;            (cons 'skip new-state))]))
;;   (define-inline (next-map-stream state)
;;     (match (next-filter-stream state)
;;       ['done 'done]
;;       [(cons 'skip new-state) (cons 'skip new-state)]
;;       [(list 'yield value new-state)
;;        (list 'yield (sqr value) new-state)]))
;;   (let ([next next-map-stream]
;;         [state lst])
;;     (let loop ([state state])
;;       (match (next state)
;;         ['done null]
;;         [(cons 'skip state)
;;          (loop state)]
;;         [(list 'yield value state)
;;          (cons value
;;                (loop state))]))))

;; return multiple values -- instead of cons skip or list yield, return values instead
;; always return exactly three values
;; (values skip new-state #f)
;; (values done #f #f)
;; every match is going to be a case on the first value of the return
;; chez scheme would kick in and result could be pretty good (CP0)
;; (define (filter-map lst)
;;   (define-inline (next-list->stream state)
;;     (cond [(null? state) (values 'done #f #f)]
;;           [else (values 'yield (car state) (cdr state))]))
;;   (define-inline (next-filter-stream state)
;;     (call-with-values
;;      (λ ()
;;        (next-list->stream state))
;;      (λ (type value new-state)
;;        (case type
;;          [(done) (values 'done #f #f)]
;;          [(skip) (values 'skip #f new-state)]
;;          [(yield)
;;           (if (odd? value)
;;               (values 'yield value new-state)
;;               (values 'skip #f new-state))]))))
;;   (define-inline (next-map-stream state)
;;     (call-with-values
;;      (λ ()
;;        (next-filter-stream state))
;;      (λ (type value new-state)
;;        (case type
;;          [(done) (values 'done #f #f)]
;;          [(skip) (values 'skip #f new-state)]
;;          [(yield)
;;           (values 'yield (sqr value) new-state)]))))
;;   (let ([next next-map-stream]
;;         [state lst])
;;     (let loop ([state state])
;;       (call-with-values
;;        (λ ()
;;          (next state))
;;        (λ (type value new-state)
;;          (case type
;;            [(done) null]
;;            [(skip)
;;             (loop new-state)]
;;            [(yield)
;;             (cons value
;;                   (loop new-state))]))))))

;; inline next-list->stream into next-filter-stream
;; (define (filter-map lst)
;;   (define (next-filter-stream state)
;;     (match (cond [(null? state) 'done]
;;                  [else (list 'yield (car state) (cdr state))])
;;       ['done 'done]
;;       [(cons 'skip new-state) (cons 'skip new-state)]
;;       [(list 'yield value new-state)
;;        (if (odd? value)
;;            (list 'yield value new-state)
;;            (cons 'skip new-state))]))
;;   (define (next-map-stream state)
;;     (match (next-filter-stream state)
;;       ['done 'done]
;;       [(cons 'skip new-state) (cons 'skip new-state)]
;;       [(list 'yield value new-state)
;;        (list 'yield (sqr value) new-state)]))
;;   (let ([next next-map-stream]
;;         [state lst])
;;     (let loop ([state state])
;;       (match (next state)
;;         ['done null]
;;         [(cons 'skip state)
;;          (loop state)]
;;         [(list 'yield value state)
;;          (cons value
;;                (loop state))]))))

;; case of case
;; when there is a conditional based on the return value of a conditional
;; invert which conditional is checked first
;; (define (filter-map lst)
;;   (define (next-list->stream state)
;;     (cond [(null? state) 'done]
;;           [else (list 'yield (car state) (cdr state))]))
;;   (define (next-filter-stream state)
;;     (cond [(null? state) (match 'done
;;                            ['done 'done]
;;                            [(cons 'skip new-state) (cons 'skip new-state)]
;;                            [(list 'yield value new-state)
;;                             (if (odd? value)
;;                                 (list 'yield value new-state)
;;                                 (cons 'skip new-state))])]
;;           [else (match (list 'yield (car state) (cdr state))
;;                   ['done 'done]
;;                   [(cons 'skip new-state) (cons 'skip new-state)]
;;                   [(list 'yield value new-state)
;;                    (if (odd? value)
;;                        (list 'yield value new-state)
;;                        (cons 'skip new-state))])]))
;;   (define (next-map-stream state)
;;     (match (next-filter-stream state)
;;       ['done 'done]
;;       [(cons 'skip new-state) (cons 'skip new-state)]
;;       [(list 'yield value new-state)
;;        (list 'yield (sqr value) new-state)]))
;;   (let ([s (stream next-map-stream lst)])
;;     (stream->list s)))

;; partially evaluate match on known argument
;; (define (filter-map lst)
;;   (define (next-list->stream state)
;;     (cond [(null? state) 'done]
;;           [else (list 'yield (car state) (cdr state))]))
;;   (define (next-filter-stream state)
;;     (cond [(null? state) 'done]
;;           [else
;;            (let ([value (car state)]
;;                  [new-state (cdr state)])
;;              (if (odd? value)
;;                  (list 'yield value new-state)
;;                  (cons 'skip new-state)))]))
;;   (define (next-map-stream state)
;;     (match (next-filter-stream state)
;;       ['done 'done]
;;       [(cons 'skip new-state) (cons 'skip new-state)]
;;       [(list 'yield value new-state)
;;        (list 'yield (sqr value) new-state)]))
;;   (let ([s (stream next-map-stream lst)])
;;     (stream->list s)))

;; 

(define-flow filter-map-values
  (>< (if odd? sqr ⏚)))

(define-flow double-list
  (~> △ (>< (-< _ _)) ▽))

(define-flow double-values
  (>< (-< _ _)))
