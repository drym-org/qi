#!/usr/bin/env racket
#lang racket/base

#|
To add a benchmark for a new form:

1. Add a submodule for it which provides a `run` function taking no
arguments. This function will be expected to exercise the new form and
return a time taken. The `run` function typically uses one of the
utility macros `run-benchmark` or `run-summary-benchmark`, and
provides it one of the helper functions `check-value` (to invoke the
form with a single value each time during benchmarking) or
`check-values` (to invoke the form with multiple values each time
during benchmarking).

2. Require the submodule in the `main` submodule with an appropriate
prefix (see other examples)

3. Add the required `run` function to the `env` hash in the main
submodule. This will ensure that it gets picked up when the benchmarks
for the forms are run.
|#

(module one-of? "forms-base.rkt"
  (provide run)

  (define (~one-of? v)
    ((☯ (one-of? 3 5 7))
     v))

  (define (run)
    (run-benchmark ~one-of?
                   check-value
                   100000)))

(module and "forms-base.rkt"
  (provide run)

  (define (~and v)
    ((☯ (and positive? integer?))
     v))

  (define (run)
    (run-benchmark ~and
                   check-value
                   200000)))

(module or "forms-base.rkt"
  (provide run)

  (define (~or v)
    ((☯ (or positive? integer?))
     v))

  (define (run)
    (run-benchmark ~or
                   check-value
                   200000)))

(module not "forms-base.rkt"
  (provide run)

  (define (~not v)
    ((☯ (not integer?))
     v))

  (define (run)
    (run-benchmark ~not
                   check-value
                   200000)))

(module and% "forms-base.rkt"
  (provide run)

  (define (~and% a b)
    ((☯ (and% positive? integer?))
     a b))

  (define (run)
    (run-benchmark ~and%
                   check-two-values
                   200000)))

(module or% "forms-base.rkt"
  (provide run)

  (define (~or% a b)
    ((☯ (or% positive? integer?))
     a b))

  (define (run)
    (run-benchmark ~or%
                   check-two-values
                   200000)))

(module group "forms-base.rkt"
  (provide run)

  (define (~group . vs)
    (apply
     (☯ (~> (group 2 + _)
            (group 3 + _)
            (group 4 + _)
            +))
     vs))

  (define (run)
    (run-benchmark ~group
                   check-values
                   200000)))

(module count "forms-base.rkt"
  (provide run)

  (define (~count . vs)
    (apply
     (☯ count)
     vs))

  (define (run)
    (run-benchmark ~count
                   check-values
                   1000000)))

(module relay "forms-base.rkt"
  (provide run)

  (define (~relay . vs)
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

  (define (run)
    (run-benchmark ~relay
                   check-values
                   50000)))

(module relay* "forms-base.rkt"
  (provide run)

  (define (~relay* . vs)
    (apply
     (☯ (==* add1
             sub1
             sqr
             +))
     vs))

  (define (run)
    (run-benchmark ~relay*
                   check-values
                   50000)))

(module amp "forms-base.rkt"
  (provide run)

  (define (~amp . vs)
    (apply
     (☯ (>< sqr))
     vs))

  (define (run)
    (run-benchmark ~amp
                   check-values
                   300000)))

(module ground "forms-base.rkt"
  (provide run)

  (define (~ground . vs)
    (apply
     (☯ ⏚)
     vs))

  (define (run)
    (run-benchmark ~ground
                   check-values
                   200000)))

(module thread "forms-base.rkt"
  (provide run)

  (define (~thread . vs)
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

  (define (run)
    (run-benchmark ~thread
                   check-values
                   200000)))

(module thread-right "forms-base.rkt"
  (provide run)

  (define (~thread-right . vs)
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

  (define (run)
    (run-benchmark ~thread-right
                   check-values
                   200000)))

(module crossover "forms-base.rkt"
  (provide run)

  (define (~crossover . vs)
    (apply
     (☯ X)
     vs))

  (define (run)
    (run-benchmark ~crossover
                   check-values
                   200000)))

(module all "forms-base.rkt"
  (provide run)

  (define (~all . vs)
    (apply
     (☯ (all positive?))
     vs))

  (define (run)
    (run-benchmark ~all
                   check-values
                   200000)))

(module any "forms-base.rkt"
  (provide run)

  (define (~any . vs)
    (apply
     (☯ (any positive?))
     vs))

  (define (run)
    (run-benchmark ~any
                   check-values
                   200000)))

(module none "forms-base.rkt"
  (provide run)

  (define (~none . vs)
    (apply
     (☯ (none positive?))
     vs))

  (define (run)
    (run-benchmark ~none
                   check-values
                   200000)))

(module all? "forms-base.rkt"
  (provide run)

  (define (~all? . vs)
    (apply
     (☯ all?)
     vs))

  (define (run)
    (run-benchmark ~all?
                   check-values
                   200000)))

(module any? "forms-base.rkt"
  (provide run)

  (define (~any? . vs)
    (apply
     (☯ any?)
     vs))

  (define (run)
    (run-benchmark ~any?
                   check-values
                   200000)))

(module none? "forms-base.rkt"
  (provide run)

  (define (~none? . vs)
    (apply
     (☯ none?)
     vs))

  (define (run)
    (run-benchmark ~none?
                   check-values
                   200000)))

(module collect "forms-base.rkt"
  (provide run)

  (define (~collect . vs)
    (apply
     (☯ ▽)
     vs))

  (define (run)
    (run-benchmark ~collect
                   check-values
                   1000000)))

(module sep "forms-base.rkt"
  (provide run)

  (define (~sep v)
    ((☯ △)
     v))

  (define (run)
    (run-benchmark ~sep
                   check-list
                   1000000)))

(module gen "forms-base.rkt"
  (provide run)

  (define (~gen . vs)
    (apply
     (☯ (gen 1 2 3))
     vs))

  (define (run)
    (run-benchmark ~gen
                   check-values
                   1000000)))

(module esc "forms-base.rkt"
  (provide run)

  (define (~esc . vs)
    (apply
     (☯ (esc (λ args args)))
     vs))

  (define (run)
    (run-benchmark ~esc
                   check-values
                   1000000)))

(module AND "forms-base.rkt"
  (provide run)

  (define (~AND . vs)
    (apply
     (☯ AND)
     vs))

  (define (run)
    (run-benchmark ~AND
                   check-values
                   200000)))

(module OR "forms-base.rkt"
  (provide run)

  (define (~OR . vs)
    (apply
     (☯ OR)
     vs))

  (define (run)
    (run-benchmark ~OR
                   check-values
                   200000)))

(module NOT "forms-base.rkt"
  (provide run)

  (define (~NOT v)
    ((☯ NOT)
     v))

  (define (run)
    (run-benchmark ~NOT
                   check-value
                   200000)))

(module NAND "forms-base.rkt"
  (provide run)

  (define (~NAND . vs)
    (apply
     (☯ NAND)
     vs))

  (define (run)
    (run-benchmark ~NAND
                   check-values
                   200000)))

(module NOR "forms-base.rkt"
  (provide run)

  (define (~NOR . vs)
    (apply
     (☯ NOR)
     vs))

  (define (run)
    (run-benchmark ~NOR
                   check-values
                   200000)))

(module XOR "forms-base.rkt"
  (provide run)

  (define (~XOR . vs)
    (apply
     (☯ XOR)
     vs))

  (define (run)
    (run-benchmark ~XOR
                   check-values
                   200000)))

(module XNOR "forms-base.rkt"
  (provide run)

  (define (~XNOR . vs)
    (apply
     (☯ XNOR)
     vs))

  (define (run)
    (run-benchmark ~XNOR
                   check-values
                   200000)))

(module tee "forms-base.rkt"
  (provide run)

  (define (~tee v)
    ((☯ (-< add1 sub1 sqr))
     v))

  (define (run)
    (run-benchmark ~tee
                   check-value
                   200000)))

(module try "forms-base.rkt"
  (provide run)

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

  (define (run)
    (run-summary-benchmark "try"
                           +
                           (try-happy check-values 20000)
                           (try-error check-values 20000))))

(module currying "forms-base.rkt"
  (provide run)

  (define (currying . vs)
    (apply (☯ (+ 3)) vs))

  (define (run)
    (run-benchmark currying
                   check-values
                   200000)))

(module template "forms-base.rkt"
  (provide run)

  (define (template . vs)
    (apply (☯ (+ _ 3 _ 5 _ _ _ _ _ _ _ _)) vs))

  (define (run)
    (run-benchmark template
                   check-values
                   200000)))

(module catchall-template "forms-base.rkt"
  (provide run)

  (define (catchall-template . vs)
    (apply (☯ (+ 3 __ 5)) vs))

  (define (run)
    (run-benchmark catchall-template
                   check-values
                   200000)))

(module if "forms-base.rkt"
  (provide run)

  (define (~if . vs)
    (apply (☯ (if < 'hi 'bye))
           vs))

  (define (run)
    (run-benchmark ~if
                   check-values
                   500000)))

(module when "forms-base.rkt"
  (provide run)

  (define (~when . vs)
    (apply (☯ (when < 'hi))
           vs))

  (define (run)
    (run-benchmark ~when
                   check-values
                   500000)))

(module unless "forms-base.rkt"
  (provide run)

  (define (~unless . vs)
    (apply (☯ (unless < 'hi))
           vs))

  (define (run)
    (run-benchmark ~unless
                   check-values
                   500000)))

(module switch "forms-base.rkt"
  (provide run)

  (define (switch-basic . vs)
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

  (define (run)
    (run-summary-benchmark "switch"
                           +
                           (switch-basic check-values 200000)
                           (switch-else check-values 200000)
                           (switch-divert check-values 200000))))

(module sieve "forms-base.rkt"
  (provide run)

  (define (~sieve . vs)
    (apply (☯ (sieve positive? 'hi 'bye))
           vs))

  (define (run)
    (run-benchmark ~sieve
                   check-values
                   100000)))

(module partition "forms-base.rkt"
  (provide run)
  (define (~partition . vs)
    (apply (flow (partition [negative? *]
                            [zero? count]
                            [positive? +]))
           vs))
  (define (run)
    (run-benchmark ~partition check-values 100000)))

(module gate "forms-base.rkt"
  (provide run)

  (define (~gate . vs)
    (apply (☯ (gate <))
           vs))

  (define (run)
    (run-benchmark ~gate
                   check-values
                   500000)))

(module input-aliases "forms-base.rkt"
  (provide run)

  (define (input-alias-1 . vs)
    (apply (☯ 1>)
           vs))

  (define (input-alias-5 . vs)
    (apply (☯ 5>)
           vs))

  (define (input-alias-9 . vs)
    (apply (☯ 9>)
           vs))

  (define (run)
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
                            100000))))

(module fanout "forms-base.rkt"
  (provide run)

  (define (fanout-small-n . vs)
    (apply (☯ (fanout 3))
           vs))

  (define (fanout-large-n . vs)
    (apply (☯ (fanout 100))
           vs))

  (define (run)
    (run-summary-benchmark "fanout"
                           +
                           (fanout-small-n
                            check-values
                            200000)
                           (fanout-large-n
                            check-values
                            20000))))

(module inverter "forms-base.rkt"
  (provide run)

  (define (~inverter . vs)
    (apply (☯ inverter)
           vs))

  (define (run)
    (run-benchmark ~inverter
                   check-values
                   200000)))

(module feedback "forms-base.rkt"
  (provide run)

  (define (feedback-number . vs)
    (apply (☯ (feedback 5 _))
           vs))

  (define (feedback-while v)
    ((☯ (feedback (while (< 1024)) (~> add1 (* 2))))
     v))

  (define (feedback-control v)
    ((☯ (~> (-< 10 (gen sub1) 10)
            feedback))
     v))

  (define (run)
    (run-summary-benchmark "feedback"
                           +
                           (feedback-number
                            check-values
                            20000)
                           (feedback-while
                            check-value
                            20000)
                           (feedback-control
                            check-value
                            70000))))

(module select "forms-base.rkt"
  (provide run)

  (define (~select . vs)
    (apply (☯ (select 3 5 8))
           vs))

  (define (run)
    (run-benchmark ~select
                   check-values
                   20000)))

(module block "forms-base.rkt"
  (provide run)

  (define (~block . vs)
    (apply (☯ (block 3 5 8))
           vs))

  (define (run)
    (run-benchmark ~block
                   check-values
                   20000)))

(module bundle "forms-base.rkt"
  (provide run)

  (define (~bundle . vs)
    (apply (☯ (bundle (3 5 8) + -))
           vs))

  (define (run)
    (run-benchmark ~bundle
                   check-values
                   20000)))

(module effect "forms-base.rkt"
  (provide run)

  (define (~effect . vs)
    (apply (☯ (effect + +))
           vs))

  (define (run)
    (run-benchmark ~effect
                   check-values
                   200000)))

(module live? "forms-base.rkt"
  (provide run)

  (define (~live? . vs)
    (apply (☯ live?)
           vs))

  (define (run)
    (run-benchmark ~live?
                   check-values
                   500000)))

(module rectify "forms-base.rkt"
  (provide run)

  (define (~rectify . vs)
    (apply (☯ (rectify #f))
           vs))

  (define (run)
    (run-benchmark ~rectify
                   check-values
                   500000)))

(module pass "forms-base.rkt"
  (provide run)

  (define (~pass . vs)
    (apply (☯ (pass odd?))
           vs))

  (define (run)
    (run-benchmark ~pass
                   check-values
                   200000)))

(module foldl "forms-base.rkt"
  (provide run)

  (define (~foldl . vs)
    (apply (☯ (>> +))
           vs))

  (define (run)
    (run-benchmark ~foldl
                   check-values
                   200000)))

(module foldr "forms-base.rkt"
  (provide run)

  (define (~foldr . vs)
    (apply (☯ (<< +))
           vs))

  (define (run)
    (run-benchmark ~foldr
                   check-values
                   200000)))

(module loop "forms-base.rkt"
  (provide run)

  (define (~loop . vs)
    (apply (☯ (loop live? sqr))
           vs))

  (define (run)
    (run-benchmark ~loop
                   check-values
                   100000)))

(module loop2 "forms-base.rkt"
  (provide run)

  (define (~loop2 . vs)
    ((☯ (~> (loop2 (~> 1> (not null?))
                   sqr
                   +)))
     vs
     0))

  (define (run)
    (run-benchmark ~loop2
                   check-values
                   100000)))

(module apply "forms-base.rkt"
  (provide run)

  (require (only-in racket/base
                    [apply b:apply]))

  (define (~apply . vs)
    (b:apply (☯ apply)
             (cons + vs)))

  (define (run)
    (run-benchmark ~apply
                   check-values
                   300000)))

(module clos "forms-base.rkt"
  (provide run)

  ;; TODO: this uses a lot of other things besides `clos` and is
  ;; likely not a reliable indicator
  (define (~clos . vs)
    (apply (☯ (~> (-< (~> 5 (clos *)) _)
                  apply))
           vs))

  (define (run)
    (run-benchmark ~clos
                   check-values
                   100000)))

;; To run benchmarks for a form interactively, use e.g.:
;; (require (submod "." fanout))
;; (run)

(module* main cli

  (require
   (prefix-in one-of?: (submod ".." one-of?))
   (prefix-in and: (submod ".." and))
   (prefix-in or: (submod ".." or))
   (prefix-in not: (submod ".." not))
   (prefix-in and%: (submod ".." and%))
   (prefix-in or%: (submod ".." or%))
   (prefix-in group: (submod ".." group))
   (prefix-in count: (submod ".." count))
   (prefix-in relay: (submod ".." relay))
   (prefix-in relay*: (submod ".." relay*))
   (prefix-in amp: (submod ".." amp))
   (prefix-in ground: (submod ".." ground))
   (prefix-in thread: (submod ".." thread))
   (prefix-in thread-right: (submod ".." thread-right))
   (prefix-in crossover: (submod ".." crossover))
   (prefix-in all: (submod ".." all))
   (prefix-in any: (submod ".." any))
   (prefix-in none: (submod ".." none))
   (prefix-in all?: (submod ".." all?))
   (prefix-in any?: (submod ".." any?))
   (prefix-in none?: (submod ".." none?))
   (prefix-in collect: (submod ".." collect))
   (prefix-in sep: (submod ".." sep))
   (prefix-in gen: (submod ".." gen))
   (prefix-in esc: (submod ".." esc))
   (prefix-in AND: (submod ".." AND))
   (prefix-in OR: (submod ".." OR))
   (prefix-in NOT: (submod ".." NOT))
   (prefix-in NAND: (submod ".." NAND))
   (prefix-in NOR: (submod ".." NOR))
   (prefix-in XOR: (submod ".." XOR))
   (prefix-in XNOR: (submod ".." XNOR))
   (prefix-in tee: (submod ".." tee))
   (prefix-in try: (submod ".." try))
   (prefix-in currying: (submod ".." currying))
   (prefix-in template: (submod ".." template))
   (prefix-in catchall-template: (submod ".." catchall-template))
   (prefix-in if: (submod ".." if))
   (prefix-in when: (submod ".." when))
   (prefix-in unless: (submod ".." unless))
   (prefix-in switch: (submod ".." switch))
   (prefix-in sieve: (submod ".." sieve))
   (prefix-in partition: (submod ".." partition))
   (prefix-in gate: (submod ".." gate))
   (prefix-in input-aliases: (submod ".." input-aliases))
   (prefix-in fanout: (submod ".." fanout))
   (prefix-in inverter: (submod ".." inverter))
   (prefix-in feedback: (submod ".." feedback))
   (prefix-in select: (submod ".." select))
   (prefix-in block: (submod ".." block))
   (prefix-in bundle: (submod ".." bundle))
   (prefix-in effect: (submod ".." effect))
   (prefix-in live?: (submod ".." live?))
   (prefix-in rectify: (submod ".." rectify))
   (prefix-in pass: (submod ".." pass))
   (prefix-in foldl: (submod ".." foldl))
   (prefix-in foldr: (submod ".." foldr))
   (prefix-in loop: (submod ".." loop))
   (prefix-in loop2: (submod ".." loop2))
   (prefix-in apply: (submod ".." apply))
   (prefix-in clos: (submod ".." clos)))

  (require racket/match
           racket/format
           relation
           qi
           (only-in "util.rkt"
                    only-if
                    for/call))

  ;; It would be great if we could get the value of a variable
  ;; by using its (string) name, but (eval (string->symbol name))
  ;; doesn't find it. So instead, we reify the "lexical environment"
  ;; here manually, so that the values can be looked up at runtime
  ;; based on the string names (note that the value is always the key
  ;; + ":" + "run")
  (define env
    (hash
     "one-of?" one-of?:run
     "and" and:run
     "or" or:run
     "not" not:run
     "and%" and%:run
     "or%" or%:run
     "group" group:run
     "count" count:run
     "relay" relay:run
     "relay*" relay*:run
     "amp" amp:run
     "ground" ground:run
     "thread" thread:run
     "thread-right" thread-right:run
     "crossover" crossover:run
     "all" all:run
     "any" any:run
     "none" none:run
     "all?" all?:run
     "any?" any?:run
     "none?" none?:run
     "collect" collect:run
     "sep" sep:run
     "gen" gen:run
     "esc" esc:run
     "AND" AND:run
     "OR" OR:run
     "NOT" NOT:run
     "NAND" NAND:run
     "NOR" NOR:run
     "XOR" XOR:run
     "XNOR" XNOR:run
     "tee" tee:run
     "try" try:run
     "currying" currying:run
     "template" template:run
     "catchall-template" catchall-template:run
     "if" if:run
     "when" when:run
     "unless" unless:run
     "switch" switch:run
     "sieve" sieve:run
     "partition" partition:run
     "gate" gate:run
     "input-aliases" input-aliases:run
     "fanout" fanout:run
     "inverter" inverter:run
     "feedback" feedback:run
     "select" select:run
     "block" block:run
     "bundle" bundle:run
     "effect" effect:run
     "live?" live?:run
     "rectify" rectify:run
     "pass" pass:run
     "foldl" foldl:run
     "foldr" foldr:run
     "loop" loop:run
     "loop2" loop2:run
     "apply" apply:run
     "clos" clos:run))

  (flag (forms #:param [forms null] name)
    ("-f" "--form" "Forms to benchmark")
    (forms (cons name (forms))))

  (constraint (multi forms))

  (help
   (usage (~a "Run benchmarks for individual Qi forms "
              "(by default, all of them).")))

  (program (main)
    (let ([fs (~>> ((forms))
                   (only-if null?
                     (gen (hash-keys env)))
                   (sort <))])
      (for ([f fs])
        (match-let ([(list name ms) ((hash-ref env f))])
          (displayln (~a name ": " ms " ms"))))))

  (run main))
