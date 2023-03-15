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
         "../intrinsic/regression.rkt"
         "intrinsic.rkt")

(flag (selected #:param [selected null] name)
  ("-s" "--select" "Select benchmark by name")
  (selected (cons name (selected))))

(constraint (multi selected))

(help
 (usage
  (~a "Run competitive benchmarks between Qi and Racket, "
      "reporting the results in a configurable output format.")))

(flag (output-format #:param [output-format ""] fmt)
  ("-f"
   "--format"
   "Output format to use, either 'json' or 'csv'. If none is specified, no output is generated.")
  (output-format fmt))

(flag (regression-file #:param [regression-file #f] reg-file)
  ("-r" "--regression" "'Before' data to compute regression against")
  (regression-file reg-file))

(program (main)
  (displayln "\nRunning competitive benchmarks..." (current-error-port))

  (let ([output (benchmark 'qi (selected))])
    (if (regression-file)
        (let ([before (parse-benchmarks (parse-json-file (regression-file)))]
              [after (parse-benchmarks output)])
          (compute-regression before after))
        (format-output output (output-format)))))

;; To run benchmarks for a form interactively, use e.g.:
;; (run main #("-s" "composition"))

(run main #("-s" "composition"))
