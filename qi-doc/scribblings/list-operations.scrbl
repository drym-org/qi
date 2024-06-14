#lang scribble/doc
@require[scribble/manual
	 (for-label racket/list
	 	    racket/base)]

@title{List Operations}

@defmodule[qi/list]

This module defines bindings that can leverage stream fusion /
deforestation optimization when found in succession within a
flow. When not part of optimized flow, their behavior is identical to
the bindings of the same name from @racketmodname[racket/base] and
@racketmodname[racket/list].

The bindings are categorized based on their intended usage inside the
deforested pipeline.

@section{Producers}

@defproc*[(((range (end real?)) list?)
           ((range (start real?) (end real?) (step real? 1)) list?))]{

Deforestable version of @racket[range] from @racketmodname[racket/list].

}

@section{Transformers}

@defproc[(filter (pred procedure?) (lst list?)) list?]{

Deforestable version of @racket[filter] from @racketmodname[racket/base].

}

@defproc[(map (proc procedure?) (lst list?) ...+) list?]{

Deforestable version of @racket[map] from @racketmodname[racket/base].

}

@defproc[(filter-map (proc procedure?) (lst list?) ...+) list?]{

Deforestable version of @racket[filter-map] from @racketmodname[racket/list].

}

@defproc*[(((take (lst list?) (pos exact-nonnegative-integer?)) list?)
           ((take (lst any/c) (pos exact-nonnegative-integer?)) list?))]{

Deforestable version of @racket[take] from @racketmodname[racket/list].

}

@section{Consumers}

foldr

foldl

car

cadr

caddr

cadddr

list-ref

length

empty?

null?

