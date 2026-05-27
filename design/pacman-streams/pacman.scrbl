#lang scribble/base

@require[(only-in scribble/jfp abstract)
         scribble/manual
         scriblib/figure]

@title{Virtual Multi-valued Streams @(linebreak) or, "Pac-Man Continuations" @(linebreak)}

@centered{@bold{@tt{Technical Specification}}}
@centered{@bold{@tt{Status: @elem[#:style "status-accepted"]{@tt{ACCEPTED}}}}}

@abstract{
  A detailed description of the design of the continuation-passing multi-valued stream implementation proposed for the Qi compiler, which naturally generalizes the existing single-valued implementation while preserving its performance characteristics. The generalization is achieved by means of threading two continuations through the stream: a @emph{pending output continuation} @code{k-pending}, and a @emph{return continuation} @code{k-return}, preserving other aspects of the stream implementation. These two continuations accumulate pending output in a single stream cycle, and support returning to points which yield additional values in the same cycle, respectively. In this way, they "unroll" the static stream, which is capable of producing zero or one value per cycle, into a longer dynamic stream capable of producing any number of values per cycle.
}

@section{Background}

Stream fusion is an approach to compiling functional sequence-oriented operations like @code{map}, @code{filter} and @code{foldl}. It represents the input as a stream of values rather than as a specific data structure such as a list, and then operates on these values individually through all of the stages of transformation, effectively fusing these into a single aggregate operation on each individual input value. This fusion of value-oriented operations avoids intermediate representations of the entire collection (for example, the construction of an intermediate list after @code{map}, after @code{filter}, and so on). The survey paper by Vincent St-Amour @cite{St-Amour12} explains the motivation and development of this approach.

This optimization is essential in settings dealing with large datasets or realtime applications where latency is critical. Additionally, because streams operate on values directly, they are agnostic to input and output data structures, making them a good candidate for optimizing Qi flows which, too, operate on values directly.

Qi currently implements this optimization, but it is restricted to list inputs and "linear" list-oriented operations, i.e., consuming and producing at most one value at each step. Qi's implementation of stream fusion employs @emph{continuation-passing style (CPS)} to take advantage of efficient compilation of this pattern in Racket/Chez, where continuing via lambdas in tail position (rather than the usual programming pattern of function invocation and use of return values) effectively compiles to GOTOs (see "LAMBDA: The Ultimate GOTO"@cite{Steele77}). In other words, CPS is very fast in Racket.

@section{Guide}

@secref["Overview"] summarizes the semantics of a stream. @secref["Architecture_of_the_Stream"] describes Qi's stream implementation, and the proposed modifications. @secref["A_Stream_Cycle"] describes the processing of a single value by the stream, including the dynamic of "cycles" and "epicycles." @secref["Analysis"] analyzes each component of the stream's operation in isolation. @secref["Stages_of_Processing"] describes the distinct semantics of the producer, transformer, and consumer. @secref["Reference_Code"] provides a minimal and faithful end-to-end code example.

@section{Overview}

A stream is a computation expressed as a series of operations on individual values. It is made up of stream segments. Any given segment is one of:

@itemlist[
  @item{Producer}
  @item{Transformer}
  @item{Consumer}
]

A producer generates values given some input parameters (e.g., an input list, which it destructures).

A transformer considers each value and yields zero or more values (e.g., @code{map} or @code{filter}).

A consumer evaluates the stream result (e.g., convert back to a list, or @code{foldl} to produce an aggregate value such as a sum).

@section{Architecture of the Stream}

This section describes the overall operation of the CPS stream fusion implementation. Most of it describes Qi's existing implementation already @hyperlink["https://github.com/drym-org/qi/wiki/The-Compiler#stream-fusion"]{documented in the Wiki}, but summarized below, while some of it describes the new proposal.

As summarized in the previous section, a stream is made up of stream segments: a producer, followed by any number of transformers, followed by a consumer.

Generally speaking, a stream segment is a @emph{closure} that accepts precisely three arguments: the continuations @code{done} (called by any segment to terminate the stream), @code{skip} (called to exclude a value from the result) and @code{yield} (called to convey a value forward to the next stream segment).

Each stream segment closes over additional arguments that parametrize its behavior. These arguments include, at a minimum, the @code{previous} stream segment (also a closure) [note that in the Qi source code, we use the word "next" for this, rather than "previous," which although true in an order-isomorphic sense, we avoid here because the binding refers to the preceding rather than the next segment in the stream!].

The exceptions to these rules are that @emph{consumers} don't close over any continuations (since they are the end of the stream, and are responsible for defining these three ultimate continuations), and @emph{producers} don't close over a @code{previous} segment (since they are the beginning of the stream and are responsible for processing the input).

Aside from these, the other arguments that parametrize each segment are specific to the semantics of the operation being performed. For instance, @code{map} closes over, in addition to @code{previous}, a function @code{f} to apply to each value, while @code{take} closes over a number @code{n} of values to keep. In the Qi compiler, we also capture and pass source syntax objects among these closed-over arguments, to aid error reporting.

The stream's architecture as a nest of closures entails two distinct times of interest: the time when the stream is @emph{constructed} (when it evaluates to a closure), and the time when the stream is @emph{applied} to input arguments (e.g., a list), when it evaluates to the computed output of the stream (e.g., a list).

At construction time, each stream segment, in turn, binds the @emph{previous} stream segment's @code{done}, @code{skip}, and @code{yield} continuations by wrapping the ones it receives from the @emph{next} segment (which are ultimately defined in the consumer) with its own semantics.

In the current implementation in the compiler, the @code{done} continuation expects no arguments, the @code{skip} continuation expects one argument — the @emph{next} stream state (typically short-circuiting all the way to the consumer to skip the current stream value), while the @code{yield} continuation expects two arguments — the current segment's computed output value and the next stream state.

The proposal introduces two additional arguments to @code{done}, @code{skip} and @code{yield} — a @emph{pending output} continuation @code{k-pending}, and a @emph{return} continuation @code{k-return}. These are used specifically for the purpose of enabling individual segments to yield multiple times, by keeping track of pending output in each stream cycle and bookmarking points to return to to compute additional output before moving on to the next cycle. This will be described in detail below.

At application time, the stream eagerly evaluates to a result.

@section{A Stream Cycle}

A single stream cycle is defined as the processing by the steam of a single value produced from the input state. This section describes a stream cycle.

As described in the previous section, a stream is a nest of closures, with the consumer of the stream being outermost and the producer of the stream being innermost.

When this closure is applied, it is therefore the consumer that receives the input state first. It applies the previous segment (a closure) to this input state, which in turn does the same, and, in this manner, this input state propagates all the way to the producer (which is innermost).

The producer analyzes the state to determine whether the stream is exhausted, in which case it signals termination of the stream to the consumer. Otherwise, it produces (1) a value, and (2) a next input state.

Crucially, in either of these cases, these aren't conveyed to subsequent (i.e., wrapping) stream segments as @emph{return values}, but rather via the @emph{continuations} that were received from them as arguments at construction time: either the @code{done} continuation (in the former case of stream exhaustion) or the @code{yield} continuation (in the latter case of producing a value and new state). If at any point thereon a segment (typically a transformer) decides that a value should be excluded from the result (e.g., @code{filter}), it calls the @code{skip} continuation. These continuation invocations are tail calls, that is, their return values aren't used in the calling frame, so these frames may be ignored and are in practice eliminated by the Racket/Chez compiler (tail-call elimination), and we can just follow the computation "forward" all the way through the series of stream segments to the consumer, rather than needing to unwind the stack.

In the case of a yield, the produced @emph{value} will be processed by all succeeding segments in the stream in the present cycle, yielding zero or more output values or even early termination of the stream (as determined by the semantics of each stream segment), while the @emph{next stream state} will simply be conveyed unchanged all the way to the consumer, for it to use to begin the next stream cycle, in exactly the way described in the present section, that is, beginning with the application of the stream (closure) to the @emph{next} stream state conveyed from the producer.

@subsection{Epicycles}

With the introduction of the @code{k-pending} and @code{k-return} continuations to support multi-valued streams, instead of the consumer always invoking the stream on the next state upon receiving each new value, there may now be additional values that need to be produced in the @emph{current} cycle. In such cases, the consumer returns to bookmarked points in the stream where these additional values need to be produced, continuing forward through the stream once again from there, accumulating "pending output" each time it returns to the consumer. These recurrences within the current cycle form smaller "epicycles" which may be nested. When all return points have been fulfilled, the pending output is computed and the consumer then starts the next stream cycle, as before. The precise mechanism of these epicycles is described in the analysis below of each continuation and each stage of stream operation.

@section{Analysis}

@subsection{Yielding Values}

Stream segments typically forward the @code{done} and @code{skip} continuations unchanged, so that these short-circuit all the way to the consumer.

When a stream segment @code{yield}s a value, it must forward:

@itemlist[
  @item{A value (exactly one).}
  @item{The remaining stream state.}
  @item{The pending output continuation.}
  @item{The return continuation for any pending work.}
]

Since it can yield precisely @emph{one} value (note that @code{skip} is used to yield zero values), we must find some way to yield multiple @emph{times} in the present stream cycle in order to yield multiple @emph{values} from a single stream segment. That's where the two new continuations come in.

@subsection{The Pending Output Continuation, @code{k-pending}}

The pending output continuation refers to a way of tracking the output computed by the stream that enables segments to yield any number of values in each stream cycle. It is defined and managed exclusively by the consumer, as this is the only point in the stream where the output may be determined.

Consumers like @code{foldr} process the stream from left to right and are not tail-recursive in the driver loop. But others like @code{foldl} are tail-recursive and pass the intermediate result to the recursive call. These two cases must handle the pending output continuation differently, and the latter style affords some optimizations.

@subsubsection{Non-tail-recursive Consumer}

@itemlist[
  @item{It is a @emph{thunk}.}
  @item{It is typically a recursive call to the driver loop beginning the @emph{next} stream cycle, @code{(λ () (go vs))}.}
  @item{The final call to it evaluates to the seed value for accumulation (for example, @code{0} for a simple consumer performing addition), @code{(λ () init)}}
  @item{Appending to it entails calling it and then operating on the result, e.g., @code{(cons v (k-pending))}.}
  @item{When called, it does @emph{all} of the remaining work on the entire stream.}
]

This style of consumer grows the call stack throughout the lifecycle of the stream, collapsing it at the end in producing a result (like any recursion that is not tail-recursive).

@subsubsection{Tail-recursive Consumer}

@itemlist[
  @item{It is an ordinary @emph{value}.}
  @item{It represents the intermediate result computed up to this point on the entire stream thus far, including work from previous stream cycles and any work so far on the current stream cycle.}
  @item{It is initialized to @code{init}, a seed value specified by the consumer (for example, @code{0} for a simple consumer performing addition).}
  @item{"Appending" to it entails directly incorporating the latest stream value on-the-fly, e.g., @code{(cons v k-pending)}.}
  @item{When all of the pending output from the current cycle has been incorporated into this value, the driver loop then passes it as the result argument (the accumulator) in the recursive call to the next stream cycle, i.e., @code{(go vs k-pending)}.}
]

This style of consumer does not build up the call stack while processing the stream since, as we see here, the new intermediate result is computed as soon as each stream value is available. The "continuation" here is not a function but simply a value representing the result, to be used directly to "escape" at the end — a kind of degenerate continuation.

@subsubsection{In Either Case}

@itemlist[
  @item{Only the consumer appends to pending output.}
  @item{Other segments just pass it forward.}
  @item{The producer must initialize it to @code{#false} because it cannot determine the continuation — only the consumer can.}
]

Since the (any) consumer is the only one that manipulates @code{k-pending}, it can use it however it wishes to (e.g., either a non-tail-recursive continuation, or a tail-recursive accumulator).

@subsection{The Return Continuation, @code{k-return}}

The return continuation is defined by any @emph{transformer} wishing to yield multiple times. It "bookmarks" a point in the stream to return to and continue forward from, forming an epicycle within the containing stream cycle that accumulates "pending output." This dynamic is the reason the approach is referred to as "Pac-Man streams," as it is reminiscent of Pac-Man moving past the edge of the screen on the right and emerging from somewhere on the left while continuing to consume values, in the classic arcade game.

@itemlist[
  @item{It is initialized to @code{#false} in the @emph{producer}, as there is as yet no return point.}
  @item{It may be set by any @emph{transformer}.}
  @item{There, it looks like @code{(λ (k-pending) ... next steps ...)}.}
  @item{The @emph{consumer} calls it with @code{k-pending} (defined in the consumer) as the only argument.}
  @item{If there are multiple return points logged, they are handled in a natural way described below under "transformer."}
]

@subsubsection[#:tag "return:ntrc"]{Non-tail-recursive Consumer}

@itemlist[
  @item{Recurrence @emph{suspends} calling @code{k-pending} (which begins the next stream cycle) until all yields in the current stream cycle have been accounted for.}
  @item{At that point, @code{k-pending} is invoked in the consumer's driver loop, which proceeds to the next stream cycle.}
  @item{This resembles, e.g., @code{(cons v (cons v ... (k-pending)))}.}
]

@subsubsection[#:tag "return:trc"]{Tail-recursive Consumer}

@itemlist[
  @item{Recurrence builds @code{k-pending} as an already-reduced intermediate result directly, until all yields in the current stream cycle have been accounted for.}
  @item{At that point, the consumer's driver loop recurs to the next stream cycle, passing forward @code{k-pending} as the accumulated result.}
  @item{This resembles, e.g., @code{(go vs k-pending)}.}
]

@subsection{Virtual Length of the Stream}

Together, these two continuations "virtually" extend the stream, unrolling recurrence into a longer stream from the perspective of the values flowing through it. If each stream segment @code{i} yields @code{kᵢ} values, then a stream of length @code{N} appears to be of virtual length bounded above by @code{N × k₁ × k₂ × ... × kn}.

@section{Stages of Processing}

@subsection{In the Producer}

@itemlist[
  @item{Its job is simply to determine how to produce individual values from some initial sequence specification (e.g., simply a list, or a set of numbers defining a range, or a vector, etc.). For example, in producing values from a list, it simply yields the @code{car} and @code{cdr}, if it is not @code{null} (in which case it calls @code{done} to terminate).}
  @item{Only the producer can "unpack" the stream state. Other segments only forward the state on, and can request to "skip" to the next state, a request which the consumer fulfills by passing that next state back to the producer. But only the producer can analyze the state.}
  @item{It @emph{must} initialize @code{k-return} to @code{#false}, since there is no bookmarked return point yet as we are just starting to process the newly produced value.}
  @item{It @emph{must} initialize @code{k-pending} to @code{#false}, since this is the pending @emph{output} continuation, which the producer cannot determine (only the consumer can).}
]

@subsection{In the Transformer}

If it's yielding a single value:

@itemlist[
  @item{It simply passes forward the pending output and return continuation, unchanged.}
  @item{The remaining stream state is also passed forward unchanged, as always.}
  @item{In addition to its own work on the current stream value.}
]

If it wants to yield multiple values:

@itemlist[
  @item{It reifies the continuation at that point.}
  @item{It yields subsequent values within the scope of the newly defined return continuation.}
  @item{It yields the next value (and untouched remaining stream state).}
  @item{It passes forward the pending output continuation along with the @emph{newly defined} return continuation.}
  @item{A return continuation so defined must accept a pending output continuation as argument (which will be supplied when invoked by the @emph{consumer}).}
  @item{In yielding the final value, it passes forward the @emph{a priori} return continuation.}
  @item{In this way, the return continuations form a "stack" — later ones shadow earlier ones as long as they are still yielding, and then they convey the a priori one forward at that stage.}
]

@subsection{In the Consumer}

The consumer is the only one with stream-scoped state (every other segment is fully "Markov" to a specific produced value, and may maintain internal state, e.g., @code{take}).

When a value is received on the @code{yield} continuation:

@itemlist[
  @item{At this point, we want to incorporate the current value into the result and recur to the next stream cycle, e.g., @code{(cons v (go vs))} or @code{(go vs (cons v result))} (depending on non-tail vs tail-recursive).}
  @item{And that's what we'll do if no one says otherwise.}
  @item{But if we see that there is a logged return point (i.e., if @code{k-return} is not @code{#false}), then we add the intended operation to the end of the pending output continuation, instead.}
  @item{And then return to the point where the work in the current stream state may be continued, passing in the pending output, thus beginning an epicycle within the containing stream cycle.}
  @item{Finally, if there is no return point but there is pending output, then evaluate it and recur to the next stream state and cycle.}
]

When a value is received on the @code{skip} continuation,

@itemlist[
  @item{We'd like to recur to the next stream cycle, e.g., @code{(go vs)} or @code{(go vs result)}.}
  @item{But if there is a @code{k-return}, we pass, e.g., @code{(λ () (go vs))}, as @code{k-pending} to @code{k-return}, as there may still be more values produced in the current stream cycle, i.e., from the current stream state.}
  @item{Finally, if there is no return point but there is pending output, then evaluate it and recur to the next stream cycle.}
]

When the @code{done} continuation is invoked,

@itemlist[
  @item{If there is pending output in @code{k-pending}, evaluate it. Then, terminate.}
]

@section{Extension to Buffered Streams}

As we have seen, the scheme elaborated thus far is capable of expressing streams that yield zero or more values in each cycle. But it is necessary that each stream segment make this determination immediately upon receiving each individual value. However, there are cases where a segment --- specifically a transformer --- may prefer to yield values only after seeing several input values, rather than immediately. We refer to this as a case of a "buffered" transformer. The defining property of such a buffered transformer is that it may continue to yield values @emph{even after the producer has determined that the stream is exhausted}.

The key in handling this case, therefore, is for the buffered transformer to assume the role of the producer when this happens, taking on its responsibilities. In particular, in its @code{done} continuation:

@itemlist[
  @item{It @emph{must} define a return continuation so that the consumer returns control to it at the end of the cycle instead of back to the producer (whose role is concluded).}
  @item{Instead of passing forward a remaining stream state for the next cycle (which is unavailable as the producer has already determined stream exhaustion), it simply passes forward an unused sentinel value such as @code{#false}.}
  @item{It must ultimately call the received @code{done} continuation, assuming this responsibility from the producer.}
]

@section{Reference Code}

The code block below contains a runnable end-to-end stream, minimally and faithfully illustrating the approach described by this document.

@code{producer} produces a stream from a list.

@code{dup-transformer} is a transformer that duplicates each input value, yielding two values for each (thus serving to illustrate a multi-valued transformer).

@code{pair-transformer} is a @emph{buffered} transformer that groups values into pairs, yielding a single list value for every two input values (thus serving to illustrate "buffered" streams). For an odd number of input values, the last value yields a singleton list.

@code{rconsumer} is a non-tail-recursive consumer (like @code{foldr}) that simply constructs a list from the stream.

@code{lconsumer} is a tail-recursive consumer (like @code{foldl}) that simply constructs a list from the stream.

@codeblock{
  (define producer
    (λ (done skip yield)
      (λ (vs)
        (if (null? vs)
            (done #false)
            (let ([v (car vs)]
                  [vs (cdr vs)])
              (yield v
                     vs
                     #false
                     #false))))))

  (define (dup-transformer previous)
    (λ (done skip yield)
      (previous done
                skip
                (λ (v vs k-pending k-return)
                  (yield v
                         vs
                         k-pending
                         (λ (k-pending)
                           (yield v
                                  vs
                                  k-pending
                                  k-return)))))))

  (define (pair-transformer previous)
    (let ([buffer #false])
      (λ (done skip yield)
        (previous (λ (k-pending)
                    (if buffer
                        (yield (list buffer)
                               #false
                               k-pending
                               (λ (k-pending)
                                 (done k-pending)))
                        (done k-pending)))
                  skip
                  (λ (v vs k-pending k-return)
                    (if buffer
                        (let ([buffered-v buffer])
                          (set! buffer #false)
                          (yield (list buffered-v v)
                                 vs
                                 k-pending
                                 k-return))
                        (begin
                          (set! buffer v)
                          (skip vs
                                k-pending
                                k-return))))))))

  (define (rconsumer init previous)
    (λ (vs)
      (let go ([vs vs])
        ((previous (λ (k-pending)
                     (let ([k-pending (or k-pending (λ () init))])
                       (k-pending)))
                   (λ (vs k-pending k-return)
                     (let ([k-pending (or k-pending (if vs
                                                        (λ () (go vs))
                                                        (λ () init)))])
                       (if k-return
                           (k-return k-pending)
                           (k-pending))))
                   (λ (v vs k-pending k-return)
                     (let ([k-pending (or k-pending (if vs
                                                        (λ () (go vs))
                                                        (λ () init)))])
                       (cons v (if k-return
                                   (k-return k-pending)
                                   (k-pending))))))
         vs))))

  (define (lconsumer init previous)
    (λ (vs)
      (let go ([vs vs] [result init])
        ((previous (λ (k-pending)
                     (let ([k-pending (or k-pending result)])
                       k-pending))
                   (λ (vs k-pending k-return)
                     (let ([k-pending (or k-pending result)])
                       (if k-return
                           (k-return k-pending)
                           (go vs k-pending))))
                   (λ (v vs k-pending k-return)
                     (let* ([k-pending (or k-pending result)]
                            [k-pending (cons v k-pending)])
                       (if k-return
                           (k-return k-pending)
                           (go vs k-pending)))))
         vs))))

  ((rconsumer null (dup-transformer producer)) (list 1 2 3))  ;=> '(1 1 2 2 3 3)

  ((lconsumer null (dup-transformer producer)) (list 1 2 3))  ;=> '(3 3 2 2 1 1)

  ((rconsumer null (pair-transformer producer)) (list 1 2 3))  ;=> '((1 2) (3))

}

@section{Summary}

We described in detail Qi's continuation-passing stream fusion implementation, including a natural generalization to support multiple values while preserving the performance characteristics of the single-valued implementation. This covered the stream's construction as a nest of closures; the use of @code{done}, @code{skip} and @code{yield} continuations to implement each cycle of the stream's semantics; the addition of @code{k-pending} and @code{k-return} continuations introducing "epicycles" within a cycle to support multiple yields; the distinct roles and responsibilities of the producer, each transformer, and the consumer, and how these responsibilities shift to accommodate "buffered" transformers that yield output only after considering several input values; the subtle distinction between tail-recursive and non-tail-recursive consumers and implications for performance; and finally, a minute analysis of the stream's ultimate application to arguments and its evaluation to a result.

@(bibliography

  (bib-entry #:key "St-Amour12"
             #:author "Vincent St-Amour"
             #:title "Deforestation"
             #:date "2012"
             #:url "https://www.ccs.neu.edu/home/amal/course/7480-s12/deforestation-notes.pdf")

  (bib-entry #:key "Steele77"
             #:author "Guy Lewis Steele Jr."
             #:title "LAMBDA: The Ultimate GOTO"
             #:date "1977"
             #:url "https://www2.cs.sfu.ca/CourseCentral/383/havens/pubs/lambda-the-ultimate-goto.pdf")

)
