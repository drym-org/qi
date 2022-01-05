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

This section contains practical advice on using Qi. It includes recipes for doing various things, advice on gotchas, troubleshooting commonly encountered errors, and other tips you may find useful "in the field."

@table-of-contents[]

@section{Writing Flows}

@subsection{Start by Drawing a Circuit Diagram}

Before you write a flow, consider drawing out a "circuit diagram" on paper. Start by drawing wires corresponding to the inputs, and then draw boxes for each transformation and trace out what happens to the outputs. This practice is the Qi equivalent of writing "pseudocode" with other languages, and is especially useful when writing complex flows entailing folds and loops. With practice, this can become second nature and can be a very helpful recourse.

@subsection{Use Small Building Blocks}

Decompose your flow into its smallest components, and name each so that they are independent flows. Qi flows, by virtue of being functions, are highly composable, and are, by the same token, eminently decomposable. This tends to make refactoring flows a much more reliable undertaking than it typically is in other languages.

@section{Debugging}

@subsection{Using Side Effects}

The most lightweight way to debug your code is to use side effects, as this allows you to check values at various points in flows without affecting their functioning in any way. You can use this debugging approach always, even in functional Racket code that isn't using Qi.

This approach involves using the side-effect form, @racket[effect] (or @racket[ε]) at a particular point (or several points) in the flow in order to see or manipulate the values there. To use it in general Racket code, just wrap the Racket code with @racket[☯] to employ Qi there (and therefore side effects).

Side effects are a natural fit for debugging functional code in general, as the example below shows.

@bold{Example}: Racket's @racket[regexp-replace*] function transforms a string into another based on a regex-based replacement rule. It accepts a pattern, a string, and a replacement rule (as a function), and then constructs the output string by parsing the input string and calling your replacement rule function each time there is a match to the pattern. With regexes, things don't usually work until you've gone through multiple cycles of debugging, so in this case, in order to see what arguments are being supplied to your replacement rule function, you could simply add a side effect using Qi.

@codeblock{
  (regexp-replace* PATTERN
                   str
                   (☯ (ε (>< println) replace-rule)))
}

@subsection{Using a Tester}

@defmodule[qi/probe]

Qi includes a "circuit tester" style debugger, which you can use to check the values at arbitrary points in the flow. It can be used even if the flow is raising an error – the tester can help you find the error. It offers similar functionality to @other-doc['(lib "debug/scribblings/debug.scrbl")] but is specialized for functional debugging and Qi flows.

To use it, first wrap the entire expression @emph{invoking} the flow with @racket[probe]. Then, if your flow happens to be defined inline with the invocation, you can simply place a literal @racket[readout] anywhere within the flow to cause the entire expression to evaluate to the values flowing at that point. See @racket[probe] for examples of this.

If, on the other hand, your flow is defined elsewhere and only @emph{used} at the invocation site, then in addition to wrapping the invocation with @racket[probe], you'll need to wrap the body of the flow at the definition site with @racket[qi:probe], allowing you to place readouts there even if it happens to be in a separate file than the invocation site. See @racket[qi:probe] for examples of this.

@deftogether[(
  @defform[(probe flo)]
  @defidform[readout]
)]{
  @racket[probe] simply marks a flow for debugging, and does not change its functionality. Then, when evaluation encounters the first occurrence of @racket[readout] within @racket[flo], the values at that point are immediately returned as the value of the entire @racket[flo]. This is done via a @tech/reference{continuation}, so that you may precede it with whatever flows you like that might help you understand what's happening at that point, and you don't have to worry about it affecting downstream flows during the process of debugging since those flows would simply never be hit. Additionally, readouts may be placed @emph{anywhere} within the flow, and not necessarily on the main stream -- it will always return the values observed at the specific point where you place the readout.

  When the flow you intend to debug is defined inline with the invocation (e.g. a flow defined and immediately applied to arguments, or an @racket[on] expression, or a toplevel @racket[~>] or @racket[switch] form), simply using a @racket[probe] together with a @racket[readout] does what you expect. But when you want to debug a named flow that has been defined elsewhere, you'll need to use @racket[qi:probe] at the definition site, in addition.

@examples[
    #:eval eval-for-docs
    (~> (5) sqr (* 2) add1)
    (probe (~> (5) readout sqr (* 2) add1))
    (probe (~> (5) sqr readout (* 2) add1))
    (probe (~> (5) sqr (* 2) readout add1))
    (probe (~> (5) sqr (* 2) add1 readout))
    (probe (~> (5) sqr (if (~> (> 20) readout) _ (* 2)) add1))
  ]
}

@deftogether[(
  @defform[(qi:probe flo)]
  @defform[(define-probed-flow name body ...)]
  @defform[#:link-target? #f
           (define-probed-flow (name arg ...) body ...)]
)]{
  When the flow you'd like to debug is a named flow that is not defined inline at the invocation site, you'll need to take some extra steps to ensure that you can place a @racket[readout] at the @emph{definition} site even though the @racket[probe] itself is placed at the @emph{invocation} site.

  To do this, either wrap the entire body of the definition, or a subflow in the definition, with @racket[qi:probe]. Alternatively, you can use @racket[define-probed-flow] instead of @racket[define-flow], which transparently does this for you. Now, you can place a @racket[probe] at the invocation site, as usual, and it will receive the readout that you indicate at the definition site.

  @racket[(define-probed-flow name body)] is equivalent to @racket[(define-flow name (qi:probe body))] or @racket[(define name (flow (qi:probe body)))].

@examples[
    #:eval eval-for-docs
    (define-probed-flow my-flow
      (~> sqr readout (* 3) add1))
    (probe (my-flow 5))
    (define my-flow-too
      (☯ (qi:probe (~> sqr readout (* 3) add1))))
    (probe (my-flow-too 5))
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

@bold{Error}:

@codeblock{
;  _: wildcard not allowed as an expression
;   in: _
}

@bold{Meaning}: @racket[_] is a valid @emph{Qi} expression but an invalid @emph{Racket} expression. Somewhere in the course of evaluation of your code, the interpreter received @racket[_] and was asked to evaluate it as a @emph{Racket} expression. It doesn't like this.

@bold{Common example}: This usually happens when you try to use a template inside a nested application, where it becomes Racket rather than Qi. For instance, @racket[(~> (1) (* 3 (+ _ 2)))] is invalid because, within the @racket[(* ...)] template, the language is @emph{Racket} rather than Qi, and you can't use a Qi template (i.e. @racket[(+ _ 2)]) there. You might try @seclink["Nested_Applications_are_Sequential_Flows"]{sequencing the flow}, something like @racket[(~> (1) (+ _ 2) (* 3))].

@section{Effectively Using Feedback Loops}

@racket[feedback] is Qi's most powerful looping form, useful for arbitrary recursion. As it encourages quite a different way of thinking than Racket's usual looping forms do, here are some tips on "grokking" it.

In essence, the feedback loop is very simple –- all it does is pass the same inputs through a flow over and over again until a condition is met, at which point these inputs just flow out of the loop. Nothing complicated at all! The subtlety comes in, though, when we treat some inputs as "control" inputs that determine attributes @emph{of} the flow or as "scratch" inputs that encode computations done @emph{on} the flow, while treating the remaining inputs as the data that are actually acted upon. By doing this, we can do pretty much anything we'd like to, i.e. it can be used for general recursion.

@subsection{Control Values and Data Values}

Prior to entering the feedback loop, augment the data values by starting the "control" or "scratch" flows that the loop will need (although control and scratch inputs are not @emph{quite} the same (see above), we can use the terms interchangeably for our purposes here). In some common cases, this may include a "counter" flow which keeps track of number of iterations, a result flow which accumulates an output, or something of this nature. In addition to these control flows, the loop will, of course, also receive all of the input data in the form of multiple values following the control values. The control inputs must always come first, so that we know where to find them (since we have no idea how many data values there will be at any stage of the loop), so that we can consistently refer to them using e.g. @racket[1>] and @racket[2>].

@subsection{Input Tracing}

For each input, think about just one cycle of the loop: what must happen to it in this cycle before it is fed forward to the next cycle of the loop? Trace each input in this way and ensure that the corresponding output of the present cycle represents the correct input value for the next cycle. For instance, if there is a simple counter in the first @emph{input} position, ensure that the first @emph{output} of the present cycle is the counter incremented by one. We also need to ensure that the same number of @emph{control} values flow to the next cycle as are used in the present cycle. There are no constraints on the number of data values, and often, this will change from one cycle to the next.

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

@subsection{Bindings are an Alternative to Nonlinearity}

In some cases, we'd prefer to think of a nonlinear flow as a linear sequence on a subset of arguments that happens to need the remainder of the arguments somewhere down the line. In such cases, it is advisable to employ bindings so that the flow can be defined on this subset of them and employ the remainder by name.

For example, these are equivalent:

@codeblock{
  (define-flow make-document
    (~> (== _
            (~>> file-contents
                 (parse-result document/p)
                 △))
        document))
}

@codeblock{
  (define (make-document name file)
    (~>> (file)
         file-contents
         (parse-result document/p)
         △
         (document name)))
}

Adding bindings can eliminate nonlinearities, and by the same token, introducing nonlinearity can eliminate bindings.
