#lang racket/base

(provide (for-space qi
                    (all-defined-out)))

(require (for-syntax racket/base
                     "private/util.rkt")
         syntax/parse/define
         (only-in "flow/space.rkt"
                  define-qi-alias)
         "macro.rkt"
         racket/list
         racket/contract/base
         racket/contract/region)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Producers

(define-deforestable #:producer (build-list~ [expr init] [const n] [floe proc])
  #:fallback
  (lambda ()
    (build-list n proc))
  #:impl
  (lambda (n proc)
    (lambda (done skip yield)
      (lambda (idx)
        (cond ((< idx n)
               (yield (proc idx) (add1 idx)))
              (else (done))))))
  #:prepare
  (lambda (consing next)
    (define/contract (something idx)
      (-> exact-nonnegative-integer? any)
      (next (consing idx)))
    (lambda ()
      (something init))))

(define-qi-syntax-parser build-list
  ((_:id n:expr proc) #'(build-list~ 0 n proc)))

(define-deforestable #:producer (append~ [expr alsts])
  #:fallback
  (lambda flsts
    (apply append (append alsts flsts)))
  #:impl
  (lambda ()
    (lambda (done skip yield)
      (lambda (lsts0)
        (define lsts
          (let loop ((lsts lsts0))
            (if (and (not (null? lsts))
                     (null? (car lsts)))
                (loop (cdr lsts))
                lsts)))
        (cond ((null? lsts)
               (done))
              ((list? (car lsts))
               (yield (caar lsts) (cons (cdar lsts) (cdr lsts))))
              ((null? (cdr lsts))
               (yield (car lsts) '()))))))
  #:prepare
  (lambda (consing next)
    (lambda flsts
      (next (consing (append alsts flsts)))))
  #:rest-contract
  (listof list?))

(define-qi-syntax-parser append
  ((_:id lst ...) #'(append~ (list lst ...)))
  (_:id #'(append~ '())))

(define-deforestable #:producer list->cstream ;; => list->cstream->cstream-next
  #:fallback
  identity
  #:impl
  (lambda ()
    (lambda (done skip yield)
      (λ (state)
        (cond [(null? state) (done)]
              [else (yield (car state) (cdr state))]))))
  #:prepare
  (lambda (consing next)
    (lambda (lst)
      (next (consing lst))))
  #:contracts
  (list?))

(define-deforestable #:producer (make-list~ [expr init] [const k] [const v])
  #:fallback
  (lambda ()
    (make-list k v))
  #:impl
  (lambda (k v)
    (lambda (done skip yield)
      (lambda (idx)
        (cond [(< idx k)
               (yield v (add1 idx))]
              [else (done)]))))
  #:prepare
  (lambda (consing next)
    (lambda ()
      (next (consing init)))))

(define-qi-syntax-parser make-list
  [(_:id k:expr v:expr) #'(make-list~ 0 k v)])

(define-deforestable #:producer (range~ [expr low] [const high] [const step])
  #:fallback
  (λ ()
    (range low high step))
  #:impl
  (lambda (high step)
    (lambda (done skip yield)
      (λ (low)
        (cond [(< low high)
               (yield low (+ low step))]
              [else (done)]))))
  #:prepare
  (lambda (consing next)
      ;;;
      (define/contract (something l h s)
        (-> number? number? number? any)
        (next (consing l)))
      (lambda ()
        (something low high step))))

;; We'd like to indicate multiple surface variants for `range` that
;; expand to a canonical form, and provide a single codegen just for the
;; canonical form.
;; Since `define-deforestable` doesn't support indicating multiple cases
;; yet, we use the ordinary macro machinery to expand surface variants of
;; `range` to a canonical form that is defined using
;; `define-deforestable`.
(define-qi-syntax-parser range
  [(_ low:expr high:expr step:expr) #'(range~ low high step)]
  [(_ low:expr high:expr) #'(range~ low high 1)]
  [(_ high:expr) #'(range~ 0 high 1)]
  ;; not strictly necessary but this provides a better error
  ;; message than simply "range: bad syntax" that's warranted
  ;; to differentiate from racket/list's `range`
  [_:id (report-syntax-error this-syntax
          "(range arg ...)"
          "range expects at least one argument")])

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Transformers

;; Special values used by stateful transformers
(define deforest/done (gensym))

(define-qi-syntax-parser cdr
  [_:id #'(list-tail 1)])

(define-deforestable #:transformer (list-tail [expr n])
  #:fallback
  (lambda (vs)
      (list-tail vs n))
  #:impl
  (lambda (next ctx src)
    (λ (done skip yield)
      (λ (drop-state)
        (define n (car drop-state))
        (define state (cdr drop-state))
        (if (zero? n)
            ((next done
                   (λ (state)
                     (skip (cons n state)))
                   (λ (value state)
                     (define new-state (cons n state))
                     (yield value new-state)))
             state)
            ((next (λ ()
                     ((contract (-> pair? any)
                                (λ (v) v)
                                'list-tail ctx
                                #f
                                src)
                      '()))
                   (λ (state)
                     (skip (cons n state)))
                   (λ (value state)
                     (skip (cons (sub1 n) state))))
             state))))))

(define-deforestable #:transformer (map [floe f])
  #:fallback
  (lambda (vs)  ; single list arg      
      (map f vs))
  #:impl
  (lambda (f next ctx src)
    (λ (done skip yield)
      (next done
            skip
            (λ (value state)
              (yield (f value) state))))))

(define-deforestable #:transformer (filter [floe f])
  #:fallback
  (λ (vs)
      (filter f vs))
  #:impl
  (lambda (f next ctx src)
    (λ (done skip yield)
      (next done
            skip
            (λ (value state)
              (if (f value)
                  (yield value state)
                  (skip state)))))))

(define-deforestable #:transformer (remove~ [expr v] [floe proc])
  #:fallback
  (λ (vs)
    (remove v vs proc))
  #:impl
  (lambda (proc next ctx src)
    (λ (done skip yield)
      (λ (state0)
        (define v (car state0))
        (define state (cdr state0))
        (if (eq? v deforest/done)
            ((next done
                   (λ (state1)
                     (skip (cons v state1)))
                   (λ (value state1)
                     (yield value (cons v state1))))
             state)
            ((next done
                   (λ (state1)
                     (skip (cons v state1)))
                   (λ (value state1)
                     (if (proc v value)
                         (skip (cons deforest/done state1))
                         (yield value (cons v state1)))))
             state))))))

(define-qi-syntax-parser remove
  [(_:id v:expr) #'(remove~ v equal?)]
  [(_:id v:expr proc) #'(remove~ v proc)])

(define-qi-syntax-parser remq
  [(_:id v:expr) #'(remove~ v eq?)])

(define-qi-syntax-parser remv
  [(_:id v:expr) #'(remove~ v eqv?)])

(define-qi-syntax-parser remw
  [(_:id v:expr) #'(remove~ v equal-always?)])

(define-deforestable #:transformer (remove*~ [const v-lst] [floe proc])
  #:fallback
  (λ (vs)
    (remove* v-lst vs proc))
  #:impl
  (lambda (v-lst proc next ctx src)
    (λ (done skip yield)
      (next done
            skip
            (λ (value state)
              (if (for/or ((v (in-list v-lst)))
                    (proc v value))
                  (skip state)
                  (yield value state)))))))

(define-qi-syntax-parser remove*
  [(_:id v:expr) #'(remove*~ v equal?)])

(define-qi-syntax-parser remq*
  [(_:id v:expr) #'(remove*~ v eq?)])

(define-qi-syntax-parser remv*
  [(_:id v:expr) #'(remove*~ v eqv?)])

(define-qi-syntax-parser remw*
  [(_:id v:expr) #'(remove*~ v equal-always?)])

(define-deforestable #:transformer (member~ [expr v] [floe is-equal?])
  #:fallback
  (λ (vs)
    (member v vs is-equal?))
  #:impl
  (lambda (is-equal? next ctx src)
    (λ (done skip yield)
      (λ (state0)
        (define v (car state0))
        (define state (cdr state0))
        (if (eq? v deforest/done)
            ((next done
                   (λ (state1)
                     (skip (cons v state1)))
                   (λ (value state1)
                     (yield value (cons v state1))))
             state)
            ((next done
                   (λ (state1)
                     (skip (cons v state1)))
                   (λ (value state1)
                     (if (is-equal? value v)
                         (yield value (cons deforest/done state1))
                         (skip (cons v state1)))))
             state))))))

(define-qi-syntax-parser member
  [(_:id v:expr) #'(member~ v equal?)]
  [(_:id v:expr proc) #'(member~ v proc)])

(define-qi-syntax-parser memw
  [(_:id v:expr) #'(member~ v equal-always?)])

(define-qi-syntax-parser memv
  [(_:id v:expr) #'(member~ v eqv?)])

(define-qi-syntax-parser memq
  [(_:id v:expr) #'(member~ v eq?)])

(define-deforestable #:transformer (memf~ [expr init] [floe proc])
  #:fallback
  (λ (vs)
    (memf proc vs))
  #:impl
  (lambda (proc next ctx src)
    (λ (done skip yield)
      (λ (state0)
        (define v (car state0))
        (define state (cdr state0))
        (if (eq? v deforest/done)
            ((next done
                   (λ (state1)
                     (skip (cons v state1)))
                   (λ (value state1)
                     (yield value (cons v state1))))
             state)
            ((next done
                   (λ (state1)
                     (skip (cons v state1)))
                   (λ (value state1)
                     (if (proc value)
                         (yield value (cons deforest/done state1))
                         (skip (cons v state1)))))
             state))))))

(define-qi-syntax-parser memf
  [(_:id proc) #'(memf~ 'unused proc)])

(define-qi-syntax-parser cddr
  [_:id #'(list-tail 2)])

(define-qi-syntax-parser cdddr
  [_:id #'(list-tail 3)])

(define-qi-syntax-parser cddddr
  [_:id #'(list-tail 4)])

(define-qi-syntax-parser cdddddr
  [_:id #'(list-tail 5)])

(define-qi-syntax-parser rest
  [_:id #'(list-tail 1)])

(define-deforestable #:transformer (list-update [expr pos] [floe updater])
  #:fallback
  (lambda (vs)
    (list-update lst post updater))
  #:impl
  (lambda (updater next ctx src)
    (lambda (done skip yield)
      (lambda (state0)
        (define pos (car state0))
        (define state (cdr state0))
        ((next done
               (lambda (state1)
                 (skip (cons pos state1)))
               (lambda (value state1)
                 (yield (if (zero? pos)
                            (updater value)
                            value)
                        (cons (sub1 pos) state1))))
         state)))))

(define-deforestable #:transformer (list-set [expr pos] [const value])
  #:fallback
  (lambda (vs)
    (list-set lst post value))
  #:impl
  (lambda (new-value next ctx src)
    (lambda (done skip yield)
      (lambda (state0)
        (define pos (car state0))
        (define state (cdr state0))
        ((next done
               (lambda (state1)
                 (skip (cons pos state1)))
               (lambda (value state1)
                 (yield (if (zero? pos)
                            new-value
                            value)
                        (cons (sub1 pos) state1))))
         state)))))

(define-deforestable #:transformer (indexes-of~ [expr idx] [const v] [floe is-equal?])
  #:fallback
  (lambda (vs)
    (indexes-of vs v is-equal?))
  #:impl
  (lambda (v is-equal? next ctx src)
    (lambda (done skip yield)
      (lambda (state0)
        (define idx (car state0))
        (define state (cdr state0))
        ((next done
               (lambda (state1)
                 (skip (cons idx state1)))
               (lambda (value state1)
                 (if (is-equal? value v)
                     (yield idx (cons (add1 idx) state1))
                     (skip (cons (add1 idx) state1)))))
         state)))))

(define-qi-syntax-parser indexes-of
  [(_:id v:expr is-equal?) #'(indexes-of~ 0 v is-equal?)]
  [(_:id v:expr) #'(indexes-of~ 0 v equal?)])

(define-deforestable #:transformer (indexes-where~ [expr idx] [floe proc])
  #:fallback
  (lambda (vs)
    (indexes-where vs proc))
  #:impl
  (lambda (proc next ctx src)
    (lambda (done skip yield)
      (lambda (state0)
        (define idx (car state0))
        (define state (cdr state0))
        ((next done
               (lambda (state1)
                 (skip (cons idx state1)))
               (lambda (value state1)
                 (if (proc value)
                     (yield idx (cons (add1 idx) state1))
                     (skip (cons (add1 idx) state1)))))
         state)))))

(define-qi-syntax-parser indexes-where
  [(_:id proc) #'(indexes-where~ 0 proc)])

(define-deforestable #:transformer (take [expr n])
  #:fallback
  (λ (vs)
      (take vs n))
  #:impl
  (lambda (next ctx src)
    (λ (done skip yield)
      (λ (take-state)
        (define n (car take-state))
        (define state (cdr take-state))
        (if (zero? n)
            (done)
            ((next (λ ()
                     ((contract (-> pair? any)
                                (λ (v) v)
                                'take ctx
                                #f
                                src)
                      '()))
                   (λ (state)
                     (skip (cons n state)))
                   (λ (value state)
                     (define new-state (cons (sub1 n) state))
                     (yield value new-state)))
             state))))))

(define-qi-alias drop list-tail)

(define-deforestable #:transformer (takef [floe pred])
  #:fallback
  (λ (vs)
    (takef vs pred))
  #:impl
  (lambda (pred next ctx src)
    (λ (done skip yield)
      (next done
            skip
            (λ (value state)
              (if (pred value)
                  (yield value state)
                  (done)))))))

(define-deforestable #:transformer (dropf~ [expr init] [floe pred])
  #:fallback
  (lambda (vs)
    (dropf vs pred))
  #:impl
  (lambda (pred next ctx src)
    (lambda (done skip yield)
      (lambda (state0)
        (define v (car state0))
        (define state (cdr state0))
        (if (eq? v deforest/done)
            ((next done
                   (lambda (state1)
                     (skip (cons v state1)))
                   (lambda (value state1)
                     (yield value (cons v state1))))
             state)
            ((next done
                   (lambda (state1)
                     (skip (cons v state1)))
                   (lambda (value state1)
                     (if (pred value)
                         (skip (cons v state1))
                         (yield value (cons deforest/done state1)))))
             state))))))

(define-qi-syntax-parser dropf
  [(_:id pred) #'(dropf~ 'unused pred)])

(define-deforestable #:transformer (filter-map [floe f])
  #:fallback
  (λ (vs)
      (filter-map f vs))
  #:impl
  (lambda (f next ctx src)
    (λ (done skip yield)
      (next done
            skip
            (λ (value state)
              (let ([fv (f value)])
                (if fv
                    (yield fv state)
                    (skip state))))))))

(define-deforestable #:transformer (filter-not [floe f])
  #:fallback
  (lambda (vs)
      (filter-not f vs))
  #:impl
  (lambda (f next ctx src)
    (λ (done skip yield)
      (next done
            skip
            (λ (value state)
              (if (f value)
                  (skip state)
                  (yield value state)))))))

(define-deforestable #:transformer (remf~ [expr init] [floe pred])
  #:fallback
  (λ (vs)
    (remf pred vs))
  #:impl
  (lambda (pred next ctx src)
    (λ (done skip yield)
      (λ (state0)
        (define v (car state0))
        (define state (cdr state0))
        (if (eq? v deforest/done)
            ((next done
                   (λ (state1)
                     (skip (cons v state1)))
                   (λ (value state1)
                     (yield value (cons v state1))))
             state)
            ((next done
                   (λ (state1)
                     (skip (cons v state1)))
                   (λ (value state1)
                     (if (pred value)
                         (skip (cons deforest/done state1))
                         (yield value (cons v state1)))))
             state))))))

(define-qi-syntax-parser remf
  [(_:id pred) #'(remf~ 'unused pred)])

(define-deforestable #:transformer (remf* [floe pred])
  #:fallback
  (λ (vs)
    (remf* pred vs))
  #:impl
  (lambda (pred next ctx src)
    (λ (done skip yield)
      (next done
            skip
            (λ (value state)
              (if (pred value)
                  (skip state)
                  (yield value state)))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Consumers

(define-deforestable #:consumer cstream->list
  #:fallback
  identity
  #:impl
  (lambda (next ctx src)
    (λ (state)
      (let loop ([state state])
        ((next (λ () null)
               (λ (state) (loop state))
               (λ (value state)
                 (cons value (loop state))))
         state)))))

(define-deforestable #:consumer pair?
  #:fallback
  pair?
  #:impl
  (lambda (next ctx src)
    (λ (state)
      (let loop ([state state])
        ((next (λ () #f)
               (λ (state) (loop state))
               (λ (value state) #t))
         state)))))

(define-qi-alias null? empty?)

(define-qi-syntax-parser car
  [_:id #'(list-ref~ 0 'car)])

(define-deforestable #:consumer length
  #:fallback
  length
  #:impl
  (lambda (next ctx src)
    (λ (state)
      (let loop ([state state]
                 [the-length 0])
        ((next (λ () the-length)
               (λ (state) (loop state the-length))
               (λ (value state)
                 (loop state (add1 the-length))))
         state)))))

(define-deforestable #:consumer (list-ref~ [expr n] [expr name])
  #:fallback
  (λ (vs)
      (list-ref vs n))
  #:impl
  (lambda (init-countdown name next ctx src)
    (λ (state)
      (let loop ([state state]
                 [countdown init-countdown])
        ((next (λ () ((contract (-> pair? any)
                                (λ (v) v)
                                name ctx #f
                                src)
                      '()))
               (λ (state) (loop state countdown))
               (λ (value state)
                 (if (zero? countdown)
                     value
                     (loop state (sub1 countdown)))))
         state)))))

(define-qi-syntax-parser list-ref
  [(_ n:expr) #'(list-ref~ n 'list-ref)])

(define-deforestable #:consumer reverse
  #:fallback
  (λ (vs)
    (reverse vs))
  #:impl
  (lambda (next ctx src)
    (lambda (state)
      (let loop ([acc '()] [state state])
        ((next (λ () acc)
               (λ (state) (loop acc state))
               (λ (value state)
                 (loop (cons value acc) state)))
         state)))))

(define-deforestable #:consumer (foldl [floe op] [expr init])
  #:fallback
  (λ (vs)
      (foldl op init vs))
  #:impl
  (lambda (op init next ctx src)
    (lambda (state)
      (let loop ([acc init] [state state])
        ((next (λ () acc)
               (λ (state) (loop acc state))
               (λ (value state)
                 (loop (op value acc) state)))
         state)))))

(define-deforestable #:consumer (foldr [floe f] [expr init])
  #:fallback
  (λ (vs)
      (foldr f init vs))
  #:impl
  (lambda (op init next ctx src)
    (lambda (state)
      (let loop ([state state])
        ((next (λ () init)
               (λ (state) (loop state))
               (λ (value state)
                 (op value (loop state))))
         state)))))

(define-deforestable #:consumer (findf [floe proc])
  #:fallback
  (λ (vs)
    (findf vs proc))
  #:impl
  (lambda (proc next ctx src)
    (lambda (state)
      (let loop ((state state))
        ((next (λ () #f)
               (λ (state) (loop state))
               (λ (value state)
                 (if (proc value)
                     value
                     (loop state))))
         state)))))

(define-deforestable #:consumer (assoc~ [expr v] [floe is-equal?])
  #:fallback
  (λ (vs)
    (assoc v vs is-equal?))
  #:impl
  (lambda (v is-equal? next ctx src)
    (λ (state)
      (let loop ((state state))
        ((next (λ () #f)
               (λ (state) (loop state))
               (λ (value state)
                 (if (is-equal? (car value) v)
                     value
                     (loop state))))
         state)))))

(define-qi-syntax-parser assoc
  [(_ v:expr) #'(assoc~ v equal?)]
  [(_ v:expr is-equal?) #'(assoc~ v is-equal?)])

(define-qi-syntax-parser assw
  [(_ v:expr) #'(assoc~ v equal-always?)])

(define-qi-syntax-parser assv
  [(_ v:expr) #'(assoc~ v eqv?)])

(define-qi-syntax-parser assq
  [(_ v:expr) #'(assoc~ v eq?)])

(define-deforestable #:consumer (assf [floe pred?])
  #:fallback
  (λ (vs)
    (assf pred? vs))
  #:impl
  (lambda (pred? next ctx src)
    (λ (state)
      (let loop ((state state))
        ((next (λ () #f)
               (λ (state) (loop state))
               (λ (value state)
                 (if (pred? (car value))
                     value
                     (loop state))))
         state)))))

(define-qi-syntax-parser cadr
  [_:id #'(list-ref~ 1 'cadr)])

(define-qi-syntax-parser caddr
  [_:id #'(list-ref~ 2 'caddr)])

(define-qi-syntax-parser cadddr
  [_:id #'(list-ref~ 3 'cadddr)])

(define-qi-alias cons? pair?)

(define-deforestable #:consumer empty?
  #:fallback
  empty?
  #:impl
  (lambda (next ctx src)
    (λ (state)
      (let loop ([state state])
        ((next (λ () #t)
               (λ (state) (loop state))
               (λ (value state) #f))
         state)))))

(define-deforestable #:consumer (index-of~ [expr v] [floe is-equal?])
  #:fallback
  (λ (vs)
    (index-of vs v is-equal?))
  #:impl
  (lambda (v is-equal? next ctx src)
    (lambda (state)
      (let loop ((state state)
                 (idx 0))
        ((next (λ () #f)
               (λ (state) (loop state idx))
               (λ (value state)
                 (if (is-equal? value v)
                     idx
                     (loop state (add1 idx)))))
         state)))))

(define-qi-syntax-parser index-of
  [(_ v:expr) #'(index-of~ v equal?)]
  [(_ v:expr is-equal?) #'(index-of~ v is-equal?)])

(define-deforestable #:consumer (index-where [floe proc])
  #:fallback
  (λ (vs)
    (index-where vs proc))
  #:impl
  (lambda (proc next ctx src)
    (lambda (state)
      (let loop ((state state)
                 (idx 0))
        ((next (λ () #f)
               (λ (state) (loop state idx))
               (λ (value state)
                 (if (proc value)
                     idx
                     (loop state (add1 idx)))))
         state)))))

(define-deforestable #:consumer (argmin [floe proc])
  #:fallback
  (λ (vs)
    (argmin proc vs))
  #:impl
  (lambda (proc next ctx src)
    (lambda (state)
      (let loop ((state state)
                 (bestarg #f)
                 (bestval #f))
        ((next (λ () bestval)
               (λ (state) (loop state bestarg bestval))
               (λ (value state)
                 (define curarg (proc value))
                 (if (or (not bestarg)
                         (< curarg bestarg))
                     (loop state curarg value)
                     (loop state bestarg bestval))))
         state)))))

(define-deforestable #:consumer (argmax [floe proc])
  #:fallback
  (λ (vs)
    (argmax proc vs))
  #:impl
  (lambda (proc next ctx src)
    (lambda (state)
      (let loop ((state state)
                 (bestarg #f)
                 (bestval #f))
        ((next (λ () bestval)
               (λ (state) (loop state bestarg bestval))
               (λ (value state)
                 (define curarg (proc value))
                 (if (or (not bestarg)
                         (> curarg bestarg))
                     (loop state curarg value)
                     (loop state bestarg bestval))))
         state)))))

#;(define-qi-syntax-parser count
  [(_ proc) #'(~> (filter-map proc) length)])
