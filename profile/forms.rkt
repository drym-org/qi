#lang racket/base

(require (only-in data/collection
                  cycle
                  take
                  in)
         (only-in math sqr)
         racket/match
         qi
         racket/format)

(require "util.rkt")

(define (group . vs)
  (apply
   (☯ (~> (group 2 + _)
          (group 3 + _)
          (group 4 + _)
          +))
   vs))

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

(define (relay* . vs)
  (apply
   (☯ (==* add1
           sub1
           sqr
           +))
   vs))

(define (amp . vs)
  (apply
   (☯ (>< sqr))
   vs))

(define (count . vs)
  (apply
   (☯ count)
   vs))

(define (ground . vs)
  (apply
   (☯ ⏚)
   vs))

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

(define (crossover . vs)
  (apply
   (☯ X)
   vs))

(define (one-of? v)
  ((☯ (one-of? 3 5 7))
   v))

(define (and v)
  ((☯ (and positive? integer?))
   v))

(define (or v)
  ((☯ (or positive? integer?))
   v))

(define (not v)
  ((☯ (not integer?))
   v))

(define (and% a b)
  ((☯ (and% positive? integer?))
   a b))

(define (or% a b)
  ((☯ (or% positive? integer?))
   a b))

(define (all . vs)
  (apply
   (☯ (all positive?))
   vs))

(define (any . vs)
  (apply
   (☯ (any positive?))
   vs))

(define (none . vs)
  (apply
   (☯ (none positive?))
   vs))

(define (all? . vs)
  (apply
   (☯ all?)
   vs))

(define (any? . vs)
  (apply
   (☯ any?)
   vs))

(define (none? . vs)
  (apply
   (☯ none?)
   vs))

(define (collect . vs)
  (apply
   (☯ ▽)
   vs))

(define (sep v)
  ((☯ △)
   v))

(define (gen . vs)
  (apply
   (☯ (gen 1 2 3))
   vs))

(define (esc . vs)
  (apply
   (☯ (esc (λ args args)))
   vs))

(define (AND . vs)
  (apply
   (☯ AND)
   vs))

(define (OR . vs)
  (apply
   (☯ OR)
   vs))

(define (NOT v)
  ((☯ NOT)
   v))

(define (NAND . vs)
  (apply
   (☯ NAND)
   vs))

(define (NOR . vs)
  (apply
   (☯ NOR)
   vs))

(define (XOR . vs)
  (apply
   (☯ XOR)
   vs))

(define (XNOR . vs)
  (apply
   (☯ XNOR)
   vs))

(define (tee v)
  ((☯ (-< add1 sub1 sqr))
   v))

(define (try . vs)
  (apply
   (☯ (try +
        [exn:break? 10]
        [exn:fail? 0]))
   vs)
  (apply
   (☯ (try string-append
        [exn:break? 10]
        [exn:fail? 0]))
   vs))

(define (currying . vs)
  (apply (☯ (+ 3)) vs))

(define (template . vs)
  (apply (☯ (+ _ 3 _ 5 _ _ _ _ _ _ _ _)) vs))

(define (catchall-template . vs)
  (apply (☯ (+ 3 __ 5)) vs))

(define (if . vs)
  (apply (☯ (if < 'hi 'bye))
         vs))

(define (when . vs)
  (apply (☯ (when < 'hi))
         vs))

(define (unless . vs)
  (apply (☯ (unless < 'hi))
         vs))

(define (switch . vs)
  (apply (☯ (switch
              [< 'hi]
              [> 'bye]))
         vs))

(define (sieve . vs)
  (apply (☯ (sieve positive? 'hi 'bye))
         vs))

(define (gate . vs)
  (apply (☯ (gate <))
         vs))

(define (input-alias-1 . vs)
  (apply (☯ 1>)
         vs))

(define (input-alias-5 . vs)
  (apply (☯ 5>)
         vs))

(define (input-alias-9 . vs)
  (apply (☯ 9>)
         vs))

(run-benchmark one-of?
               check-value
               100000)

(run-benchmark and
               check-value
               200000)

(run-benchmark or
               check-value
               200000)

(run-benchmark not
               check-value
               200000)

(run-benchmark and%
               check-two-values
               200000)

(run-benchmark or%
               check-two-values
               200000)

(run-benchmark group
               check-values
               200000)

(run-benchmark count
               check-values
               1000000)

(run-benchmark relay
               check-values
               50000)

(run-benchmark relay*
               check-values
               50000)

(run-benchmark amp
               check-values
               300000)

(run-benchmark ground
               check-values
               200000)

(run-benchmark thread
               check-values
               200000)

(run-benchmark thread-right
               check-values
               200000)

(run-benchmark crossover
               check-values
               200000)

(run-benchmark all
               check-values
               200000)

(run-benchmark any
               check-values
               200000)

(run-benchmark none
               check-values
               200000)

(run-benchmark all?
               check-values
               200000)

(run-benchmark any?
               check-values
               200000)

(run-benchmark none?
               check-values
               200000)

(run-benchmark collect
               check-values
               1000000)

(run-benchmark sep
               check-list
               1000000)

(run-benchmark gen
               check-values
               1000000)

(run-benchmark esc
               check-values
               1000000)

(run-benchmark AND
               check-values
               200000)

(run-benchmark OR
               check-values
               200000)

(run-benchmark NOT
               check-value
               200000)

(run-benchmark NAND
               check-values
               200000)

(run-benchmark NOR
               check-values
               200000)

(run-benchmark XOR
               check-values
               200000)

(run-benchmark XNOR
               check-values
               200000)

(run-benchmark tee
               check-value
               200000)

(run-benchmark try
               check-values
               20000)

(run-benchmark currying
               check-values
               200000)

(run-benchmark template
               check-values
               200000)

(run-benchmark catchall-template
               check-values
               200000)

(run-benchmark if
               check-values
               500000)

(run-benchmark when
               check-values
               500000)

(run-benchmark unless
               check-values
               500000)

(run-benchmark switch
               check-values
               500000)

(run-benchmark sieve
               check-values
               100000)

(run-benchmark gate
               check-values
               500000)

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
                        100000))
