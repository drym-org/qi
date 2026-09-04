#lang scribble/base

@require[(only-in scribble/jfp abstract)
         scribble/manual
         scriblib/figure]

@title{Streams in the Core Language}

@centered{@bold{@tt{Qi Improvement Proposal (QIP)}}}
@centered{@bold{@tt{Status: @elem[#:style "status-accepted"]{@tt{ACCEPTED}}}}}

@abstract{We consider the modeling of streams via dedicated core forms and associated runtimes, in order to express functional transformations of pure values efficiently in general. We show that a unified runtime is a natural choice that expresses all streams of interest. As of yet, the unified runtime does not perform as well as the existing implementation; however, employing three separate runtimes: a producer, a transformer, and a consumer, achieves rough parity.}

@section{Background}

Qi enables a flow-oriented style of programming where control naturally follows the flow of data, and where computations are expressed in terms of elementary values rather than collections. In principle, this paradigm avoids the overhead of collections, and as it separates the computation from the data representation, it is naturally generic across data structures and runtimes.

In practice, such flows of pure values in Qi involve gratuitous construction of intermediate collections in their implementation, and are thus slow. This prevents flows from fulfilling their promise of enabling intuitive @emph{and} efficient functional operation.

@section{Guide}

@secref["The_Frustration_with_Flows"] describes the performance problems plaguing flows of values. @secref["Fixing_Flows"] describes several distinct strategies to improve performance in specific cases. @secref["Core_Streams"] introduces the goals for a general solution and proposes incorporating streams into the Qi core language. @secref["A_Unified_Runtime"] presents the main result: a runtime capable of expressing any stream. @secref["Stream_Implementations"] shows many example streams implemented as parametrizations of the unified runtime. @secref["Extension_by_Users"] suggests macros to present a friendly interface for user extension. @secref["Future_Work"] identifies some lingering performance mysteries, theoretical work, and implied refactoring of the Qi core language. Finally, @secref["Summary"] summarizes the proposal.

@section{The Frustration with Flows}

Qi defines a composable abstraction operating on pure values, called a @emph{flow}. A flow may accept any number of input values and produce any number of output values. Consider the following example:

@code{(~> (1 2 3) (pass odd?) (>< sqr))} produces the values @code{1, 9}.

This is a simple transformation of values. In principle, we could perform this operation without allocating any data structures, as none are referred to here.

Qi currently compiles this to ordinary functions and function composition. In Racket (and Chez), this supports multiple arguments and return values out of the box, making it an adequate compilation target for flows. In fact, Chez's multiple return values implementation specifically @emph{avoids any allocation of data structures} if the number of values being passed between functions is @emph{known}. In such cases, the runtime stores the values in CPU registers and the stack, exclusively, making this @emph{much faster} than, for instance, passing the multiple values as a single list value@cite{AshleyDybvig94}, which must be allocated on the heap.

Unfortunately, it's not so easy to take advantage of this in practice. A flow like @code{(pass odd?)} may generate any number of values, and it isn't possible to know this statically. Indeed, even @code{(>< f)} could generate any number of values, as @code{f} could return zero or more values and not specifically one.

For this reason, Qi flows often compile to something resembling @code{(λ args (apply f args))}.

The presence of the "rest" argument here entirely nullifies the performance benefit of using multiple values, as it necessitates a heap allocation of the intermediate data structure. In addition, the use of @code{apply} necessitates pushing all of @code{args} onto the stack in order to apply @code{f} to them. In most languages this risks stack overflow if @code{args} is large, but Chez Scheme uses a "segmented" stack meaning that it can grow without bound. However, it still incurs the penalty of stack segment allocation and bookkeeping.

We sometimes refer to this frequent conversion between values and lists (and their being pushed wholesale onto the stack) as Qi's @emph{core performance issue}.

@section{Fixing Flows}

@subsection{@code{case-lambda}}

We could ameliorate the aforementioned performance issue to some extent by compiling to a @code{case-lambda}, instead. Something like:

@codeblock{
  (case-lambda
    [() (f)]
    [(v) (f v)]
    [(a b) (f a b)]
    [args (apply f args)])
}

This would improve the situation in the not-uncommon case of very small numbers of values flowing.

@subsection{Chai}

The proposed Chai extension@cite{SamPh25} to the compiler would enable arity inference to capture additional cases as simple single-value and other fixed-arity lambdas. Single-value lambdas are the fastest, as they don't incur any arity-checking overhead@cite{AshleyDybvig94}.

But that still leaves the truly variadic case — which is idiomatic and common — unaddressed.

@subsection{Using Lists Instead}

This flow we saw earlier illustrates the variadic case:

@code{(~> (pass odd?) (>< sqr))}

Here, the analogous operation on lists is likely to be marginally faster: @code{(~> ((range 1000)) (filter odd?) (map sqr))}, even though it, too, requires construction of intermediate lists after each operation, as it at least avoids the overhead from stack segment allocation.

But we are back to square one, as this is neither generic nor efficient.

@subsection{@code{qi/list}}

Functional programming languages improve the situation by using optimizations that avoid the intermediate representations. The most prominent of these approaches is @emph{stream fusion}@cite{St-Amour12}, which translates list operations (for example) into equivalent stream operations, the latter of which are efficiently composable or "fusable."

The @code{qi/list} collection implements this approach by circumventing the ordinary compiler and attaching stream semantics to list operations. This achieves fusion, but specifically for list operations, and restricted to @emph{linear} operations that produce zero or one value at each step.

This is more restrictive than general flows, but it enabled Qi to prototype the approach in this bounded and useful special case, opening the door to generalizing it and expressing arbitrary variadic, multi-valued flows in the future.

@section{Core Streams}

In order to address the general problem in variadic flows of values, it is essential for the compiler to be able to rewrite such flows to fusable streams instead of compositions of ordinary lambdas.

This requires that streams be @emph{part of the core language}, and not simply tacked on. Additionally, the stream runtimes used in @code{qi/list} must be generalized to express multiple input and output values, i.e., the @emph{nonlinear} operations that ordinary flows of values express.

Once streams are represented in the Qi core language, generic operations on streams may be implemented as ordinary Qi macros compiling to these new stream core forms.

The challenge is: @emph{how to design core forms to exhibit all the stream semantics we seek while still being minimal and natural?}

@subsection{Our Approach}

Our approach has a practical aspect and a theoretical aspect.

We start from multi-valued continuation-passing streams which generalize those used in @code{qi/list}@cite{Pac-Man}. First, we posit the existence of a small set of stream runtimes capable of faithfully expressing all of these stream semantics by means of parameters that modulate runtime behavior. Trivially, for any finite set of semantics, such a set of runtimes must exist, as the sets could be identical, with no parametrization. But this set of runtimes would be highly specialized and not general. By introducing parameters and reconciling different streams through generalization of these parameters, it takes us deeper into an understanding of the essential nature of streams, until such a point as we reach a minimal set of parametrized runtimes that expresses the desired semantics, a set that is evidently general, and which we hope would be @emph{natural} in some sense. Finally, we introduce core forms in a one-to-one correspondence with these introduced runtimes, allowing arbitrary streams to be defined as ordinary Qi macros.

This prompts the questions:

@itemlist[#:style 'ordered
  @item{What is a representative set of stream semantics to model?}
  @item{What does this final set of parametrized runtimes look like, and is it natural?}
]

@subsection{Modeling @code{racket/list}}

For the former, we chose to model the APIs in the @code{racket/list} collection. This is a large and diverse collection, and modeling them economically would give us confidence that our derived runtimes express reasonably rich semantics.

@subsection{The Set of Runtimes}

We began with three candidate runtimes corresponding to the three types of stream segments@cite{Pac-Man}: @emph{producer}, @emph{transformer}, and @emph{consumer}. But over time there was a convergence among these three into a single runtime, as will be elaborated in the next section. The unified runtime is simpler and more theoretically satisfying, but currently performs worse (as will be discussed). We will continue to treat both the unified as well as tripartite runtimes, understanding the former as the theoretical goal for modeling streams in the core language, and the latter as the practical compromise thus far achieved.

@codeblock{
(define (producer map next stop?)
  (λ (state)
    (λ (done yield)
      (let go ([state state])
        (if (stop? state)
            (done)
            (yield (map state)
                   (λ ()
                     (go (next state)))))))))

(define (transformer map
                     [init (void)]
                     [next void]
                     [stop? (case-λ [(_v _s) #false]
                                    [(_s) #true])]
                     [exit (case-λ [(_s) (values)]
                                   [(_v _s) (values)])])
  (λ (previous)
    (let ([state init])
      (λ (done yield)
        (previous (case-λ [()
                           (let go ([state state])
                             (if (stop? state)
                                 (call-with-values (λ () (exit state))
                                                   done)
                                 (call-with-values (λ () (map state))
                                                   (case-λ [() (go (next state))]
                                                           [(v) (yield v
                                                                       (λ ()
                                                                         (go (next state))))]
                                                           [vs (let go2 ([vs vs])
                                                                 (if (null? vs)
                                                                     (go (next state))
                                                                     (yield (car vs)
                                                                            (λ ()
                                                                              (go2 (cdr vs))))))]))))]
                          [(result) (error "Expected stream.")])
                  (λ (v return)
                    (if (stop? v state)
                        (call-with-values (λ () (exit v state))
                                          done)
                        (let ([original-state state])
                          (set! state (next v state))
                          (call-with-values (λ () (map v original-state))
                                            (case-λ [() (return)]
                                                    [(fv) (yield fv return)]
                                                    [fvs (let go ([fvs fvs])
                                                           (if (null? fvs)
                                                               (return)
                                                               (yield (car fvs)
                                                                      (λ ()
                                                                        (go (cdr fvs))))))]))))))))))

(define (consumer next
                  init
                  [stop? (case-λ [(_v _s) #false]
                                 [(s) s])]
                  [exit (case-λ [(v _s) v]
                                [(s) s])]
                  [map (λ (_s) #false)])
  (λ (previous)
    (let ([result init])
      (previous (case-λ [()
                         (if (stop? result)
                             (exit result)
                             (map result))]
                        [(result) result])
                (λ (v return)
                  (set! result (next v result))
                  (if (stop? v result)
                      (exit v result)
                      (return)))))))
}

@subsection{Core Forms}

With three separate runtimes modeling streams, three corresponding core forms, @code{#%producer}, @code{#%transformer}, and @code{#%consumer}, need to be introduced. The unified runtime would simplify that further by requiring a single corresponding core form, @code{#%stream}. The existing placeholder @code{#%deforestable} may be renamed for this purpose, as it has not been publicly advertised thus far.

@section{A Unified Runtime}

As foreshadowed in the previous section, it turns out that the stream semantics of interest may be modeled using a @emph{single} runtime representing a stream segment, with only five parameters, each of which accepts two arities corresponding to two natural stream modes, of @emph{production} and @emph{consumption} of values. The runtime is first shown here, followed by annotations describing it.

@codeblock{
(define (stream map
                [init (void)]
                [next void]
                [stop? (case-λ [(_v _s) #false]
                               [(_s) #true])]
                [exit (case-λ [(_s) (values)]
                              [(_v _s) (values)])])
  (λ (previous)
    (let ([state init])
      (λ (done yield)
        (previous
         (case-λ [()
                  (let go ([state state])
                    (if (stop? state)
                        (call-with-values
                         (λ () (exit state))
                         done)
                        (call-with-values
                         (λ () (map state))
                         (case-λ [() (go (next state))]
                                 [(v) (yield v
                                             (λ ()
                                               (go (next state))))]
                                 [vs (let go2 ([vs vs])
                                       (if (null? vs)
                                           (go (next state))
                                           (yield (car vs)
                                                  (λ ()
                                                    (go2 (cdr vs))))))]))))]
                 [(result) (error "Expected stream.")])
         (λ (v return)
           (if (stop? v state)
               (call-with-values
                (λ () (exit v state))
                done)
               (let ([original-state state])
                 (set! state (next v state))
                 (call-with-values
                  (λ () (map v original-state))
                  (case-λ [() (return)]
                          [(fv) (yield fv return)]
                          [fvs (let go ([fvs fvs])
                                 (if (null? fvs)
                                     (return)
                                     (yield (car fvs)
                                            (λ ()
                                              (go (cdr fvs))))))]))))))))))
}

@subsection{A Stream Segment}

The runtime is an abstraction of a @emph{stream segment} in the underlying continuation-passing stream paradigm. It is a function. Its arguments are the @emph{parameters} (typically functions) that modulate choices made in the runtime at every meaningful juncture. In the code above, @code{previous} refers to the preceding stream segment in the continuation-passing implementation, while @code{done}, and @code{yield} are continuations received from the @emph{next} stream segment. This architecture is inherited directly from Qi's existing continuation-passing stream implementation in @code{qi/list}, generalized to multiple values@cite{Pac-Man}. The two main branches in the function are the runtime's specification of the @code{done} and @code{yield} continuations (passed to the @emph{previous} segment), respectively.

Stream segments fall into three clear conceptual categories: producers, transformers, and consumers. One would expect, on these grounds, that there might be three corresponding runtimes that would be natural. This was the initial approach taken, and three runtimes worked well, but it was eventually noticed that the transformer runtime contained both producer and consumer runtimes embedded in it. This makes sense in retrospect, since the transformer must play both producer and consumer roles, depending on the context.

Thus, it became possible for the transformer runtime @emph{on its own} (shown above) to model all producers and consumers. It was only necessary to attach an initial, "universal" producer to the stream in the former case, and, likewise, a universal consumer at the end in the latter (distinct from the producer and consumer runtimes in the tripartite model considered earlier).

@subsection{The Universal Producer}

Generally, a stream segment accepts @code{done} and @code{yield} continuations through which values computed by the segment may be forwarded to the next segment. The universal producer operates by simply invoking the done continuation of the "actual" producer, thus abdicating control to it.

@codeblock{
  (λ (done _yield)
    (done))
}

The universal producer is passed as the @code{previous} argument to "actual" producers, as can be seen in the examples in @secref["Stream_Implementations"].

@subsection{The Universal Consumer}

A consumer defined using the unified runtime computes a value and forwards it via the @code{done} continuation. In order to terminate evaluation, a universal consumer must be attached at the end to receive this value and simply terminate with that result. So the @code{done} continuation of the universal consumer is simply:

@codeblock{
  values
}

Recall that any stream segment is a closure that accepts @code{done} and @code{yield} continuations as arguments@cite{Pac-Man}, which are passed by the @emph{next} segment. When invoked, it defines both @code{done} and @code{yield} continuations for the @emph{previous} segment. But for the universal consumer, as its @code{yield} continuation would never be called (since the previous segment, as the "actual" consumer, does not @code{yield}), its definition is arbitrary.

Thus, the "actual" consumer is simply applied to the universal consumer's @code{done} and (an arbitrary) @code{yield} — defining the stream's terminus — when it is invoked, as can be seen in the examples in @secref["Stream_Implementations"].

@subsection{The Parameters}

In addition to the essential semantics of direct computations on values, the parametrized runtime supports local state in order to implement operations such as @code{take} (which must track the number of values seen), and buffering to enable produced values to be conditioned on sequences of values rather than just one. It also supports early termination or "shortcircuiting" to avoid redundant computations at the point when a result is known, such as in @code{take} and in @code{list-ref}.

All of these semantics of the underlying stream runtime are modulated by means of parameters which are specified by each specific stream implementation. These parameters are:

@itemlist[
  @item{@code{map} — how to transform each value.}
  @item{@code{init} — an initial state.}
  @item{@code{next} — a state transition function.}
  @item{@code{stop?} — when to stop processing values.}
  @item{@code{exit} — what result to forward downstream after stopping.}
]

@code{init} is a simple value, while @code{map}, @code{init}, @code{next}, @code{stop?} and @code{exit} are each dual-arity functions accepting one, or two, or either one or two, arguments. Streams may provide either or both of these arities in defining each parameter, as will be discussed further in the next section.

By means of these parameters, the unified runtime, the universal producer, and the universal consumer together model all streams of interest.

@subsection{Naturality}

In a stream segment's @code{yield} continuation, the segment receives a value from the preceding segment and incorporates it into the local state. In this respect, the segment is operating as a @emph{consumer} (cf. @code{foldl}). It may optionally yield a value after deliberation, in which case it also acts as a producer.

In the stream segment's @code{done} continuation, the context is that all preceding segments have signaled that the stream is exhausted and have concluded their operation. Thus, the present segment now assumes the role of @emph{producer}, operating on locally accumulated state alone (and no fresh values).

Corresponding to this dual nature, as we saw, the parameters each have two arities: one accepting both value and current state ("consumer" mode — used exclusively within the scope of @code{yield}), and the other accepting only the state ("producer" mode — used exclusively within the scope of @code{done}).

The @code{stop?} and @code{next} parameters modulate both producer and consumer roles, and support both arities.

The @code{map} parameter pertains exclusively to the producer role, but it still supports both arities. This is because for transformers, the yielding of a value is most naturally expressed as a function of the fresh value and the @emph{a priori} state (e.g., @code{take}), and so we cannot pass only the state as it has not yet incorporated the fresh value. Similarly, the @code{exit} parameter pertains exclusively to the consumer role, and yet it too supports both arities. This is necessary because transformers may signal early termination with the received value as the result of evaluation (e.g., @code{list-ref}), though most rely on the ordinary identification of the result with the accumulated state in the consumer.

Perhaps these two parameters should be rightfully thought of as true "transformer" parameters, empowering the transformer to assume @emph{either} role at any time.

This structure of the runtime and the dichotomy in its parameters reveals the nature of a transformer as being nothing other than a segment that is @emph{both consumer and producer}, which corresponds to intuition, and gives us confidence that the runtime is indeed @emph{natural}.

@section{Stream Implementations}

This section enumerates parametrizations of the unified runtime that achieve the semantics of some select standard operators. For reference, the order of the parameters passed as arguments to @code{stream} is: @code{map}, @code{init}, @code{next}, @code{stop?}, @code{exit}.

@subsection{@code{list→stream}}

@codeblock{
  (define (list→stream vs)
    ((stream car
             vs
             cdr
             null?)
     (λ (done _yield)
       (done))))
}

@subsection{@code{range}}

@codeblock{
  (define (range low high step)
    ((stream values
             low
             (λ (s) (+ s step))
             (λ (s) (>= s high)))
     (λ (done _yield)
       (done))))
}

@subsection{@code{map}}

@codeblock{
  (define (map f previous)
    ((stream (λ (v _s) (f v)))
     previous))
}

@subsection{@code{filter}}

@codeblock{
  (define (filter pred previous)
    ((stream (λ (v _s) (if (pred v) v (values))))
     previous))
}

@subsection{@code{take}}

@codeblock{
  (define (take n previous)
    ((stream (case-λ [(v _s) v]
                     [(_s) (error "out of elements")])
             0
             (λ (_v s) (add1 s))
             (case-λ [(_v s) (= n s)]
                     [(s) (= n s)]))
     previous))
}

@subsection{@code{foldl}}

@codeblock{
  (define (foldl op init previous)
    (((stream (λ (_v _s) (values))
              init
              op
              (case-λ [(_v _s) #false]
                      [(_s) #true])
              (λ (s) s))
      previous)
     values
     (λ (_v _s) (values))))
}

@subsection{What about @code{foldr}?}

While @code{foldl} is tail-recursive, consuming values one at a time and incorporating them into the result on-the-fly — as the unified runtime does — @code{foldr} instead builds up a stack of operations that may only be evaluated at the conclusion of the stream. Using the unified runtime to implement @code{foldr} would require reversing the stream and then using @code{foldl} instead of @code{foldr}. Since this incurs an intermediate allocation cost, we opt to implement @code{foldr} as a one-off, non-tail-recursive consumer in the compiler, not in terms of the unified runtime.

Similarly, although @code{stream→list} could be implemented using the unified runtime, it would involve a call to @code{racket/list}'s @code{reverse} at the end (via the @code{exit} parameter), likewise incurring an extra allocation cost. Since this is such a common operation, we opt to use an ad hoc implementation in the compiler (e.g., using unsafe list operations to avoid reversal) rather than the unified runtime.

@section{Extension by Users}

As the stream runtime has a corresponding @code{#%stream} core form, implementing a custom stream is a simple matter of writing an ordinary Qi macro.

The runtime is sufficiently complex, however, that parametrizing it directly via its basic function interface is not very suggestive. To support users in writing custom streams, it would be best to provide a set of macros or a mini-DSL.

At a minimum, @code{define-producer}, @code{define-transformer}, and @code{define-consumer} macros would be useful as the specification of parameters does partition along these categories. For instance, only consumers have the universal consumer attached, and they share common definitions of various parameters. Likewise, only producers attach the universal producer, and they similarly share commonalities in their parameter specifications. Different defaults make sense in these different categories, and thus motivate separate defining macros.

It would even be possible to provide a DSL for describing streams (indeed, users could write their own such DSLs compiling to the @code{#%stream} core form!). The parameters are all functions, so having them be @code{floe} in the syntax makes a lot of sense and would be the most intuitive. Yet, Qi has no concept of a @code{case-lambda}, and so it may make sense to accept the two modes of the parameters as @emph{separate} @code{floe}s, and then perform some inference in the compiler to synthesize these into @code{case-lambda}s for the sake of performance, since we know the arities statically and they are fixed.

On a forward-looking note, it seems reasonable for such a DSL to be considered a @emph{hosted} Qi DSL, which suggests the possibility of generalizing Syntax Spec (the language implementing Qi's hosted architecture on Racket) to elegantly express this case and enable special compilation for this DSL on top of, and prior to, Qi compilation. Otherwise, the optimizations (including to @code{case-lambda}) would likely need to be part of the macro definitions, or, of course, could be obviated by writing macros that expand directly to @code{#%stream} using @code{esc}aped @code{case-lambda}s. Writing new streams is perhaps rare enough that this may be sufficient.

@section{Future Work}

@subsection{Performance Challenges and Mysteries}

While separate producer, transformer, and consumer runtimes perform comparably to the naive Pac-Man implementation, the unified, parametrized runtime performs worse in streams of length greater than one. We discuss a few guesses as to why, along with possible ways of alleviating the slowdown.

One possible reason is that Chez Scheme's multiple values interface provides a no-penalty fast path for single-value returns but not for zero-value returns, which incur a modest penalty along the "fixed arity" path. The unified runtime makes frequent use of zero-value returns, especially to "return" to production of values earlier in the stream, and also to exit in typical cases through the universal consumer. If this is indeed to blame, it may be worth identifying the impact more comprehensively and proposing a zero value fast path in upstream Chez.

Another possible culprit is that the naive Pac-Man implementation does not support mid-stream exit with a specific result, as the @code{member} transformer does when it returns @code{#false} if the element isn't found. In order to support this, the unified runtime makes @code{done} a case-lambda that accepts either zero or one argument. Since the former now falls under the fixed-arity return path rather than the statically known arity path that was formerly the case with a simple lambda, it's possible that this causes the slowdown, once again, due to arity-0 not being a special no-penalty path the way that arity-1 is.

@subsection{Mathematical Formalism}

While being able to model @code{racket/list} gives us empirical proof of a reasonable level of generality, and the clues to "naturality" give us confidence, it would be illuminating to undertake a theoretical formalization and understand this precisely.

Unlike lists and vectors, a stream is not a data structure located in @emph{space}, but is a way of computing a series of @emph{temporally ordered} values. The computed values may themselves be data structures of any kind, but are typically just primitive values such as numbers. In other words, a stream is a particular kind of @emph{evaluator}, or a @emph{language}.

Yet, this evaluation appears to have a strong structural relationship to sequential types such as lists, making it a suitable strategy for computing operations on these sequences. A mathematical model for streams would be invaluable in understanding this more deeply, and whether our unified runtime and parameters are truly universal in expressing all streams. And if not, it could suggest changes that would be needed in order to make it so.

@subsection{Compressing the Core Language}

With a faithful model of streams in the core language, it becomes possible to implement many of Qi's existing core forms using the new stream runtime. This includes at least @code{><} and @code{pass}, but, if our model is truly universal in expressing multi-valued transformations, and with further generalization to multi-streams such as @code{zip}, it may be possible to express ever more of the Qi core language using the new stream primitives.

@section{Summary}

We first discussed a longstanding issue with the performance of Qi flows of pure values that prevents these flows from fulfilling their promise of efficient, generic, functional sequence operations. We then identified a number of strategies to ameliorate special cases, and proposed adding a unified stream runtime to the core language as a natural solution to the general case. We showed how the unified runtime is capable of expressing diverse stream semantics modeling the operations in @code{racket/list}, achieved by means of specifying @code{floe} parameters modulating every aspect of the runtime, of which several examples were given. We identified some performance challenges that remain to be addressed, foreshadowed a compression of the Qi core language by reducing existing core forms to streams, suggested a macro interface to streamline extension by users, and discussed the need for mathematical formalization in order to better understand the limits of the proposed stream model.

@(bibliography

  (bib-entry #:key "AshleyDybvig94"
             #:author "J. Michael Ashley and R. Kent Dybvig"
             #:title "An Efficient Implementation of Multiple Return Values in Scheme"
             #:date "1994"
             #:url "https://dl.acm.org/doi/10.1145/182590.156784")

  (bib-entry #:key "SamPh25"
             #:author "Sam D. Phillips"
             #:title "Chai: An Alternative Compiler for Core Qi"
             #:date "2025"
             #:url "https://github.com/samdphillips/chai-demo")

  (bib-entry #:key "St-Amour12"
             #:author "Vincent St-Amour"
             #:title "Deforestation"
             #:date "2012"
             #:url "https://www.ccs.neu.edu/home/amal/course/7480-s12/deforestation-notes.pdf")

  (bib-entry #:key "Pac-Man"
             #:author "Qiwis"
             #:title "Virtual Multi-valued Streams, or Pac-Man Continuations"
             #:date "2026"
             #:url "https://countvajhula.com/oldsite/qi/pacman/")

)
