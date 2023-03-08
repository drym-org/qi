#!/usr/bin/env racket
#lang cli

#|
To add a benchmark for a new form:

1. Add a submodule for it in benchmarks.rkt which provides a `run`
function taking no arguments. This function will be expected to
exercise the new form and return a time taken. The `run` function
typically uses one of the utility macros `run-benchmark` or
`run-summary-benchmark`, and provides it one of the helper functions
`check-value` (to invoke the form with a single value each time during
benchmarking) or `check-values` (to invoke the form with multiple
values each time during benchmarking). Note that at the moment, as a
hack for convenience, `run-benchmark` expects a function with the name
of the form being benchmarked _prefixed with tilde_. This is to avoid
name collisions between this function and the Qi form with the same
name. Basically, just follow one of the numerous examples in this
module to see what this is referring to.

2. Require the submodule in the present module with an appropriate
prefix (see other examples)

3. Add the required `run` function to the `env` hash below.  This will
ensure that it gets picked up when the benchmarks for the forms are
run.
|#

(require
 (prefix-in one-of?: (submod "benchmarks.rkt" one-of?))
 (prefix-in and: (submod "benchmarks.rkt" and))
 (prefix-in or: (submod "benchmarks.rkt" or))
 (prefix-in not: (submod "benchmarks.rkt" not))
 (prefix-in and%: (submod "benchmarks.rkt" and%))
 (prefix-in or%: (submod "benchmarks.rkt" or%))
 (prefix-in group: (submod "benchmarks.rkt" group))
 (prefix-in count: (submod "benchmarks.rkt" count))
 (prefix-in relay: (submod "benchmarks.rkt" relay))
 (prefix-in relay*: (submod "benchmarks.rkt" relay*))
 (prefix-in amp: (submod "benchmarks.rkt" amp))
 (prefix-in ground: (submod "benchmarks.rkt" ground))
 (prefix-in thread: (submod "benchmarks.rkt" thread))
 (prefix-in thread-right: (submod "benchmarks.rkt" thread-right))
 (prefix-in crossover: (submod "benchmarks.rkt" crossover))
 (prefix-in all: (submod "benchmarks.rkt" all))
 (prefix-in any: (submod "benchmarks.rkt" any))
 (prefix-in none: (submod "benchmarks.rkt" none))
 (prefix-in all?: (submod "benchmarks.rkt" all?))
 (prefix-in any?: (submod "benchmarks.rkt" any?))
 (prefix-in none?: (submod "benchmarks.rkt" none?))
 (prefix-in collect: (submod "benchmarks.rkt" collect))
 (prefix-in sep: (submod "benchmarks.rkt" sep))
 (prefix-in gen: (submod "benchmarks.rkt" gen))
 (prefix-in esc: (submod "benchmarks.rkt" esc))
 (prefix-in AND: (submod "benchmarks.rkt" AND))
 (prefix-in OR: (submod "benchmarks.rkt" OR))
 (prefix-in NOT: (submod "benchmarks.rkt" NOT))
 (prefix-in NAND: (submod "benchmarks.rkt" NAND))
 (prefix-in NOR: (submod "benchmarks.rkt" NOR))
 (prefix-in XOR: (submod "benchmarks.rkt" XOR))
 (prefix-in XNOR: (submod "benchmarks.rkt" XNOR))
 (prefix-in tee: (submod "benchmarks.rkt" tee))
 (prefix-in try: (submod "benchmarks.rkt" try))
 (prefix-in currying: (submod "benchmarks.rkt" currying))
 (prefix-in template: (submod "benchmarks.rkt" template))
 (prefix-in catchall-template: (submod "benchmarks.rkt" catchall-template))
 (prefix-in if: (submod "benchmarks.rkt" if))
 (prefix-in when: (submod "benchmarks.rkt" when))
 (prefix-in unless: (submod "benchmarks.rkt" unless))
 (prefix-in switch: (submod "benchmarks.rkt" switch))
 (prefix-in sieve: (submod "benchmarks.rkt" sieve))
 (prefix-in partition: (submod "benchmarks.rkt" partition))
 (prefix-in gate: (submod "benchmarks.rkt" gate))
 (prefix-in input-aliases: (submod "benchmarks.rkt" input-aliases))
 (prefix-in fanout: (submod "benchmarks.rkt" fanout))
 (prefix-in inverter: (submod "benchmarks.rkt" inverter))
 (prefix-in feedback: (submod "benchmarks.rkt" feedback))
 (prefix-in select: (submod "benchmarks.rkt" select))
 (prefix-in block: (submod "benchmarks.rkt" block))
 (prefix-in bundle: (submod "benchmarks.rkt" bundle))
 (prefix-in effect: (submod "benchmarks.rkt" effect))
 (prefix-in live?: (submod "benchmarks.rkt" live?))
 (prefix-in rectify: (submod "benchmarks.rkt" rectify))
 (prefix-in pass: (submod "benchmarks.rkt" pass))
 (prefix-in foldl: (submod "benchmarks.rkt" foldl))
 (prefix-in foldr: (submod "benchmarks.rkt" foldr))
 (prefix-in loop: (submod "benchmarks.rkt" loop))
 (prefix-in loop2: (submod "benchmarks.rkt" loop2))
 (prefix-in apply: (submod "benchmarks.rkt" apply))
 (prefix-in clos: (submod "benchmarks.rkt" clos)))

(require "loadlib.rkt"
         "regression.rkt")

(require racket/match
         racket/format
         relation
         qi
         json
         csv-writing
         (only-in "../util.rkt"
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

(define (write-csv data)
  (~> (data)
      △
      (>< (~> (-< (hash-ref 'name)
                  (hash-ref 'unit)
                  (hash-ref 'value))
              ▽))
      (-< '(name unit value)
          _)
      ▽
      display-table))

(flag (forms #:param [forms null] name)
  ("-f" "--form" "Forms to benchmark")
  (forms (cons name (forms))))

(constraint (multi forms))

(help
 (usage
  (~a "Run benchmarks for individual Qi forms "
      "(by default, all of them), reporting the results "
      "in a configurable output format.")))

(flag (output-format #:param [output-format ""] fmt)
  ("-o"
   "--format"
   "Output format to use, either 'json' or 'csv'. If none is specified, no output is generated.")
  (output-format fmt))

(flag (regression-file #:param [regression-file #f] reg-file)
  ("-r" "--regression" "'Before' data to compute regression against")
  (regression-file reg-file))

(define (format-output output)
  ;; Note: this is a case where declaring "constraints" on the CLI args
  ;; would be useful, instead of using the ad hoc fallback `else` check here
  ;; https://github.com/countvajhula/cli/issues/6
  (cond
    [(equal? (output-format) "json") (write-json output)]
    [(equal? (output-format) "csv") (write-csv output)]
    [(equal? (output-format) "") (values)]
    [else (error (~a "Unrecognized format: " (output-format) "!"))]))

(program (main)
  (define fs (~>> ((forms))
                  (only-if null?
                           (gen (hash-keys env)))
                  (sort <)))
  (define forms-data (for/list ([f (in-list fs)])
                       (match-let ([(list name ms) ((hash-ref env f))])
                         ;; Print results "live" to STDERR, with
                         ;; only the actual output (if desired)
                         ;; going to STDOUT at the end.
                         (displayln (~a name ": " ms " ms")
                                    (current-error-port))
                         (hash 'name name 'unit "ms" 'value ms))))
  (define require-data (list (hash 'name "(require qi)"
                                   'unit "ms"
                                   'value (time-module-ms "qi"))))
  (let ([output (append forms-data require-data)])

    (if (regression-file)
        (let ([before (parse-benchmarks (parse-json-file (regression-file)))]
              [after (parse-benchmarks output)])
          (compute-regression before after))
        (format-output output))))

;; To run benchmarks for a form interactively, use e.g.:
;; (run main #("-f" "fanout"))

(run main)
