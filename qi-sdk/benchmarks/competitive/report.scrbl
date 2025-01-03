#lang scribble/manual

@require[scribble-math/dollar
	 srfi/19
	 vlibench
	 (for-syntax racket/base)
	 racket/cmdline
	 racket/string
	 racket/function]

@;Command-line handling ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
@(define config-profile
  (let ()
    (define profile-box (box 'preview))
    (command-line
      #:once-each
      (("-p" "--profile")
       name
       "profile name to use (use 'list' to list available profiles)"
       (when (equal? name "list")
	 (displayln
	  (format
	   "Available profiles: ~a"
	   (string-join
	    (for/list (((k v) vlib/profiles))
	      (symbol->string k))
	    ", ")))
	 (exit 0))
       (set-box! profile-box (string->symbol name))))
    (unbox profile-box)))

@title[#:style (with-html5 manual-doc-style)]{Qi Normal/Deforested Competitive Benchmarks}

@;Qi version helper ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
@(begin-for-syntax
  (require setup/getinfo)
  (define (get-version)
    ((get-info '("qi")) 'version)))
@(define-syntax (get-qi-version stx)
  (datum->syntax stx (get-version) stx stx))

@;Specification ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

@(module qi-default racket/base
  (require qi
           racket/math
           racket/list
           vlibench)

  (provide qi-filter-map-prog
           qi-filter-map-foldl-prog
           qi-long-pipeline-prog
           qi-range-map-car-prog)

  (define impl-label "Qi")

  (define qi-filter-map-prog
    (make-vlib/prog impl-label
                    (flow (~>> (filter odd?) (map sqr)))))

  (define qi-filter-map-foldl-prog
    (make-vlib/prog impl-label
                    (flow (~>> (filter odd?) (map sqr) (foldl + 0)))))

  (define qi-long-pipeline-prog
    (make-vlib/prog impl-label
                    (λ (high)
                      (~>> ()
                        (range high)
                        (filter odd?)
                        (map sqr)
                        values
                        (filter (lambda (v) (< (remainder v 10) 5)))
                        (map (lambda (v) (* v 2)))
                        (foldl + 0)))))

  (define qi-range-map-car-prog
    (make-vlib/prog impl-label
                    (λ (high)
                      (~>> () (range high) (map sqr) car))))
  )

@(module qi-deforested racket/base
  (require qi
           qi/list
           racket/math
           vlibench)

  (provide qi/d-filter-map-prog
           qi/d-filter-map-foldl-prog
           qi/d-long-pipeline-prog
           qi/d-range-map-car-prog)

  (define impl-label "Qi deforested")

  (define qi/d-filter-map-prog
    (make-vlib/prog impl-label
                    (flow (~>> (filter odd?) (map sqr)))))

  (define qi/d-filter-map-foldl-prog
    (make-vlib/prog impl-label
                    (flow (~>> (filter odd?) (map sqr) (foldl + 0)))))

  (define qi/d-long-pipeline-prog
    (make-vlib/prog impl-label
                    (λ (high)
                      (~>> ()
                        (range high)
                        (filter odd?)
                        (map sqr)
                        values
                        (filter (lambda (v) (< (remainder v 10) 5)))
                        (map (lambda (v) (* v 2)))
                        (foldl + 0)))))

  (define qi/d-range-map-car-prog
    (make-vlib/prog impl-label
                    (λ (high)
                      (~>> () (range high) (map sqr) car))))
  )

@(require 'qi-default
          'qi-deforested)

@(define benchmarks-specs
  (list
   (vlib/spec 'filter-map
          make-random-integer-list
          (list qi/d-filter-map-prog
                qi-filter-map-prog))
   (vlib/spec 'filter-map-foldl
          make-random-integer-list
          (list qi/d-filter-map-foldl-prog
                qi-filter-map-foldl-prog))
   (vlib/spec 'long-pipeline
          identity
          (list qi/d-long-pipeline-prog
                qi-long-pipeline-prog))
   (vlib/spec 'range-map-car
          identity
          (list qi/d-range-map-car-prog
                qi-range-map-car-prog))))

@; Processing ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
@define[profile (hash-ref vlib/profiles config-profile)]
@(define results
  (for/list ((spec (in-list benchmarks-specs)))
    (run-benchmark
      spec
      #:profile profile)))

@; Rendering ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

@section{General Information}

Date and time: @(date->string (seconds->date (current-seconds)))

@snippet:vlib/profile[profile]

@snippet:system-information[#:more-versions `(("Qi Version: " ,(get-qi-version)))]


@section{Summary Results}

@snippet:summary-results-table[results]


@section{Detailed Results}

@snippet:benchmark/s-duration[results]

Measured lengths: @(racket #,(for/list ((len (vlib/profile->steps profile))) len))

@(for/list ((result (in-list results)))
  (snippet:benchmark-result result))
