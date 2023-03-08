#!/usr/bin/env racket
#lang cli

(require "../regression.rkt")

(require racket/match
         racket/format
         relation
         qi
         (only-in "../util.rkt"
                  only-if
                  for/call
                  write-csv
                  format-output))
(require
 (submod "benchmarks.rkt" main))

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

(program (main)
  (let ([output (benchmark (forms))])
    (if (regression-file)
        (let ([before (parse-benchmarks (parse-json-file (regression-file)))]
              [after (parse-benchmarks output)])
          (compute-regression before after))
        (format-output output (output-format)))))

;; To run benchmarks for a form interactively, use e.g.:
;; (run main #("-f" "fanout"))

(run main)
