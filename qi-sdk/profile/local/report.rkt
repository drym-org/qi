#!/usr/bin/env racket
#lang cli

(require racket/match
         racket/format
         relation
         qi
         (only-in "../util.rkt"
                  only-if
                  for/call
                  write-csv
                  format-output)
         "../regression.rkt"
         (submod "benchmarks.rkt" main))

(flag (selected #:param [selected null] name)
  ("-s" "--select" "Select form to benchmark")
  (selected (cons name (selected))))

(constraint (multi selected))

(help
 (usage
  (~a "Run benchmarks for individual Qi forms "
      "(by default, all of them), reporting the results "
      "in a configurable output format.")))

(flag (output-format #:param [output-format ""] fmt)
  ("-f"
   "--format"
   "Output format to use, either 'json' or 'csv'. If none is specified, no output is generated.")
  (output-format fmt))

(flag (regression-file #:param [regression-file #f] reg-file)
  ("-r" "--regression" "'Before' data to compute regression against")
  (regression-file reg-file))

(program (main)
  (let ([output (benchmark (selected))])
    (if (regression-file)
        ;; TODO: regression ignores any flags and is a parallel path
        ;; it should be properly incorporated into the CLI
        (let ([before (parse-benchmarks (parse-json-file (regression-file)))]
              [after (parse-benchmarks output)])
          (compute-regression before after))
        (format-output output (output-format)))))

;; To run benchmarks for a form interactively, use e.g.:
;; (run main #("-s" "fanout"))

(run main)
