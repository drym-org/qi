#lang scribble/doc
@require[scribble/manual
         scribble-abbrevs/manual
         scribble/example
         racket/sandbox
         @for-label[qi
                    qi/probe
                    racket
                    (only-in relation
                             ->number
                             ->string
                             sum)]]

@(define eval-for-docs
  (parameterize ([sandbox-output 'string]
                 [sandbox-error-output 'string]
                 [sandbox-memory-limit #f])
    (make-evaluator 'racket/base
                    '(require qi
                              qi/probe
                              (only-in racket/list range)
                              racket/string
                              relation)
                    '(define (sqr x)
                       (* x x)))))

@title{Field Guide}

@table-of-contents[]

@section{Writing Flows}

@subsection{Start by Drawing a Circuit Diagram}

Before you write a flow, consider drawing out a "circuit diagram" on paper. Start by drawing wires corresponding to the inputs, and then draw boxes for each transformation and trace out what happens to the outputs. This practice is the Qi equivalent of writing "pseudocode" with other languages, and is especially useful when writing complex flows entailing folds and loops. With practice, this can become second nature and can be a very helpful recourse.

@subsection{Use Small Building Blocks}

Decompose your flow into its smallest components, and name each so that they are independent flows. Qi flows, by virtue of being functions, are highly composable, and are, by the same token, eminently decomposable. This tends to make refactoring flows a much more reliable undertaking than it typically is in other languages.

@section{Debugging}

@subsection{Using Side Effects}

For the simplest cases, you could just use the side-effect form, @racket[effect] (or @racket[ε]), to see the values at a particular point in the flow without affecting the functioning of the flow itself.

@subsection{Using a Tester}

@defmodule[qi/probe]

Qi includes a "circuit tester" style debugger, which you can use to check the values at arbitrary points in the flow. It can be used even if the flow is raising an error – the tester can help you find the error. You can use it by simply wrapping a flow invocation with @racket[probe]. Then, the symbol @racket[readout] may be used within this form to return the values flowing at the point as the result of the entire expression.

@deftogether[(
  @defform[(probe flo)]
  @defidform[readout]
)]{
  @racket[probe] simply marks a flow for debugging, and does not change its functionality. Then, when evaluation encounters the first occurrence of @racket[readout] within @racket[flo], the values at that point are immediately returned as the value of the entire @racket[flo]. This is done via a @tech/reference{continuation}, so that you may precede it with whatever flows you like that might help you understand what's happening at that point, and you don't have to worry about it affecting downstream flows during the process of debugging since those flows would simply never be hit. Additionally, readouts may be placed @emph{anywhere} within the flow, and not necessarily on the main stream -- it will always return the values observed at the specific point where you place the readout.

  Note that, at least at the moment, the @racket[probe] must decorate a flow invocation rather than a flow definition. For instance, this could be a flow applied to arguments, or an @racket[on] expression, or a toplevel @racket[~>] or @racket[switch] form.

@examples[
    #:eval eval-for-docs
    (~> (5) sqr (* 2) add1)
    (probe (~> (5) readout sqr (* 2) add1))
    (probe (~> (5) sqr readout (* 2) add1))
    (probe (~> (5) sqr (* 2) readout add1))
    (probe (~> (5) sqr (* 2) add1 readout))
    (probe (~> (5) sqr (if (~> (> 20) readout) _ (* 2)) add1 readout))
  ]
}

@subsection{Common Errors and What They Mean}

@bold{Error}:

@codeblock{
; result arity mismatch;
;  expected number of values not received
;   expected: 1
;   received: 2
}

@bold{Meaning}: A flow is either returning more or fewer values than the expression receiving the result of the flow is expecting.

@bold{Common example}: Attempting to assign the result of a multi-valued flow to a single variable. Use @racket[define-values] instead of @racket[define] here, or consider decomposing the flow into multiple flows that each return a single value.

@section{Effectively Using Feedback Loops}

@racket[feedback] is Qi's most powerful looping form, useful for arbitrary recursion. It encourages quite a different way of thinking about code than Racket's usual looping forms. Here are some tips on "grokking" it.

@subsection{Scratch Values and Data Values}

Prior to entering the feedback loop, start the "scratch" flows that the loop will need. In some common cases, this may include a "counter" flow which keeps track of number of iterations, a result flow which accumulates an output, or something of this nature. In addition to these scratch flows, the loop will, of course, also receive all of the input data in the form of multiple values following the scratch values. The scratch inputs must always come first, so that we know where to find them (since we have no idea how many data values there will be at any stage of the loop), so that we can consistently refer to them using e.g. @racket[1>] and @racket[2>].

@subsection{Input Tracing}

For each input, think about just one cycle of the loop: what must happen to it in this cycle before it is fed forward to the next cycle of the loop? Trace each input in this way and ensure that the corresponding output of the present cycle represents the correct input value for the next cycle. For instance, if there is a simple counter in the first @emph{input} position, ensure that the first @emph{output} of the present cycle is the counter incremented by one. We also need to ensure that the same number of @emph{scratch} values flow to the next cycle as are used in the present cycle. There are no constraints on the number of data values, and often, this will change from one cycle to the next.

@subsection{Keeping It Tidy}

Use the @racket[then] clause to ensure that the feedback loop produces only its computed output and not the "scratch" values used in guiding the flow, i.e., these should be blocked in the @racket[then] clause (using, for instance, @racket[block] or another appropriate form).

@section{Idioms and Transforms}

@subsection{Nested Applications are Sequential Flows}

A nested function application can always be converted to a sequential flow.

@examples[
    #:eval eval-for-docs
    (add1 (* 2 (sqr 5)))
    (~> (5) sqr (* 2) add1)
    (define my-num 5)
    (add1 (* my-num (sqr (+ my-num 3))))
    (~> (my-num) (-< (~> (+ 3) sqr)
                     _) * add1)
  ]

@subsection{Converting a Function to a Closure}

Sometimes you may find you want to go from something like @racket[(~> f1 f2)] to a similar flow except that one of the functions is itself parameterized by an input, i.e. it is a closure. If @racket[f1] is the one that needs to be a closure, you can do it like this: @racket[(~> (== (clos f1) f2) apply)], assuming that the closed-over argument to @racket[f1] is passed in as the first input. Closures are useful in a wide variety of situations, however, and this isn't a one-size-fits-all formula.
