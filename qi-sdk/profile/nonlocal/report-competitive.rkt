#!/usr/bin/env racket
#lang cli

(require racket/format
         (only-in "../util.rkt"
                  format-output)
         "../regression.rkt"
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

(program (main)
  (displayln "\nRunning competitive benchmarks..." (current-error-port))

  (let* ([racket-output
          (begin (displayln "\nRunning Racket benchmarks..." (current-error-port))
                 (benchmark "racket" (selected)))]
         [qi-output
          (begin (displayln "\nRunning Qi benchmarks..." (current-error-port))
                 (benchmark "qi" (selected)))]
         [before (parse-benchmarks racket-output)]
         [after (parse-benchmarks qi-output)])
    (format-output (compute-regression before after)
                   (output-format))))

;; To run benchmarks for a form interactively, use e.g.:
;; (run main #("-s" "composition"))

(run main)
