#lang scribble/base

@require[(only-in scribble/jfp abstract)
         scribble/manual
         scriblib/footnote
         scriblib/figure]

@title{Virtual Multi-valued Streams @(linebreak) or, "Pac-Man Continuations" @(linebreak)}

@centered{@bold{@tt{Qi Improvement Proposal (QIP)}}}
@centered{@bold{@tt{Status: @elem[#:style "status-accepted"]{@tt{ACCEPTED}}}}}

@abstract{
  A detailed description of the design of the continuation-passing multi-valued stream implementation proposed for the Qi compiler, which naturally generalizes the existing single-valued implementation while preserving its performance characteristics. The generalization is achieved by threading a new @code{return} continuation through the stream to support returning to points where additional values should be produced in a single stream cycle, while maintaining local state as needed in each stream segment using mutable lexical variables. These mechanisms "unroll" the static stream, which is capable of producing zero or one value per cycle, into a longer dynamic stream capable of producing any number of values per cycle.
}

@section{Background}

Stream fusion is an approach to compiling functional sequence-oriented operations like @code{map}, @code{filter} and @code{foldl}. It represents the input as a stream of values rather than as a specific data structure such as a list, and then operates on these values, directly, through all of the stages of transformation. This effectively fuses these sequential operations into a single aggregate operation on the input values considered in each stream cycle, and thus avoids intermediate representations of the entire collection (for example, the construction of an intermediate list after @code{map}, after @code{filter}, and so on). The survey paper by Vincent St-Amour @cite{St-Amour12} explains the motivation and development of this approach.

This optimization is essential in settings dealing with large datasets or in realtime applications where latency is critical. Additionally, because streams operate on values directly, they are agnostic to input and output data structures, making them a good candidate for optimizing Qi flows which, too, operate on values directly.

Qi currently implements this optimization, but it is restricted to list inputs and "linear" list-oriented operations, i.e., those consuming and producing at most one value at each step. Qi's implementation of stream fusion employs @emph{continuation-passing style (CPS)} to take advantage of efficient compilation of this pattern in Racket/Chez, where continuing via lambdas in tail position (rather than the usual programming pattern of function invocation and use of return values) effectively compiles to GOTOs (see "LAMBDA: The Ultimate GOTO"@cite{Steele77}). In other words, CPS is very fast in Racket.

@section{Guide}

@secref["Overview"] summarizes the semantics of a stream. @secref["Static_Architecture"] describes Qi's stream implementation and the proposed modifications. @secref["A_Stream_Cycle"] describes the runtime processing of a single value by the stream, including the dynamic of "cycles" and "epicycles." @secref["Analysis"] analyzes each component of the stream's operation in isolation. @secref["Reference_Code"] provides a minimal and faithful end-to-end code example. @secref["Future_Work"] describes extending the paradigm to multi-streams. Finally, @secref["Summary"] summarizes the proposal.

@section{Overview}

A stream is a computation expressed as a series of operations on @emph{values}. These operations may each accept zero or more input values and produce zero or more output values. Most commonly, they accept and produce single values.

The semantics of each such operation is encapsulated in a @emph{stream segment}. Any given segment is one of:

@itemlist[
  @item{Producer}
  @item{Transformer}
  @item{Consumer}
]

A @emph{producer} generates values one at a time given some input parameters (e.g., an input list, which it destructures).

A @emph{transformer} considers each value, or multiple values in succession, and yields zero or more values, one at a time (e.g., @code{map} or @code{filter}).

A @emph{consumer} incorporates values one at a time in constructing the stream result (e.g., converting back to a list, or @code{foldl} to produce an aggregate value such as a sum).

Thus, a stream is made up of stream segments: a producer, followed by any number of transformers, followed by a consumer.

@section{Static Architecture}

This section describes the static construction of continuation-passing streams in the Qi compiler. Much of it describes Qi's existing implementation already @hyperlink["https://github.com/drym-org/qi/wiki/The-Compiler#stream-fusion"]{documented in the Wiki}, but summarized below, while some of it describes the new proposal.

@subsection{The "Dilated" Driver Loop}

A representative example of something we'd like to do with streams is implement operations on lists. Typically, in order to process a list and, say, construct a new list, we would use @emph{structural recursion} in a simple loop. With continuation-passing streams, we do something analogous, except that this driver loop is "dilated" across the producer and consumer instead of being a single expression in one place.

A simple stream that translates a list to a stream and then back again to a list illustrates this core, "dilated," driver loop:

@codeblock{

  (define (list→stream vs)
    (λ (done yield)
      (let go ([vs vs])
        (if (null? vs)
            (done)
            (yield (car vs)
                   (λ ()
                     (go (cdr vs))))))))

  (define (stream→list previous)
    (previous (λ ()
                null)
              (λ (v return)
                (cons v (return)))))

  (stream→list (list→stream (list 1 2 3)))

}

With a little squinting, it's not hard to see that this is essentially just a decomposition of:

@codeblock{
  (define (list→stream→list vs)
    (if (null? vs)
        null
        (let ([v (car vs)]
              [vs (cdr vs)])
          (cons v (list→stream→list vs)))))

  (list→stream→list (list 1 2 3))
}

The benefit of "dilation" is that it allows inserting any number of specialized components between the producer and consumer that operate directly on these produced values without building any intermediate data structures, and which seamlessly compose with one another by conforming to a simple interface.

@subsection{Stream Segments}

Generally speaking, a stream segment is a @emph{closure} that accepts two arguments: the continuations @code{done} (called by any segment to terminate the stream) and @code{yield} (called to convey a value forward to the next stream segment). For example, this is the @code{map} transformer, which applies a function to each value:

@codeblock{
  (define (map f previous)
    (λ (done yield)
      (previous done
                (λ (v return)
                  (yield (f v)
                         return)))))
}

Each stream segment closes over additional arguments that parametrize its behavior. These arguments include, at a minimum, the @code{previous} stream segment (also a closure) [note that in the Qi source code, we use the word "next" for this, rather than "previous," which although true in an order-isomorphic sense, we avoid here because the binding refers to the preceding rather than the next segment in the stream!].

The two exceptions to these rules are, first, that @emph{consumers} don't close over any continuations, since they are the end of the stream, and are responsible for defining these ultimate continuations. For example, the consumer we saw earlier that translates the stream into a list:

@codeblock{

  (define (stream→list previous)
    (previous (λ ()
                null)
              (λ (v return)
                (cons v (return)))))

}

And second, @emph{producers} don't close over a @code{previous} segment, since they are the beginning of the stream and are responsible for processing the input. For example, the producer we saw earlier that translates a list into a stream:

@codeblock{

  (define (list→stream vs)
    (λ (done yield)
      (let go ([vs vs])
        (if (null? vs)
            (done)
            (yield (car vs)
                   (λ ()
                     (go (cdr vs))))))))

}

Aside from these, the other arguments that parametrize each segment are specific to the semantics of the operation being performed. For instance, @code{map} closes over, in addition to @code{previous}, a function @code{f} to apply to each value, while @code{take} closes over a number @code{n} of values to keep. In the Qi compiler, we also capture and pass source syntax objects among these closed-over arguments, to aid error reporting.

When the stream is constructed, each segment, in turn, binds the @emph{previous} segment's @code{done} and @code{yield} continuations by wrapping the ones it receives from the @emph{next} segment (which are ultimately defined in the consumer) with its own semantics.

When applied, the stream eagerly evaluates to a result.

@subsection{Differences from the Existing Implementation}

This section discusses some subtle differences from the reference implementation in the Qi compiler.

In the reference implementation, the loop driving stream evaluation is located in the @emph{consumer} although parsing and analysis of the stream state is the responsibility of the @emph{producer}. This necessitates having the (for example) structural recursion on the stream state in the @emph{consumer} and passing the next state all the way back to the producer for analysis there, and the further need to once again thread the remaining stream state all the way back to the consumer. The proposal moves the driver loop to its natural place in the producer, avoiding the need to thread the stream state through the various segments. It brings the significant benefit that stream components can now be compiled to closures independently and not only as complete sequences, simplifying compilation.

The reference compiler implements segment-local state by consing it onto the stream state shared between segments, and unconsing it before use, entailing significant supporting macro infrastructure. The proposal instead uses mutable lexical variables that are locally managed by each stream segment, as this is simpler and preserves the reference performance characteristics while also trivially generalizing to nonlinear streams such as @code{zip}.

In the reference implementation, in addition to the @code{done} and @code{yield} continuations, there is a @code{skip} continuation that is used by any segment to skip the current value and recur to the next stream cycle. It expects one argument: the next stream state, as discussed above. The @code{yield} continuation expects two arguments — the current segment's computed output value and, once again, the next stream state.

In addition to eliminating the need to thread the remaining input state through the stream segments, the proposal introduces one additional argument to @code{yield} — a @emph{return} continuation, which bookmarks points to return to in each stream cycle and thus enables individual segments to yield multiple times (i.e., produce multiple values) before moving on to the next cycle. As the return continuation enables resuming from @emph{any} earlier point in the stream and not only from the very beginning, it generalizes the capability of the former @code{skip} continuation which is therefore eliminated in this proposal.

@section{A Stream Cycle}

A single stream cycle is defined as the processing of a single value produced from the input state at runtime. This section describes a stream cycle.

As described in the previous section, a stream is a nest of closures, with the producer of the stream being innermost, and transformers forming successive wrapping layers, and the consumer being outermost.

When the stream is evaluated, the consumer defines the previous segment's @code{done} and @code{yield} continuations, which in turn does the same, and, in this manner, the stream continuations are defined all the way to the producer, kicking off eager evaluation of the stream.

At this point, the producer first analyzes the input state (which it closes over) to determine whether the stream is exhausted, in which case it signals termination of the stream to the consumer. Otherwise, it produces (1) a value, and (2) a lambda (i.e., the aforementioned "return continuation") that defers recursion on the stream state.

Crucially, in either of these cases, these aren't conveyed to subsequent (i.e., wrapping) stream segments as @emph{return values}, but rather, as arguments to the @emph{continuations} that were received from them at the time of construction of the present segment: either the @code{done} continuation (in the former case of stream exhaustion) or the @code{yield} continuation (in the latter case of producing a value and a return continuation).

If at any point thereon a segment (typically a transformer) decides that a value should be excluded from the result (e.g., @code{filter}), it calls the @code{return} continuation @emph{instead of} calling @code{yield}, resuming production of the @emph{next} value at an earlier point in the stream (often the producer).

These continuation invocations are tail calls, that is, their return values aren't used in the calling frame, so these frames may be ignored and are in practice eliminated by the Racket/Chez compiler (via tail-call elimination), and we can just follow the computation "forward" all the way through the series of stream segments to the consumer, rather than needing to unwind the stack.

In the case of a yield, the produced @emph{value} will be processed by all succeeding segments in the stream in the present cycle, yielding zero or more output values or even early termination of the stream (as determined by the semantics of each stream segment), while the @emph{return continuation} is conveyed unchanged unless a segment intends to yield multiple times. In the common case where all stream segments yield single values, the return continuation is only invoked in the consumer which resumes evaluation at the point in the producer where recursion on the remaining stream state had been deferred. This begins the next stream cycle, which then proceeds in exactly the way described in the present section.

When the producer determines that the stream is exhausted, the stream evaluates to a result determined by the consumer.

@subsection{Epicycles}

In the reference implementation, control always moves sequentially through segments in each cycle, and returns to the producer upon reaching the consumer, beginning the next cycle. With the introduction of the @code{return} continuation, @emph{any} segment may return to @emph{any} earlier bookmarked point in the stream, continuing forward through the stream once again from there, producing additional values mid-stream in the @emph{current} cycle. These recurrences within the current cycle form smaller "epicycles" which may be nested. They facilitate yielding multiple values (e.g., the @code{dup} transformer that duplicates each input value), and also, symmetrically, accumulating multiple values (e.g., the @code{pair} transformer that collects input values into pairs before yielding).

When all intermediate return points have been fulfilled, evaluation naturally returns to the producer on the final return (whether from the consumer or any other segment), starting the next stream cycle, as before.

@section{Analysis}

The previous section described the holistic operation of the stream.

In this section, we examine the specific components in isolation, describing their mechanics and how they facilitate overall stream evaluation.

@subsection{The @code{yield} Continuation}

When a stream segment wishes to pass a computed value forward to the next stream segment, it calls the @code{yield} continuation. In this invocation, it must forward:

@itemlist[
  @item{A value (exactly one).}
  @item{The return continuation for any pending work.}
]

If the segment wishes to yield a single value, it simply does so, and forwards the received return continuation, unchanged (e.g., see @code{map}).

As the continuation can yield precisely @emph{one} value, we need some way to @emph{not} yield if we wish to skip a value, and to yield multiple @emph{times} in the present stream cycle if we wish to yield multiple @emph{values} from a single stream segment. That's where the new @code{return} continuation comes in.

@subsection{The @code{return} Continuation}

The return continuation enables any stream segment to either skip a value (e.g., @code{filter}), or yield multiple values (e.g., @code{dup}), or accumulate multiple values (e.g., @code{pair}) in a single stream cycle.

It "bookmarks" a point in the stream to return to and continue forward from, forming an epicycle within the containing stream cycle@note{This dynamic is the reason the approach is referred to as "Pac-Man streams," as it is reminiscent of Pac-Man moving past the edge of the screen on the right and emerging from somewhere on the left while continuing to consume values, in the classic arcade game.}.

For example, the @code{filter} transformer uses @code{return} to skip certain values:

@codeblock{
  (define (filter f previous)
    (λ (done yield)
      (previous done
                (λ (v return)
                  (if (f v)
                      (yield v return)
                      (return))))))
}

And the @code{dup} transformer uses @code{return} to yield multiple values:

@codeblock{
  (define (dup previous)
    (λ (done yield)
      (previous done
                (λ (v return)
                  (yield v
                         (λ ()
                           (yield v
                                  return)))))))
}

Some general remarks on the return continuation:

@itemlist[
  @item{The return continuation is a thunk resembling @code{(λ () ... next steps ...)}.}
  @item{A segment @emph{defines} a return continuation when it wishes to yield multiple times. A segment @emph{enters} this continuation when it wishes to skip the present value or when it wishes to accumulate additional values in local state.}
  @item{The producer @emph{always} defines a return continuation (e.g., see @code{list→stream}), as evaluation must return here in order to produce each additional stream value from the input state.}
  @item{If there are multiple return continuations defined, they "stack" — a later one shadows an earlier one as long as it is still yielding, and then conveys the a priori one forward when yielding the final time.}
  @item{The consumer @emph{always} enters the return continuation after incorporating a value received via @code{yield}.}
]

@subsubsection{Virtual Length of the Stream}

The return continuation has the effect of "virtually" extending the stream, unrolling recurrence into a longer stream from the perspective of the values flowing through it. If each stream segment @code{i} yields @code{kᵢ} values, then a stream of length @code{N} appears to be of virtual length bounded above by @code{N × k₁ × k₂ × ... × kn}.

@subsection{The @code{done} continuation}

Any stream segment may signal the conclusion of the stream via the @emph{done} continuation.

@itemlist[
  @item{The @code{done} continuation is a thunk accepting no arguments.}
  @item{It @emph{must} be defined by the consumer, as this is where the result of stream evaluation is determined.}
]

At construction time, stream segments typically forward @code{done} unchanged all the way from the consumer back to the producer, so that it short-circuits all the way to the consumer at any point in the stream.

In cases where transformers accumulate multiple values before yielding a result, they may choose to override the done continuation to, for example, flush the pending output by yielding it. In this case, they assume responsibility for (1) defining a @code{return} continuation if multiple values are to be yielded, and (2) calling the received @code{done} at the end of their operation, as the producer and all preceding stream segments have already concluded their operation and have signed off on the stream being "done," and the consumer still needs, ultimately, to be notified of this.

@subsection{Styles of Consumer}

Consumers like @code{foldr} process the stream from left to right and are not tail-recursive in the "dilated" driver loop. But others like @code{foldl} are tail-recursive and accumulate the intermediate result in a mutable lexical variable local to the consumer@note{As an alternative to local state, we could pass the accumulated result back through the return continuation and cycle it back and forth through the entire stream as an immutable binding, but since it is determined entirely by the consumer, it is simpler to retain it in the consumer than to introduce conventions around (not) handling an unused variable in other stream segments, and has similar performance characteristics.}.

As with ordinary recursion, the tail-recursive consumers exhibit better performance as they avoid growing the call stack.

@subsubsection[#:tag "return:ntrc"]{Non-tail-recursive Consumer}

@itemlist[
  @item{The recursive call resembles, e.g., @code{(cons v (return))}.}
]

@subsubsection[#:tag "return:trc"]{Tail-recursive Consumer}

@itemlist[
  @item{The recursive call resembles, e.g., @code{(begin (set! result (cons v result)) (return))}.}
]

@subsection{State}

Each stream segment may retain local state across the handling of values. For instance, @code{take} needs to remember how many values remain to be yielded before truncating the rest of the stream. And @code{pair} needs to buffer pending values before yielding pairs of them together as a single cons pair or list value.

State of this kind that is local to a stream segment is maintained simply as a mutable lexical variable in the segment itself. For example:

@codeblock{
  (define (take n previous)
    (let ([remaining n])
      (λ (done yield)
        (previous done
                  (λ (v return)
                    (if (> remaining 0)
                        (begin
                          (set! remaining (sub1 remaining))
                          (yield v return))
                        (done)))))))
}

@section{Reference Code}

The code block below contains a runnable end-to-end stream, minimally and faithfully illustrating the approach described by this document.

@code{producer} produces a stream from a list.

@code{dup-transformer} is a transformer that duplicates each input value, yielding two values for each (thus serving to illustrate a multi-valued transformer).

@code{pair-transformer} is a transformer that groups values into pairs, yielding a single list value for every two input values (thus serving to illustrate buffering of values in local state). For an odd number of input values, the last value yields a singleton list.

@code{rconsumer} is a non-tail-recursive consumer (like @code{foldr}) that simply constructs a list from the stream.

@code{lconsumer} is a tail-recursive consumer (like @code{foldl}) that simply constructs a list from the stream.

@codeblock{

  (define (producer vs)
    (λ (done yield)
      (let go ([vs vs])
        (if (null? vs)
            (done)
            (yield (car vs)
                   (λ ()
                     (go (cdr vs))))))))

  (define (dup-transformer previous)
    (λ (done yield)
      (previous done
                (λ (v return)
                  (yield v
                         (λ ()
                           (yield v
                                  return)))))))

  (define (pair-transformer previous)
    (let ([buffer #false])
      (λ (done yield)
        (previous (λ ()
                    (if buffer
                        (yield (list buffer)
                               done)
                        done))
                  (λ (v return)
                    (if buffer
                        (let ([buffered-v buffer])
                          (set! buffer #false)
                          (yield (list buffered-v v)
                                 return))
                        (begin
                          (set! buffer v)
                          (return))))))))

  (define (rconsumer init previous)
    (previous (λ () init)
              (λ (v return)
                (cons v (return)))))

  (define (lconsumer init previous)
    (let ([result init])
      (previous (λ () result)
                (λ (v return)
                  (set! result (cons v result))
                  (return)))))

  (rconsumer null (dup-transformer (producer (list 1 2 3))))

  (lconsumer null (dup-transformer (producer (list 1 2 3))))

  (rconsumer null (pair-transformer (producer (list 1 2 3))))

}

@section{Future Work}

The present proposal describes streams where each segment has a single input stream and a single output stream, though these input and output streams may produce multiple values (or no values) from each input value.

There are cases where we may wish to consume multiple input streams and produce multiple output streams. An example of the former is the @code{zip} operation which merges two streams into a single stream using a specified binary operation. An example of the latter is @code{unzip}, which splits a stream into two streams using a specified function or pair of functions.

We include below a sample implementation of @code{zip} and @code{unzip}. For the single input and output streams that are the subject of this proposal, our implementation performs comparably to hand-written recursions or specialized @code{for}-based implementations. However, for multi-streams, the implementations below are significantly slower than using specialized recursion or @code{for} forms, while still being faster than using naive Racket list operations. It will be useful to understand the reasons for this, and whether the current approach could be generalized to achieve efficient multi-streams.

@codeblock{

  (define (zip-transformer left right)
    (let ([left-return #false]
          [right-return #false]
          [left-v #false])
      (λ (done yield)
        (left done
              (λ (v return)
                (set! left-return return)
                (set! left-v v)
                (if right-return
                    (right-return)
                    (right done
                           (λ (v return)
                             (set! right-return return)
                             (yield (cons left-v v)
                                    left-return)))))))))

  (define (unzip-transformer previous)
    (let ([left (λ (done yield)
                  (previous done
                            (λ (v return)
                              (yield (car v)
                                     return))))]
          [right (λ (done yield)
                   (previous done
                             (λ (v return)
                               (yield (cdr v)
                                      return))))])
      (values left right)))

  (rconsumer null (zip-transformer (producer '(a b c)) (producer '(1 2 3))))

  (call-with-values (λ () (unzip-transformer (producer '((a . 1) (b . 2) (c . 3)))))
                    (λ (left right)
                      (values (rconsumer null left)
                              (rconsumer null right))))

}

These implementations can be generalized to the variadic case by accumulating values from each input stream in succession and using a growable vector to keep track of changing returns in each of them, as seen in the accompanying proof-of-concept code.

@section{Summary}

We described in detail Qi's continuation-passing stream fusion implementation, including a natural generalization to support multiple values while preserving the performance characteristics of the single-valued implementation. This covered the stream's construction as a nest of closures; the use of @code{done} and @code{yield} continuations to implement each cycle of the stream's semantics; the addition of the @code{return} continuation which introduces "epicycles" within a cycle to support multiple yields; the distinct roles and responsibilities of the producer, each transformer, and the consumer, and how these make use of local state to express diverse semantics including counting, and accumulation of values before yielding; the subtle distinction between tail-recursive and non-tail-recursive consumers and implications for performance; and the stream's eager evaluation to a result. Finally, we considered further generalization of the approach to support multi-streams.

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
