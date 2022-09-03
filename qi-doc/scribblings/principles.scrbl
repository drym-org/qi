#lang scribble/doc
@require[scribble/manual
         scribble-abbrevs/manual
         scribble/example
         racket/sandbox
         scribble-math
         @for-label[qi
                    racket]]

@(define eval-for-docs
  (parameterize ([sandbox-output 'string]
                 [sandbox-error-output 'string]
                 [sandbox-memory-limit #f])
    (make-evaluator 'racket/base
                    '(require qi
                              (only-in racket/list range)
                              racket/string)
                    '(define (sqr x)
                       (* x x)))))

@(use-mathjax)

@title{Principles of Qi}

 After many patient hours meticulously crafting Qi flows, you may find that you seek a deeper understanding; insight into guiding principles and inner workings, so that you can hone your skills on firmer ground.

 Welcome. Your wanderings have brought you to the right place. In this section, we will cover various topics that will help you have a fuller understanding and a sound conceptual model of how Qi works. This kind of facility with the fundamentals will be useful as you employ Qi for more complex tasks, enabling you to engage in higher level reasoning about the task at hand rather than be mired in conceptual building blocks.

@table-of-contents[]

@section{What is a Flow?}

 A @deftech{flow} is either made up of flows, or is a native (e.g. Racket) @seclink["lambda" #:doc '(lib "scribblings/guide/guide.scrbl")]{function}. Flows may be composed using a number of combinators that could yield either linear or nonlinear composite flows.

 A flow in general accepts @code{m} inputs and yields @code{n} outputs, for arbitrary non-negative integers @code{m} and @code{n}. We say that such a flow is @code{m × n}.

 The semantics of a flow is function invocation -- simply invoke a flow with inputs (i.e. ordinary arguments) to obtain the outputs.

 The Qi language allows you to describe and use flows in your code.

@section{Values, Paths and Flows}

@emph{Flows} accept inputs and produce outputs -- they are functions. The things that flow -- the inputs and outputs -- are @emph{values}. Yet, values do not actually "move" through a flow, since a flow does not mutate them. The flow simply produces new values that are related to the inputs by a computation.

 Every flow is made up of components that are themselves flows. Thus, each of these components is a relationship between an input set of values and an output set of values, so that at every level, flows produce sequences of sets of values beginning with the inputs and ending with the outputs, with each set related to the preceding one by a computation, and again, no real "motion" of values at all. There may be many such distinct @deftech{paths} over flow components that could be traced (borrowing the term "path" as used in graph theory in this sense), and we may imagine values to flow along these paths.

 So indeed, when we say that values "flow," there is nothing in fact that truly flows, and it is merely a convenient metaphor.

@section{Values are Not Collections}

 The things that flow are values. Individual values may happen to be collections such as lists, but the values that are flowing are not, together, a collection of any kind.

 To understand this with an example: when we employ a tee junction in a flow, colloquially, we might say that the junction "divides the flow into two," which might suggest that there are now two flows. But in fact, there is just one flow that divides @emph{values} down two separate flows which are part of its makeup. More precisely, @racket[-<] composes two flows to yield a single composite flow. Like any flow, this composite flow accepts values and produces values, not collections of values. There is no way to differentiate, at the output end, which values came from the first channel of the junction and which ones came from the second, since downstream flows have no idea about the structure of upstream flows and only see the values they receive.

 The way to group values, if we need grouping, is to collect them into a data structure (e.g. a list) using a collection prism, @racket[▽]. In the case of a tee junction, the way to differentiate between values coming from each channel of the junction is for the channels to individually @racket[collect] their values at the end. That way, the values that are the output of the composite flow are lists generated individually by the various channels of the flow.

@section{Everything is a Function}

Everything in Qi is a @seclink["lambda" #:doc '(lib "scribblings/guide/guide.scrbl")]{function}. Programs are functions, they are made up of functions. Even @seclink["Literals"]{literals} are interpreted as functions generating them.

@section{Flowy Logic}

Qi's design is inspired by buddhist śūnyatā logic. To understand it holistically would require a history lesson to put the sunyata development in context, and that would be quite a digression. But in essence, sunyata is about transcension of context or viewpoint. A viewpoint entails a logical span of possibilities (@emph{catuṣkoṭi}) in terms of which assertions may be made. Sunyata is the rejection of @emph{all} of the available logical possibilities, thus transcending the very framing of the problem (this is signified by the word @emph{mu} in Zen). This kind of transcension could suggest alternative points of view, but more precisely, indicates no point of view at all (which isn't the same as being ambivalent!). This idea has implications not just for formal logical systems but also for everyday experience and profound metaphysical questions alike.

But for the purposes of Qi, what it means is that the existence of a value is a logical span within which it takes on specific forms. Sunyata is the difference between a value taking on a form indicating tangible output (e.g. @racket[5] or @racket["hello"]) or indicating absence (e.g. @racket[(void)] or @racket[""]) or failure (e.g. @racket[#f]), or provisionality (e.g. @racket['suspended]) or certainty (e.g. @racket[#t]) -- it's the difference between these, and not existing at all.

The same considerations extend the other way as well, from nonexistence to existence to existence of more than one. As each value corresponds to an independent logical span of possibilities, sunyata in the context of Qi translates into the core paradigm being the existence/non-existence and consequently also the number of values at each point in the flow.

In practice, this means that Qi will often opt to either return or not return a value rather than return a value signifying absence or raise an error. This principle even suggests considerations for the design of ordinary functions and the evaluator itself, which from a Qi/sunyata perspective, could model absence and number in positions that typically expect values.

For example, the following would seem to be in accord with these principles:

@itemlist[
   @item{Variadic functions, on receiving no input, produce a nullary value (e.g. a monoid identity) if applicable, or no output otherwise, instead of raising an error. For instance, @racket[(max)] currently raises an error, and under this guideline would produce no output, instead.}
   @item{Upon receiving multiple values in positions where a single value is expected, the evaluator "forks" the continuation so that each possibility is independently (combinatorially) evaluated. The results from these parallel computations could be "flattened" as multiple output values, but it may be more correct to evaluate them instead as completely independent computations. These could be manipulated distinctly -- for instance, each forked continuation could be fulfilled by a distinct process, and the evaluator could provide a means to refer to the output of these processes from within the language or in a metalanguage, while keeping the processes themselves abstracted. @racket[(cons (values 1 2) (list 3))] independently produces @racket[(list 1 3)] and @racket[(list 2 3)].}
   @item{Upon receiving @emph{no} values in positions where a single value is expected, there are a few cases to consider. If no values were received in a position corresponding to the "object" of the function, in the grammatical sense, then the function produces no values. If no values were received in another position, then the function produces the input object(s) (again, objects in the grammatical sense) -- which would be consistent with the expected output type. If there is more than one object position, then the result of the function is empty if @emph{any} of the object positions is. If no values were received in a position serving another grammatical role (e.g. a modifier or adverb such as a function-valued argument), the function generally produces nothing. In none of these cases does the function raise an error. @racket[(cons (values) (list 1 2 3))] produces @racket[(list 1 2 3)], while @racket[(cons 1 (values))], @racket[(add-two-numbers (values) 5)], and @racket[(sort (values) (list 2 3 1))] (where the first argument position indicates a comparator function to be used in sorting) produce nothing.}
   @item{If the function receives valid inputs but is unable to produce a valid result (for instance, if the inputs fail some runtime requirement), it produces nothing.}
   @item{If an @emph{invalid} input (such as one of an unexpected type) is received, the function raises an error.}
  ]

See @secref["Write_Yourself_a_Maybe_Monad_for_Great_Good"] for an example that applies some of these ideas to implement the Maybe monad commonly used in many functional languages. Although, note that if the above design were adopted by the underlying language and interpreter, Maybe would be unnecessary in most cases.

@section{Phrases}

When reading languages like English, we understand what we read in terms of words and then phrases and the relationship of these phrases to one another as clauses of a sentence, and then the relationship of sentences to one another, and then paragraphs to one another. The resourceful speed readers among us even do this in the reverse order at first, discerning high level structure before parsing the low level component meanings. Just like human languages, Qi expressions exhibit phrase structure that we can leverage in similar ways. Here are some common phrases in the language to get you started thinking about the language in this way.

@;clarify arity of adaptation; and scribble mathify some of these things (and review/distinguish from code); and add diagrams - look at the prolog bookmark for the fold diagram
@itemlist[
   @item{@racket[(~> △ (>< f) ...)] -- "sep-amp". A standard mapping over values extracted from a list.}
   @item{@racket[(~> (-< _ f ...) ...)] -- "augment". The tee junction may augment the flow in any order -- the signature of this phrase is the presence of a @racket[_] in the tee junction.}
   @item{@racket[(~> (-< f ...) g)] -- "diamond composition". This is one way to adapt a flow @racket[f] of arity @${k} to a flow @racket[g] of arity @${m}, that is, by branching the @${k} inputs into @${m} copies of @racket[f] (assuming @racket[f] produces one output). It is the same as the "composition operator" used in defining @hyperlink["https://en.wikipedia.org/wiki/Primitive_recursive_function"]{primitive recursive functions}.}
   @item{@racket[(group 1 car-flo cdr-flo)] -- "pare". This is analogous to "car and cdr" style destructuring with lists, but for segregating values instead. Note that while it is analogous, this isn't "destructuring," since the values taken together @seclink["Values_are_Not_Collections"]{do not form a data structure}.}
  ]

Some of these phrases may someday make it into the language as forms themselves, and there may be higher-level phrases still, made up of such phrases.

@section{Identities}

Here are some useful identities for the core routing forms. They can be used to simplify your code or say things in different ways.

@$${(\sim> (\sim> f g) h) = (\sim> f (\sim> g h)) = (\sim> f g h)} [associative law]
@$${(\sim> f \_) = (\sim> \_ f) = (\sim> f) = f} [left and right identity]
@$${(== (\sim> f₁ g₁) (\sim> f₂ g₂)) = (\sim> (== f₁ f₂) (== g₁ g₂))}
@$${(\sim> (>< f) (>< g)) = (>< (\sim> f g))}
@$${(\sim> \_ \cdots) = \_}
@$${(== \_ \ldots) = \_}
@$${(>< \_) = \_}
@$${(-< f) = f}
@$${(-< (\text{gen} a) (\text{gen} b)) = (-< (\text{gen} a b))}
@$${(\sim> △ ▽) = \_ = (\sim> ▽ △) \text{(the former only holds when the input is a list)}}

@section{Flows and Arrows}

[@emph{The connection between flows and arrows was pointed out by Sergiu Ivanov (Scolobb on Discourse).}]

It turns out that the core routing forms of Qi fulfill the definition of @hyperlink["https://www.haskell.org/arrows/"]{arrows} in category theory and Haskell (in an unfortunate conflation of terminology, these "arrows" are an entirely different notion than morphisms, which are also sometimes referred to as arrows). The specific correspondence is as follows:

@itemlist[
 @item{Qi's "base case" of @seclink["What_is_a_Flow_"]{treating any function as a flow} corresponds to the @racket[arr] method of arrows.}
 @item{@racket[~>] is equivalent to the @racket[(>>>)] of arrows.}
 @item{The @racket[relay], and specifically, @racket[(== a _)], @racket[(== _ b)], and @racket[(== a b)], respectively correspond to @racket[first], @racket[second], and their composite @racket[(***)] in arrows.}
 @item{@racket[(-< f g)] corresponds to what is referred to as "fanout composition", @racket[(&&&)], in arrows.}
]

So evidently, flows are just @hyperlink["https://www.sciencedirect.com/science/article/pii/S1571066106001666/pdf"]{monoids in suitable subcategories of bifunctors} (what's the problem?), or, in another way of looking at it, @hyperlink["https://bentnib.org/arrows.pdf"]{enriched Freyd categories}.

Therefore, any theoretical results about arrows should generally apply to Qi as well (but not necessarily, since Qi is not @emph{just} arrows).

@close-eval[eval-for-docs]
@(set! eval-for-docs #f)
