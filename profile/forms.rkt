#lang racket/base

(require (only-in math sqr)
         qi)

(require "util.rkt")

(module+ one-of?
  (define (one-of? v)
    ((☯ (one-of? 3 5 7))
     v))

  (run-benchmark one-of?
                 check-value
                 100000))

(module+ and
  (define (and v)
    ((☯ (and positive? integer?))
     v))

  (run-benchmark and
                 check-value
                 200000))

(module+ or
  (define (or v)
    ((☯ (or positive? integer?))
     v))

  (run-benchmark or
                 check-value
                 200000))

(module+ not
  (define (not v)
    ((☯ (not integer?))
     v))

  (run-benchmark not
                 check-value
                 200000))

(module+ and%
  (define (and% a b)
    ((☯ (and% positive? integer?))
     a b))

  (run-benchmark and%
                 check-two-values
                 200000))

(module+ or%
  (define (or% a b)
    ((☯ (or% positive? integer?))
     a b))

  (run-benchmark or%
                 check-two-values
                 200000))

(module+ group
  (define (group . vs)
    (apply
     (☯ (~> (group 2 + _)
            (group 3 + _)
            (group 4 + _)
            +))
     vs))

  (run-benchmark group
                 check-values
                 200000))

(module+ count
  (define (count . vs)
    (apply
     (☯ count)
     vs))

  (run-benchmark count
                 check-values
                 1000000))

(module+ relay
  (define (relay . vs)
    (apply
     (☯ (== add1
            sub1
            sqr
            add1
            sub1
            sqr
            add1
            sub1
            sqr
            add1))
     vs))

  (run-benchmark relay
                 check-values
                 50000))

(module+ relay*
  (define (relay* . vs)
    (apply
     (☯ (==* add1
             sub1
             sqr
             +))
     vs))

  (run-benchmark relay*
                 check-values
                 50000))

(module+ amp
  (define (amp . vs)
    (apply
     (☯ (>< sqr))
     vs))

  (run-benchmark amp
                 check-values
                 300000))

(module+ ground
  (define (ground . vs)
    (apply
     (☯ ⏚)
     vs))

  (run-benchmark ground
                 check-values
                 200000))

(module+ thread
  (define (thread . vs)
    (apply
     (☯ (~> (+ 5)
            add1
            sub1
            sqr
            add1
            sub1
            sqr
            add1
            sub1
            sqr
            add1))
     vs))

  (run-benchmark thread
                 check-values
                 200000))

(module+ thread-right
  (define (thread-right . vs)
    (apply
     (☯ (~>> (+ 5)
             add1
             sub1
             sqr
             add1
             sub1
             sqr
             add1
             sub1
             sqr
             add1))
     vs))

  (run-benchmark thread-right
                 check-values
                 200000))

(module+ crossover
  (define (crossover . vs)
    (apply
     (☯ X)
     vs))

  (run-benchmark crossover
                 check-values
                 200000))

(module+ all
  (define (all . vs)
    (apply
     (☯ (all positive?))
     vs))

  (run-benchmark all
                 check-values
                 200000))

(module+ any
  (define (any . vs)
    (apply
     (☯ (any positive?))
     vs))

  (run-benchmark any
                 check-values
                 200000))

(module+ none
  (define (none . vs)
    (apply
     (☯ (none positive?))
     vs))

  (run-benchmark none
                 check-values
                 200000))

(module+ all?
  (define (all? . vs)
    (apply
     (☯ all?)
     vs))

  (run-benchmark all?
                 check-values
                 200000))

(module+ any?
  (define (any? . vs)
    (apply
     (☯ any?)
     vs))

  (run-benchmark any?
                 check-values
                 200000))

(module+ none?
  (define (none? . vs)
    (apply
     (☯ none?)
     vs))

  (run-benchmark none?
                 check-values
                 200000))

(module+ collect
  (define (collect . vs)
    (apply
     (☯ ▽)
     vs))

  (run-benchmark collect
                 check-values
                 1000000))

(module+ sep
  (define (sep v)
    ((☯ △)
     v))

  (run-benchmark sep
                 check-list
                 1000000))

(module+ gen
  (define (gen . vs)
    (apply
     (☯ (gen 1 2 3))
     vs))

  (run-benchmark gen
                 check-values
                 1000000))

(module+ esc
  (define (esc . vs)
    (apply
     (☯ (esc (λ args args)))
     vs))

  (run-benchmark esc
                 check-values
                 1000000))

(module+ AND
  (define (AND . vs)
    (apply
     (☯ AND)
     vs))

  (run-benchmark AND
                 check-values
                 200000))

(module+ OR
  (define (OR . vs)
    (apply
     (☯ OR)
     vs))

  (run-benchmark OR
                 check-values
                 200000))

(module+ NOT
  (define (NOT v)
    ((☯ NOT)
     v))

  (run-benchmark NOT
                 check-value
                 200000))

(module+ NAND
  (define (NAND . vs)
    (apply
     (☯ NAND)
     vs))

  (run-benchmark NAND
                 check-values
                 200000))

(module+ NOR
  (define (NOR . vs)
    (apply
     (☯ NOR)
     vs))

  (run-benchmark NOR
                 check-values
                 200000))

(module+ XOR
  (define (XOR . vs)
    (apply
     (☯ XOR)
     vs))

  (run-benchmark XOR
                 check-values
                 200000))

(module+ XNOR
  (define (XNOR . vs)
    (apply
     (☯ XNOR)
     vs))

  (run-benchmark XNOR
                 check-values
                 200000))

(module+ tee
  (define (tee v)
    ((☯ (-< add1 sub1 sqr))
     v))

  (run-benchmark tee
                 check-value
                 200000))

(module+ try
  (define (try-happy . vs)
    (apply
     (☯ (try +
          [exn:break? 10]
          [exn:fail? 0]))
     vs))

  (define (try-error . vs)
    (apply
     (☯ (try string-append
          [exn:break? 10]
          [exn:fail? 0]))
     vs))

  (run-summary-benchmark "try"
                         +
                         (try-happy check-values 20000)
                         (try-error check-values 20000)))

(module+ currying
  (define (currying . vs)
    (apply (☯ (+ 3)) vs))

  (run-benchmark currying
                 check-values
                 200000))

(module+ template
  (define (template . vs)
    (apply (☯ (+ _ 3 _ 5 _ _ _ _ _ _ _ _)) vs))

  (run-benchmark template
                 check-values
                 200000))

(module+ catchall-template
  (define (catchall-template . vs)
    (apply (☯ (+ 3 __ 5)) vs))

  (run-benchmark catchall-template
                 check-values
                 200000))

(module+ if
  (define (if . vs)
    (apply (☯ (if < 'hi 'bye))
           vs))

  (run-benchmark if
                 check-values
                 500000))

(module+ when
  (define (when . vs)
    (apply (☯ (when < 'hi))
           vs))

  (run-benchmark when
                 check-values
                 500000))

(module+ unless
  (define (unless . vs)
    (apply (☯ (unless < 'hi))
           vs))

  (run-benchmark unless
                 check-values
                 500000))

(module+ switch
  (define (switch . vs)
    (apply (☯ (switch
                [< 'hi]
                [> 'bye]))
           vs))

  (define (switch-else . vs)
    (apply (☯ (switch
                [> 'hi]
                [else 'bye]))
           vs))

  (define (switch-divert . vs)
    (apply (☯ (switch (% _ 2>)
                [> 'hi]
                [else 'bye]))
           vs))

  (run-summary-benchmark "switch"
                         +
                         (switch check-values 200000)
                         (switch-else check-values 200000)
                         (switch-divert check-values 200000)))

(module+ sieve
  (define (sieve . vs)
    (apply (☯ (sieve positive? 'hi 'bye))
           vs))

  (run-benchmark sieve
                 check-values
                 100000))

(module+ gate
  (define (gate . vs)
    (apply (☯ (gate <))
           vs))

  (run-benchmark gate
                 check-values
                 500000))

(module+ input-aliases
  (define (input-alias-1 . vs)
    (apply (☯ 1>)
           vs))

  (define (input-alias-5 . vs)
    (apply (☯ 5>)
           vs))

  (define (input-alias-9 . vs)
    (apply (☯ 9>)
           vs))

  (run-summary-benchmark "input aliases"
                         +
                         (input-alias-1
                          check-values
                          100000)
                         (input-alias-5
                          check-values
                          100000)
                         (input-alias-9
                          check-values
                          100000)))

(module+ main
  (require (submod ".." one-of?)
           (submod ".." and)
           (submod ".." or)
           (submod ".." not)
           (submod ".." and%)
           (submod ".." or%)
           (submod ".." group)
           (submod ".." count)
           (submod ".." relay)
           (submod ".." relay*)
           (submod ".." amp)
           (submod ".." ground)
           (submod ".." thread)
           (submod ".." thread-right)
           (submod ".." crossover)
           (submod ".." all)
           (submod ".." any)
           (submod ".." none)
           (submod ".." all?)
           (submod ".." any?)
           (submod ".." none?)
           (submod ".." collect)
           (submod ".." sep)
           (submod ".." gen)
           (submod ".." esc)
           (submod ".." AND)
           (submod ".." OR)
           (submod ".." NOT)
           (submod ".." NAND)
           (submod ".." NOR)
           (submod ".." XOR)
           (submod ".." XNOR)
           (submod ".." tee)
           (submod ".." try)
           (submod ".." currying)
           (submod ".." template)
           (submod ".." catchall-template)
           (submod ".." if)
           (submod ".." when)
           (submod ".." unless)
           (submod ".." switch)
           (submod ".." sieve)
           (submod ".." gate)
           (submod ".." input-aliases)))
