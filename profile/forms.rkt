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

(run-benchmark "one-of?"
               check-value
               (local one-of?)
               100000)

(run-benchmark "and"
               check-value
               (local and)
               200000)

(run-benchmark "or"
               check-value
               (local or)
               200000)

(run-benchmark "not"
               check-value
               (local not)
               200000)

(run-benchmark "and%"
               check-two-values
               (local and%)
               200000)

(run-benchmark "or%"
               check-two-values
               (local or%)
               200000)

(run-benchmark "group"
               check-values
               (local group)
               200000)

(run-benchmark "count"
               check-values
               (local count)
               1000000)

(run-benchmark "relay"
               check-values
               (local relay)
               50000)

(run-benchmark "amp"
               check-values
               (local amp)
               300000)

(run-benchmark "ground"
               check-values
               (local ground)
               200000)

(run-benchmark "thread"
               check-values
               (local thread)
               200000)

(run-benchmark "thread-right"
               check-values
               (local thread-right)
               200000)

(run-benchmark "crossover"
               check-values
               (local crossover)
               200000)

(run-benchmark "all"
               check-values
               (local all)
               200000)

(run-benchmark "any"
               check-values
               (local any)
               200000)

(run-benchmark "none"
               check-values
               (local none)
               200000)

(run-benchmark "all?"
               check-values
               (local all?)
               200000)

(run-benchmark "any?"
               check-values
               (local any?)
               200000)

(run-benchmark "none?"
               check-values
               (local none?)
               200000)

(run-benchmark "collect"
               check-values
               (local collect)
               1000000)

(run-benchmark "sep"
               check-list
               (local sep)
               1000000)

(run-benchmark "gen"
               check-values
               (local gen)
               1000000)

(run-benchmark "esc"
               check-values
               (local esc)
               1000000)

(run-benchmark "AND"
               check-values
               (local AND)
               200000)

(run-benchmark "OR"
               check-values
               (local OR)
               200000)

(run-benchmark "NOT"
               check-value
               (local NOT)
               200000)

(run-benchmark "NAND"
               check-values
               (local NAND)
               200000)

(run-benchmark "NOR"
               check-values
               (local NOR)
               200000)

(run-benchmark "XOR"
               check-values
               (local XOR)
               200000)

(run-benchmark "XNOR"
               check-values
               (local XNOR)
               200000)
