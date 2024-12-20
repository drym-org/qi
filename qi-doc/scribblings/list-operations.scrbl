#lang scribble/doc
@require[scribble/manual
         (for-label racket/list
                    racket/base)]

@title{List Operations}

@defmodule[qi/list]

This module defines functional list operations analogous to those in
@racketmodname[racket/base] and @racketmodname[racket/list], except
that these forms support @tech{flows} in higher-order function
positions and leverage the @seclink["Don_t_Stop_Me_Now"]{stream fusion
/ deforestation} optimization to avoid constructing intermediate
representations along the way to computing the result.

The forms in this module extend the syntax of the @seclink["The_Qi_Core_Language"]{core Qi language}. This extended syntax is given below:

@racketgrammar*[
[floe (map floe)
      (filter floe)
      (filter-map floe)
      (foldl floe expr)
      (foldr floe expr)
      (range expr expr expr)
      (take expr)
      car
      cadr
      caddr
      cadddr
      (list-ref expr)
      length
      empty?
      null?]]

The operations are categorized based on their role in the deforested
pipeline.

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

@defproc[(foldl (proc procedure?) (init any/c) (lst list?) ...+) any/c]{

Deforestable version of @racket[foldl] from @racketmodname[racket/base].

}

@defproc[(foldr (proc procedure?) (init any/c) (lst list?) ...+) any/c]{

Deforestable version of @racket[foldr] from @racketmodname[racket/base].

}

@defproc[(car (p pair?)) any/c]{

Deforestable version of @racket[car] from @racketmodname[racket/base].

}

@defproc[(cadr (v (cons/c any/c pair?))) any/c]{

Deforestable version of @racket[cadr] from @racketmodname[racket/base].

}

@defproc[(caddr (v (cons/c any/c (cons/c any/c pair?)))) any/c]{

Deforestable version of @racket[caddr] from @racketmodname[racket/base].

}

@defproc[(cadddr (v (cons/c any/c (cons/c any/c (cons/c any/c pair?))))) any/c]{

Deforestable version of @racket[cadddr] from @racketmodname[racket/base].

}

@defproc*[(((list-ref (lst list?) (pos exact-nonnegative-integer?)) any/c)
 	   ((list-ref (lst pair?) (pos exact-nonnegative-integer?)) any/c))]{

Deforestable version of @racket[list-ref] from @racketmodname[racket/base].

}

@defproc[(length (lst list?)) exact-nonnegative-integer?]{

Deforestable version of @racket[length] from @racketmodname[racket/base].

}

@defproc[(empty? (v any/c)) boolean?]{

Deforestable version of @racket[empty?] from @racketmodname[racket/list].

}

@defproc[(null? (v any/c)) boolean?]{

Deforestable version of @racket[null?] from @racketmodname[racket/base].

}


