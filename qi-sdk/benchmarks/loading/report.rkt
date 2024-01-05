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
         "loadlib.rkt")

(help
 (usage
  (~a "Measure module load time, i.e. the time taken by (require qi).")))

(flag (output-format #:param [output-format ""] fmt)
  ("-f"
   "--format"
   "Output format to use, either 'json' or 'csv'. If none is specified, no output is generated.")
  (output-format fmt))

(flag (regression-file #:param [regression-file #f] reg-file)
  ("-r" "--regression" "'Before' data to compute regression against")
  (regression-file reg-file))

(program (main)
  (displayln "\nMeasuring module load time..." (current-error-port))

  (let ([output (require-latency "qi")])
    (if (regression-file)
        (let ([before (parse-benchmarks (parse-json-file (regression-file)))]
              [after (parse-benchmarks output)])
          (format-output (compute-regression before after)
                         (output-format)))
        (format-output output (output-format)))))

(run main)
