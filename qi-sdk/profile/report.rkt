#!/usr/bin/env racket
#lang cli

(require "loading/loadlib.rkt"
         "forms/regression.rkt")

(require racket/match
         racket/format
         relation
         qi
         json
         csv-writing
         (only-in "util.rkt"
                  only-if
                  for/call))
(require
 (submod "forms/benchmarks.rkt" main))

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
  (define forms-data (benchmark (forms)))
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
