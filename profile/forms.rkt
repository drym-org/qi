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

(run-benchmark "one-of?"
               check-value
               one-of?
               100000)

(run-benchmark "and"
               check-value
               and
               200000)

(run-benchmark "or"
               check-value
               or
               200000)

(run-benchmark "not"
               check-value
               not
               200000)

(run-benchmark "and%"
               check-two-values
               and%
               200000)

(run-benchmark "or%"
               check-two-values
               or%
               200000)

(run-benchmark "group"
               check-values
               group
               200000)

(run-benchmark "count"
               check-values
               count
               1000000)

(run-benchmark "relay"
               check-values
               relay
               50000)

(run-benchmark "relay*"
               check-values
               relay*
               50000)

(run-benchmark "amp"
               check-values
               amp
               300000)

(run-benchmark "ground"
               check-values
               ground
               200000)

(run-benchmark "thread"
               check-values
               thread
               200000)

(run-benchmark "thread-right"
               check-values
               thread-right
               200000)

(run-benchmark "crossover"
               check-values
               crossover
               200000)

(run-benchmark "all"
               check-values
               all
               200000)

(run-benchmark "any"
               check-values
               any
               200000)

(run-benchmark "none"
               check-values
               none
               200000)

(run-benchmark "all?"
               check-values
               all?
               200000)

(run-benchmark "any?"
               check-values
               any?
               200000)

(run-benchmark "none?"
               check-values
               none?
               200000)

(run-benchmark "collect"
               check-values
               collect
               1000000)

(run-benchmark "sep"
               check-list
               sep
               1000000)

(run-benchmark "gen"
               check-values
               gen
               1000000)

(run-benchmark "esc"
               check-values
               esc
               1000000)

(run-benchmark "AND"
               check-values
               AND
               200000)

(run-benchmark "OR"
               check-values
               OR
               200000)

(run-benchmark "NOT"
               check-value
               NOT
               200000)

(run-benchmark "NAND"
               check-values
               NAND
               200000)

(run-benchmark "NOR"
               check-values
               NOR
               200000)

(run-benchmark "XOR"
               check-values
               XOR
               200000)

(run-benchmark "XNOR"
               check-values
               XNOR
               200000)

(run-benchmark "tee"
               check-value
               tee
               200000)

(run-benchmark "try"
               check-values
               try
               20000)

(run-benchmark "currying"
               check-values
               currying
               200000)

(run-benchmark "template"
               check-values
               template
               200000)

(run-benchmark "catchall-template"
               check-values
               catchall-template
               200000)

(run-benchmark "if"
               check-values
               if
               500000)

(run-benchmark "when"
               check-values
               when
               500000)

(run-benchmark "unless"
               check-values
               unless
               500000)

(run-benchmark "switch"
               check-values
               switch
               500000)
