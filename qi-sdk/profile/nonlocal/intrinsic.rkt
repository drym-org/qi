#!/usr/bin/env racket
#lang racket/base

(provide benchmark)

(require racket/runtime-path
         "../util.rkt"
         "spec.rkt")

;; We use `eval` in this module to `require` the appropriate objective
;; functions (either Racket or Qi) for benchmarking in a dynamically
;; constructed namespace (following
;; https://docs.racket-lang.org/guide/eval.html). This allows us to
;; define those functions symmetrically in the Racket and Qi modules, and
;; invoke them in a common way here. But as this eval namespace is
;; dynamically constructed, the require paths are interpreted as being
;; relative to the path from which this module is executed (e.g. either
;; locally from this folder or from the qi root via the Makefile) and may
;; therefore fail to find the modules if executed from "the wrong"
;; location.  To avoid this, we set the "load relative" directory to the
;; module's path, so that requiring modules is always relative to the
;; present module path, allowing it to behave the same no matter where it
;; is executed from.  Another possibility is to simply assume that the
;; qi-sdk package is installed so that the modules are available via
;; collection paths, but currently, having the SDK "officially" installed
;; slows down building of other packages for reasons as yet unknown. See:
;; https://github.com/drym-org/qi/wiki/Installing-the-SDK#install-the-sdk
;; So for now, we use this fix so that we can have the SDK remain
;; uninstalled.

(define-runtime-path lexical-module-path ".")

(define (benchmark language benchmarks-to-run)
  (let ([namespace (make-base-namespace)]
        [benchmarks-to-run (if (null? benchmarks-to-run)
                               (map bm-name specs)
                               benchmarks-to-run)])
    (cond [(equal? "qi" language)
           (parameterize ([current-load-relative-directory lexical-module-path])
             (eval '(require "qi/main.rkt")
                   namespace))]
          [(equal? "racket" language)
           (parameterize ([current-load-relative-directory lexical-module-path])
             (eval '(require "racket/main.rkt")
                   namespace))])

    (for/list ([spec specs]
               #:when (member (bm-name spec) benchmarks-to-run))
      (let ([name (bm-name spec)]
            [exerciser (bm-exerciser spec)]
            [f (eval
                ;; the first datum in the benchmark name needs to be a function name
                (read (open-input-string (bm-name spec))) namespace)]
            [n-times (bm-times spec)])
        (run-nonlocal-benchmark name exerciser f n-times)))))
