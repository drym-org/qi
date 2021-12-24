#lang racket/base

(provide probe
         readout
         qi:probe
         define-probed-flow)

(require syntax/parse/define
         racket/stxparam
         (for-syntax racket/base)
         version-case
         mischief/shorthand)

(version-case
 [(version< (version) "7.9.0.22")
  (define-alias define-syntax-parse-rule define-simple-macro)])

#|
We want to support debugging flow invocations of the kind:

    (~> (5) sqr add1)

and

    ((☯ (~> sqr add1)) 5)

where the arguments are supplied to a flow that is defined inline, but
also flow invocations of the kind:

    (my-flow 5)

where arguments are supplied to a named flow that is defined
elsewhere.

Here's how we do it and why:

The main entry-point for debugging is `probe` which is a _Racket_ form
used to debug a Qi flow _invocation_.

The mechanism underlying the probe/readout is a continuation that is
taken at the point where the `probe` form is used, which is escaped
into when the `readout` form is encountered. This doesn't immediately
work in the case of named flows because the continuation taken is not
in the lexical scope of the readout in this case. In order to handle
this, we use a _parameter_ (i.e. dynamic rather than lexical binding)
called `source` to store the continuation taken at the point where the
Racket `probe` form is used, i.e. at the site of _invocation_ of the
flow, and then retrieve this continuation from the parameter at the
point where the readout is encountered, i.e. at the site of
_definition_ of the flow.

In order to ensure that the flow can only be invoked inside of `probe`
where a well-defined continuation is known to exist (and not, say, a
stale continuation from a previous `probe` attempt), we reset the
`source` parameter to a placeholder `default-source` function right
before we exit through the continuation with a readout value.  The
`default-source` function simply raises an error indicating that a
fresh continuation has not been taken.

Additionally, in the case of the named flow _definition_, we must wrap
it (or any sub-flow within it) with a _Qi_ version of the `probe` form
in order to give the term `readout` – lexically – the special meaning
that allows it to escape via the continuation with the values at that
point in the flow and also reset the parameter as described above.
|#

(define (default-source . args)
  (error
   (string-append "Continuation not taken - the final flow "
                  "invocation must be wrapped "
                  "in `(probe ...)`")))

(define source (make-parameter default-source))

(define-syntax-parameter readout
  (lambda (stx)
    (raise-syntax-error (syntax-e stx) "can only be used inside `probe`")))

(define-syntax-parse-rule (probe flo)
  (call/cc
   (λ (return)
     (source return) ; save the continuation to the `source` parameter
     (syntax-parameterize
         ([readout (syntax-id-rules ()
                     [_ (let ([src (source)])
                          ;; reset source to avoid the possibility of stale
                          ;; continuations used later outside of a `probe`
                          (source default-source)
                          src)])])
       flo))))

(define-syntax-parse-rule (qi:probe flo)
  (syntax-parameterize
      ([readout (syntax-id-rules ()
                  [_ (flow
                      (esc
                       (λ args
                         (let ([src (source)])
                           ;; reset source to avoid the possibility of stale
                           ;; continuations used later outside of a `probe`
                           (source default-source)
                           (apply src args)))))])])
    (flow flo)))

(define-syntax-parser define-probed-flow
  [(_ (name:id arg:id ...) flo:expr)
   #'(define name
       (flow-lambda (arg ...)
         (qi:probe flo)))]
  [(_ name:id flo:expr)
   #'(define name
       (flow (qi:probe flo)))])
