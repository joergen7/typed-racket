#lang scribble/manual

@begin[(require "../utils.rkt"
                "numeric-tower-pict.rkt"
                scribble/example
                racket/sandbox)
       (require (for-label (only-meta-in 0 [except-in typed/racket for])
                           racket/async-channel))]

@(define the-eval (make-base-eval))
@(the-eval '(require (except-in typed/racket #%top-interaction #%module-begin)))
@(define the-top-eval (make-base-eval))
@(the-top-eval '(require (except-in typed/racket #%module-begin)
                         racket/flonum racket/extflonum racket/fixnum))

@(define-syntax-rule (ex . args)
   (examples #:eval the-top-eval . args))


@title[#:tag "type-ref"]{Type Reference}

@deftype[Any]{Any Racket value. All other types are subtypes of @racket[Any].}

@deftype[AnyValues]{Any number of Racket values of any type.}

@deftype[Nothing]{The empty type.  No values inhabit this type, and
any expression of this type will not evaluate to a value.}

@section{Base Types}

@(define-syntax-rule
   (defnums (ids ...) . rest)
   (deftogether ((deftype ids) ...) . rest))

@subsection{Numeric Types}

These types represent the hierarchy of @rtech{numbers} of Racket. The
diagram below shows the relationships between the types in the hierarchy.

@centered[@numeric-tower-pict]

The regions with a solid border are @emph{layers} of the numeric hierarchy
corresponding to sets of numbers such as integers or rationals. Layers
contained within another are subtypes of the layer containing them. For
example, @racket[Exact-Rational] is a subtype of @racket[Exact-Number].

The @racket[Real] layer is also divided into positive and negative types
(shown with a dotted line). The @racket[Integer] layer is subdivided into
several fixed-width integers types, detailed later in this section.

@defnums[(Number Complex)]
@racket[Number] and @racket[Complex] are synonyms. This is the most general
numeric type, including all Racket numbers, both exact and inexact, including
complex numbers.

@defnums[(Integer)]
Includes Racket's exact integers and corresponds to the
@racket[exact-integer?] predicate. This is the most general type that is still
valid for indexing and other operations that require integral values.

@defnums[(Float Flonum)]
Includes Racket's double-precision (default) floating-point numbers and
corresponds to the @racket[flonum?] predicate. This type excludes
single-precision floating-point numbers.

@defnums[(Single-Flonum)]
Includes Racket's single-precision floating-point numbers and corresponds to
the @racket[single-flonum?] predicate. This type excludes double-precision
floating-point numbers.

@defnums[(Inexact-Real)]
Includes all of Racket's floating-point numbers, both single- and
double-precision.

@defnums[(Exact-Rational)]
Includes Racket's exact rationals, which include fractions and exact integers.

@defnums[(Real)]
Includes all of Racket's real numbers, which include both exact rationals and
all floating-point numbers. This is the most general type for which comparisons
(e.g. @racket[<]) are defined.

@defnums[(
Exact-Number
Float-Complex
Single-Flonum-Complex
Inexact-Complex
Imaginary
Exact-Complex
Exact-Imaginary
Inexact-Imaginary)]
These types correspond to Racket's complex numbers.

@history[#:changed "1.7"]{@elem{Added @racket[Imaginary],
 @racket[Inexact-Complex],
 @racket[Exact-Complex],
 @racket[Exact-Imaginary],
 @racket[Inexact-Imaginary].}}

The above types can be subdivided into more precise types if you want to
enforce tighter constraints. Typed Racket provides types for the positive,
negative, non-negative and non-positive subsets of the above types (where
applicable).

@defnums[(
Positive-Integer
Exact-Positive-Integer
Nonnegative-Integer
Exact-Nonnegative-Integer
Natural
Negative-Integer
Nonpositive-Integer
Zero
Positive-Float
Positive-Flonum
Nonnegative-Float
Nonnegative-Flonum
Negative-Float
Negative-Flonum
Nonpositive-Float
Nonpositive-Flonum
Float-Negative-Zero
Flonum-Negative-Zero
Float-Positive-Zero
Flonum-Positive-Zero
Float-Zero
Flonum-Zero
Float-Nan
Flonum-Nan
Positive-Single-Flonum
Nonnegative-Single-Flonum
Negative-Single-Flonum
Nonpositive-Single-Flonum
Single-Flonum-Negative-Zero
Single-Flonum-Positive-Zero
Single-Flonum-Zero
Single-Flonum-Nan
Positive-Inexact-Real
Nonnegative-Inexact-Real
Negative-Inexact-Real
Nonpositive-Inexact-Real
Inexact-Real-Negative-Zero
Inexact-Real-Positive-Zero
Inexact-Real-Zero
Inexact-Real-Nan
Positive-Exact-Rational
Nonnegative-Exact-Rational
Negative-Exact-Rational
Nonpositive-Exact-Rational
Positive-Real
Nonnegative-Real
Negative-Real
Nonpositive-Real
Real-Zero
)]
@racket[Natural] and @racket[Exact-Nonnegative-Integer] are synonyms. So are
the integer and exact-integer types, and the float and flonum
types. @racket[Zero] includes only the integer @racket[0]. @racket[Real-Zero]
includes exact @racket[0] and all the floating-point zeroes.

These types are useful when enforcing that values have a specific
sign. However, programs using them may require additional dynamic checks when
the type-checker cannot guarantee that the sign constraints will be respected.

In addition to being divided by sign, integers are further subdivided into
range-bounded types. The relationships between most of the range-bounded types
are shown in this diagram:

@centered[@integer-pict]

Like the previous diagram, types nested inside of another in the
diagram are subtypes of its containing types.

@defnums[(
One
Byte
Positive-Byte
Index
Positive-Index
Fixnum
Positive-Fixnum
Nonnegative-Fixnum
Negative-Fixnum
Nonpositive-Fixnum
)]
@racket[One] includes only the integer @racket[1]. @racket[Byte] includes
numbers from @racket[0] to @racket[255]. @racket[Index] is bounded by
@racket[0] and by the length of the longest possible Racket
vector. @racket[Fixnum] includes all numbers represented by Racket as machine
integers. For the latter two families, the sets of values included in the types
are architecture-dependent, but typechecking is architecture-independent.

These types are useful to enforce bounds on numeric values, but given the
limited amount of closure properties these types offer, dynamic checks may be
needed to check the desired bounds at runtime.

@ex[
7
8.3
(/ 8 3)
0
-12
3+4i]

@defnums[(
ExtFlonum
Positive-ExtFlonum
Nonnegative-ExtFlonum
Negative-ExtFlonum
Nonpositive-ExtFlonum
ExtFlonum-Negative-Zero
ExtFlonum-Positive-Zero
ExtFlonum-Zero
ExtFlonum-Nan
)]
80-bit @rtech{extflonum} types, for the values operated on by
@racketmodname[racket/extflonum] exports.
These are not part of the numeric tower.

@subsection{Other Base Types}

@deftogether[(
@deftype[Boolean]
@deftype[True]
@deftype[False]
@deftype[String]
@deftype[Keyword]
@deftype[Symbol]
@deftype[Char]
@deftype[Void]
@deftype[Input-Port]
@deftype[Output-Port]
@deftype[Unquoted-Printing-String]
@deftype[Port]
@deftype[Path]
@deftype[Path-For-Some-System]
@deftype[Regexp]
@deftype[PRegexp]
@deftype[Byte-Regexp]
@deftype[Byte-PRegexp]
@deftype[Bytes]
@deftype[Namespace]
@deftype[Namespace-Anchor]
@deftype[Variable-Reference]
@deftype[Null]
@deftype[EOF]
@deftype[Continuation-Mark-Set]
@deftype[Undefined]
@deftype[Module-Path]
@deftype[Module-Path-Index]
@deftype[Resolved-Module-Path]
@deftype[Compiled-Module-Expression]
@deftype[Compiled-Expression]
@deftype[Internal-Definition-Context]
@deftype[Pretty-Print-Style-Table]
@deftype[Special-Comment]
@deftype[Struct-Type-Property]
@deftype[Impersonator-Property]
@deftype[Read-Table]
@deftype[Bytes-Converter]
@deftype[Parameterization]
@deftype[Custodian]
@deftype[Inspector]
@deftype[Security-Guard]
@deftype[UDP-Socket]
@deftype[TCP-Listener]
@deftype[Logger]
@deftype[Log-Receiver]
@deftype[Log-Level]
@deftype[Thread]
@deftype[Thread-Group]
@deftype[Subprocess]
@deftype[Place]
@deftype[Place-Channel]
@deftype[Semaphore]
@deftype[FSemaphore]
@deftype[Will-Executor]
@deftype[Pseudo-Random-Generator]
@deftype[Environment-Variables]
)]{
These types represent primitive Racket data.

@ex[
#t
#f
"hello"
(current-input-port)
(current-output-port)
(string->path "/")
#rx"a*b*"
#px"a*b*"
'#"bytes"
(current-namespace)
#\b
(thread (lambda () (add1 7)))
]
}

@deftype[Path-String]{
The union of the @racket[Path] and
@racket[String] types.  Note that this does not
match exactly what the predicate @racket[path-string?]
recognizes. For example, strings
that contain the character @racket[#\nul] have the type
@racket[Path-String] but @racket[path-string?] returns
@racket[#f] for those strings. For a complete specification
of which strings @racket[path-string?] accepts, see its
documentation.}


@section{Singleton Types}

Some kinds of data are given singleton types by default.  In
particular, @rtech{booleans}, @rtech{symbols}, and @rtech{keywords} have types which
consist only of the particular boolean, symbol, or keyword.  These types are
subtypes of @racket[Boolean], @racket[Symbol] and @racket[Keyword], respectively.

@ex[
#t
'#:foo
'bar
]

@section[#:tag "built-in-type-constructors"]{Base Type Constructors and Supertypes}


@deftypeconstr[(Pairof s t)]{Returns a @rtech{pair} type containing @racket[s] as the @racket[car]
  and @racket[t] as the @racket[cdr]}

@ex[
(cons 1 2)
(cons 1 "one")
]


@deftypeconstr[(Listof t)]{Returns the type of a homogeneous @rtech{list} of @racket[t]}
@deftypeconstr[(List t ...)]{Returns a list type with one element, in order,
  for each type provided to the @racket[List] type constructor.}
@deftypeconstr/none[(#,(racket List) t ... trest #,(racket ...) bound)]{Returns the type of a list with
one element for each of the @racket[t]s, plus a sequence of elements
corresponding to @racket[trest], where @racket[bound]
  must be an identifier denoting a type variable bound with @racket[...].}
@deftypeconstr[(List* t t1 ... s)]{Is equivalent to @racket[(Pairof t (List* t1 ... s))]. @racket[(List* s)] is equivalent to @racket[s] itself.}

@ex[
(list 'a 'b 'c)
(plambda: (a ...) ([sym : Symbol] boxes : (Boxof a) ... a)
  (ann (cons sym boxes) (List Symbol (Boxof a) ... a)))
(map symbol->string (list 'a 'b 'c))
]

@deftypeconstr[(MListof t)]{Returns the type of a homogeneous @rtech{mutable list} of @racket[t].}
@deftypeconstr[(MPairof t u)]{Returns the type of a @rtech{Mutable pair} of @racket[t] and @racket[u].}

@deftypeconstr[(TreeListof t)]{Returns the type of @rtech{treelist} of @racket[t]}

@deftype[MPairTop]{Is the type of a @rtech{mutable pair} with unknown
  element types and is the supertype of all mutable pair types.
  This type typically appears in programs via the combination of
  occurrence typing and @racket[mpair?].
@ex[(lambda: ([x : Any]) (if (mpair? x) x (error "not an mpair!")))]
}

@deftypeconstr[(Boxof t)]{Returns the type of a @rtech{box} of @racket[t]}

@ex[(box "hello world")]

@deftype[BoxTop]{Is the type of a @rtech{box} with an unknown element
  type and is the supertype of all box types. Only read-only box operations
  (e.g. @racket[unbox]) are allowed on values of this type. This type
  typically appears in programs via the combination of occurrence
  typing and @racket[box?].
@ex[(lambda: ([x : Any]) (if (box? x) x (error "not a box!")))]
}

@deftypeconstr[(Vectorof t)]{Returns the type of a homogeneous @rtech{vector} list of @racket[t]
 (mutable or immutable).}
@deftypeconstr[(Immutable-Vectorof t)]{
 Returns the type of a homogeneous immutable @rtech{vector} of @racket[t].
 @history[#:added "1.9"]}
@deftypeconstr[(Mutable-Vectorof t)]{
 Returns the type of a homogeneous mutable @rtech{vector} of @racket[t].
 @history[#:added "1.9"]}

@deftypeconstr[(Vector t ...)]{Returns the type of a mutable or immutable vector with one
  element, in order, for each type provided to the @racket[Vector] type constructor.

  @ex[(ann (vector 1 'A) (Vector Fixnum 'A))]}

@deftypeconstr[(Immutable-Vector t ...)]{Similar to @racket[(Vector t ...)], but
 for immutable vectors.

 @ex[(vector-immutable 1 2 3)]
 @history[#:added "1.9"]}

@deftypeconstr[(Mutable-Vector t ...)]{Similar to @racket[(Vector t ...)], but
 for mutable vectors.

 @ex[(vector 1 2 3)]
 @history[#:added "1.9"]}

@deftype[FlVector]{An @rtech{flvector}.
  @ex[(flvector 1.0 2.0 3.0)]}
@deftype[ExtFlVector]{An @rtech{extflvector}.
  @ex[(eval:alts (extflvector 1.0t0 2.0t0 3.0t0)
                 (eval:result @racketresultfont{#<extflvector>}
                              "- : ExtFlVector"
                              ""))]}
@deftype[FxVector]{An @rtech{fxvector}.
  @ex[(fxvector 1 2 3)]}

@deftype[VectorTop]{Is the type of a @rtech{vector} with unknown length and
  element types and is the supertype of all vector types.
  Only read-only vector operations (e.g. @racket[vector-ref])
  are allowed on values of this type. This type typically appears in programs
  via the combination of occurrence typing and @racket[vector?].
@ex[(lambda: ([x : Any]) (if (vector? x) x (error "not a vector!")))]
}
@deftype[Mutable-VectorTop]{Is the type of a mutable @rtech{vector}
 with unknown length and element types.}


@deftypeconstr[(HashTable k v)]{Returns the type of a mutable or immutable @rtech{hash table}
   with key type @racket[k] and value type @racket[v].

@ex[(ann (make-hash '((a . 1) (b . 2))) (HashTable Symbol Integer))]
}

@deftypeconstr[(Immutable-HashTable k v)]{
 Returns the type of an immutable @rtech{hash table}
 with key type @racket[k] and value type @racket[v].

 @ex[#hash((a . 1) (b . 2))]
 @history[#:added "1.8"]}

@deftypeconstr[(Mutable-HashTable k v)]{
 Returns the type of a mutable @rtech{hash table}
 that holds keys strongly (see @r-reference-secref{weakbox})
 with key type @racket[k] and value type @racket[v].

 @ex[(make-hash '((a . 1) (b . 2)))]
 @history[#:added "1.8"]
}

@deftypeconstr[(Weak-HashTable k v)]{
 Returns the type of a mutable @rtech{hash table}
 that holds keys weakly with key type @racket[k] and value type @racket[v].

 @ex[(make-weak-hash '((a . 1) (b . 2)))]
 @history[#:added "1.8"]
}


@deftype[HashTableTop]{Is the type of a @rtech{hash table} with unknown key
  and value types and is the supertype of all hash table types. Only read-only
  hash table operations (e.g.
  @racket[hash-ref]) are allowed on values of this type. This type typically
  appears in programs via the combination of occurrence typing and
  @racket[hash?].
@ex[(lambda: ([x : Any]) (if (hash? x) x (error "not a hash table!")))]
}

@deftype[Mutable-HashTableTop]{Is the type of a mutable @rtech{hash table}
  that holds keys strongly with unknown key and value types.}

@deftype[Weak-HashTableTop]{Is the type of a mutable @rtech{hash table}
  that holds keys weakly with unknown key and value types.}

@deftypeconstr[(Setof t)]{Returns the type of a @rtech{hash set} of
@racket[t]. This includes custom hash sets, but not mutable hash set
or sets that are implemented using @racket[gen:set].
@ex[(set 0 1 2 3)]
@ex[(seteq 0 1 2 3)]
}

@deftypeconstr[(Channelof t)]{Returns the type of a @rtech{channel} on which only @racket[t]s can be sent.
@ex[
(ann (make-channel) (Channelof Symbol))
]
}

@deftype[ChannelTop]{Is the type of a @rtech{channel} with unknown
  message type and is the supertype of all channel types. This type typically
  appears in programs via the combination of occurrence typing and
  @racket[channel?].
@ex[(lambda: ([x : Any]) (if (channel? x) x (error "not a channel!")))]
}

@deftypeconstr[(Async-Channelof t)]{Returns the type of an @rtech{asynchronous channel} on which only @racket[t]s can be sent.
@ex[
(require typed/racket/async-channel)
(ann (make-async-channel) (Async-Channelof Symbol))
]
@history[#:added "1.1"]
}

@deftype[Async-ChannelTop]{Is the type of an @rtech{asynchronous channel} with unknown
  message type and is the supertype of all asynchronous channel types. This type typically
  appears in programs via the combination of occurrence typing and
  @racket[async-channel?].
@ex[(require typed/racket/async-channel)
    (lambda: ([x : Any]) (if (async-channel? x) x (error "not an async-channel!")))]
@history[#:added "1.1"]
}

@deftypeconstr*[[(Parameterof t)
                 (Parameterof s t)]]{

Returns the type of a @rtech{parameter} of @racket[t].  If two type arguments
are supplied, the first is the type the parameter accepts, and the second is the
type returned.  @ex[current-input-port current-directory]}

@deftypeconstr[(Promise t)]{Returns the type of @rtech{promise} of @racket[t].
 @ex[(delay 3)]}

@deftypeconstr[(Futureof t)]{Returns the type of @rtech{future} which produce a value of type @racket[t] when touched.}

@deftypeconstr[(Sequenceof t ...)]{Returns the type of @rtech{sequence} that produces
  @racket[(Values _t ...)] on each iteration. E.g., @racket[(Sequenceof)]
  is a sequence which produces no values, @racket[(Sequenceof String)] is a
  sequence of strings, @racket[(Sequenceof Number String)] is a sequence which
  produces two values---a number and a string---on each iteration, etc.}

@deftype[SequenceTop]{Is the type of a @rtech{sequence} with unknown element
  type and is the supertype of all sequences. This type typically
  appears in programs via the combination of ocurrence typing ang
  @racket[sequence?].
@ex[(lambda: ([x : Any]) (if (sequence? x) x (error "not a sequence!")))]
@history[#:added "1.10"]
}

@deftypeconstr[(Custodian-Boxof t)]{Returns the type of @rtech{custodian box} of @racket[t].}

@deftypeconstr[(Thread-Cellof t)]{Returns the type of @rtech{thread cell} of @racket[t].}

@deftype[Thread-CellTop]{Is the type of a @rtech{thread cell} with unknown
  element type and is the supertype of all thread cell types. This type typically
  appears in programs via the combination of occurrence typing and
  @racket[thread-cell?].
@ex[(lambda: ([x : Any]) (if (thread-cell? x) x (error "not a thread cell!")))]
}

@deftypeconstr[(Weak-Boxof t)]{
  Returns the type for a @rtech{weak box} whose value is of type @racket[t].

  @ex[(make-weak-box 5)
      (weak-box-value (make-weak-box 5))]
}

@deftype[Weak-BoxTop]{Is the type of a @rtech{weak box} with an unknown element
  type and is the supertype of all weak box types. This type
  typically appears in programs via the combination of occurrence
  typing and @racket[weak-box?].
@ex[(lambda: ([x : Any]) (if (weak-box? x) x (error "not a box!")))]
}

@deftypeconstr[(Ephemeronof t)]{Returns the type of an @rtech{ephemeron} whose value is of type @racket[t].}

@deftypeconstr[(Evtof t)]{A @rtech{synchronizable event} whose @rtech{synchronization result}
  is of type @racket[t].

  @ex[always-evt
      (system-idle-evt)
      (ann (thread (λ () (displayln "hello world"))) (Evtof Thread))]
}

@section{Syntax Objects}

The following type constructors and types respectively create and represent
@rtech{syntax object}s and their content.

@deftypeconstr[(Syntaxof t)]{Returns the type of syntax object with content of type @racket[t].
Applying @racket[syntax-e] to a value of type @racket[(Syntaxof t)] produces a
value of type @racket[t].}

@deftype[Identifier]{A syntax object containing a @rtech{symbol}.  Equivalent
to @racket[(Syntaxof Symbol)].}

@deftype[Syntax]{A syntax object containing only @rtech{symbol}s,
@rtech{keyword}s, @rtech{string}s, @rtech{byte string}s, @rtech{character}s, @rtech{boolean}s,
@rtech{number}s, @rtech{box}es containing @racket[Syntax], @rtech{vector}s of
@racket[Syntax], or (possibly improper) @rtech{list}s of @racket[Syntax].
Equivalent to @racket[(Syntaxof Syntax-E)].}

@deftype[Syntax-E]{The content of syntax objects of type @racket[Syntax].
Applying @racket[syntax-e] to a value of type @racket[Syntax] produces a value
of type @racket[Syntax-E].}

@deftypeconstr[(Sexpof t)]{Returns the recursive union of @racket[t] with @rtech{symbol}s,
@rtech{keyword}s, @rtech{string}s, @rtech{byte string}s, @rtech{character}s, @rtech{boolean}s,
@rtech{number}s, @rtech{box}es, @rtech{vector}s, and (possibly improper)
@rtech{list}s.}

@deftype[Sexp]{Applying @racket[syntax->datum] to a value of type
@racket[Syntax] produces a value of type @racket[Sexp].  Equivalent to
@racket[(Sexpof Nothing)].}

@deftype[Datum]{Applying @racket[datum->syntax] to a value of type
@racket[Datum] produces a value of type @racket[Syntax].  Equivalent to
@racket[(Sexpof Syntax)].}


@section{Control}

The following type constructors and type respectively create and represent
@rtech{prompt tag}s and keys for @rtech{continuation mark}s for use with
delimited continuation functions and continuation mark functions.

@deftypeconstr[(Prompt-Tagof s t)]{

  Returns the type of a prompt tag to be used in a continuation prompt whose
  body produces the type @racket[_s] and whose handler has the type
  @racket[_t]. The type @racket[_t] must be a function type.

  The domain of @racket[_t] determines the type of the values
  that can be aborted, using @racket[abort-current-continuation],
  to a prompt with this prompt tag.

  @ex[(make-continuation-prompt-tag 'prompt-tag)]
}

@deftype[Prompt-TagTop]{is the type of a @rtech{prompt tag} with unknown
  body and handler types and is the supertype of all prompt tag types. This type
  typically appears in programs via the combination of occurrence typing
  and @racket[continuation-prompt-tag?].
@ex[(lambda: ([x : Any]) (if (continuation-prompt-tag? x) x (error "not a prompt tag!")))]
}

@deftypeconstr[(Continuation-Mark-Keyof t)]{

  Returns the type of a continuation mark key that is used for continuation mark
  operations such as @racket[with-continuation-mark] and
  @racket[continuation-mark-set->list]. The type @racket[_t] represents the type
  of the data that is stored in the continuation mark with this key.

  @ex[(make-continuation-mark-key 'mark-key)]
}

@deftype[Continuation-Mark-KeyTop]{Is the type of a continuation mark
  key with unknown element type and is the supertype of all continuation mark key
  types. This type typically appears in programs
  via the combination of occurrence typing and @racket[continuation-mark-key?].
@ex[(lambda: ([x : Any]) (if (continuation-mark-key? x) x (error "not a mark key!")))]
}


@section{Other Type Constructors}

@deftypeconstr*/subs[#:id -> #:literals (|@| * ... ! and or implies car cdr)
                     [(-> dom ... rng opt-proposition)
                      (-> dom ... rest * rng)
                      (-> dom ... rest ooo bound rng)

                      (dom ... -> rng opt-proposition)
                      (dom ... rest * -> rng)
                      (dom ... rest ooo bound -> rng)]
                     ([ooo #,(racket ...)]
                      [dom type
                           mandatory-kw
                           opt-kw]
                      [rng type
                           (code:line (Some (a ...) type : #:+ proposition))
                           (Values type ...)]
                      [mandatory-kw (code:line keyword type)]
                      [opt-kw [keyword type]]
                      [opt-proposition (code:line)
                                       (code:line : type)
                                       (code:line : pos-proposition
				                    neg-proposition
				      	      object)]
                      [pos-proposition (code:line)
                                       (code:line #:+ proposition ...)]
                      [neg-proposition (code:line)
                                       (code:line #:- proposition ...)]
                      [object (code:line)
                              (code:line #:object index)]
                      [proposition Top
		                   Bot
			           type
                                   (! type)
                                   (type |@| path-elem ... index)
                                   (! type |@| path-elem ... index)
                                   (and proposition ...)
                                   (or proposition ...)
                                   (implies proposition ...)]
                      [path-elem car cdr]
                      [index positive-integer
                             (positive-integer positive-integer)
                             identifier])]{
  The type of functions from the (possibly-empty)
  sequence @racket[dom ....] to the @racket[rng] type.

  @ex[(λ ([x : Number]) x)
      (λ () 'hello)]

  The second form specifies a uniform rest argument of type @racket[rest], and the
  third form specifies a non-uniform rest argument of type
  @racket[rest] with bound @racket[bound]. The bound refers to the type variable
  that is in scope within the rest argument type.

  @ex[(λ ([x : Number] . [y : String *]) (length y))
      ormap]

  In the third form, the @racket[...] introduced by @racket[ooo] is literal,
  and @racket[bound] must be an identifier denoting a type variable.

  The @racket[dom]s can include both mandatory and optional keyword arguments.
  Mandatory keyword arguments are a pair of keyword and type, while optional
  arguments are surrounded by a pair of parentheses.

  @ex[(:print-type file->string)
      (: is-zero? : (-> Number #:equality (-> Number Number Any) [#:zero Number] Any))
      (define (is-zero? n #:equality equality #:zero [zero 0])
        (equality n zero))
      (is-zero? 2 #:equality =)
      (is-zero? 2 #:equality eq? #:zero 2.0)]

  When @racket[opt-proposition] is provided, it specifies the
  @emph{proposition} for the function type (for an introduction to
  propositions in Typed Racket, see
  @tr-guide-secref["propositions-and-predicates"]).  For almost all use
  cases, only the simplest form of propositions, with a single type after a
  @racket[:], are necessary:

  @ex[string?]

  The proposition specifies that when @racket[(string? x)] evaluates to a
  true value for a conditional branch, the variable @racket[x] in that
  branch can be assumed to have type @racket[String]. Likewise, if the
  expression evaluates to @racket[#f] in a branch, the variable
  @emph{does not} have type @racket[String].

  In some cases, asymmetric type information is useful in the
  propositions. For example, the @racket[filter] function's first
  argument is specified with only a positive proposition:

  @ex[filter]

  The use of @racket[#:+] indicates that when the function applied to a variable
  evaluates to a true value, the given type can be assumed for the variable. However,
  the type-checker gains no information in branches in which the result is @racket[#f].

  Conversely, @racket[#:-] specifies that a function provides information for the
  false branch of a conditional.

  The other proposition cases are rarely needed, but the grammar documents them
  for completeness. They correspond to logical operations on the propositions.

  The type of functions can also be specified with an @emph{infix} @racket[->]
  which comes immediately before the @racket[rng] type. The fourth through
  sixth forms match the first three cases, but with the infix style of arrow.

  @ex[(: add2 (Number -> Number))
      (define (add2 n) (+ n 2))]

  @margin-note{Currently, because explicit packing operations for existential types are
  not supported, existential type results are only used to annotate accessors
  for @racket[Struct-Property]}

  @racket[(Some (a ...) type : #:+ proposition)] for @racket[rng] specifies an
  @deftech[#:key "Some"]{existential type result}, where the type variables @racket[a ...] may appear
  in @racket[type] and @racket[opt-proposition]. Unpacking the existential type
  result is done automatically while checking application of the function.

  @history[#:changed "1.12" @elem{Added @tech[#:key "Some"]{existential type results}}]
}

@;; This is a trick to get a reference to ->* in another manual
@(module id-holder racket/base
   (require scribble/manual (for-label racket/contract))
   (provide ->*-element)
   (define ->*-element (racket ->*)))
@(require 'id-holder)

@deftypeconstr[#:literals (* ...)
         (->* (mandatory-dom ...) optional-doms rest rng)
         #:grammar
         ([mandatory-dom type
                         (code:line keyword type)]
          [optional-doms (code:line)
                         (optional-dom ...)]
          [optional-dom type
                        (code:line keyword type)]
          [rest (code:line)
                (code:line #:rest type)
                (code:line #:rest-star (type ...))])]{
  Constructs the type of functions with optional or rest arguments. The first
  list of @racket[mandatory-dom]s correspond to mandatory argument types. The list
  @racket[optional-doms], if provided, specifies the optional argument types.

  @ex[(: append-bar (->* (String) (Positive-Integer) String))
      (define (append-bar str [how-many 1])
        (apply string-append str (make-list how-many "bar")))]

  If provided, the @racket[#:rest type] specifies the type of
  elements in the rest argument list.

  @ex[(: +all (->* (Integer) #:rest Integer (Listof Integer)))
      (define (+all inc . rst)
        (map (λ ([x : Integer]) (+ x inc)) rst))
      (+all 20 1 2 3)]

  A @racket[#:rest-star (type ...)] specifies the rest list is a sequence
  of types which occurs 0 or more times (i.e. the Kleene closure of the
  sequence).

 @ex[(: print-name+ages (->* () #:rest-star (String Natural) Void))
     (define (print-name+ages . names+ages)
       (let loop ([names+ages : (Rec x (U Null (List* String Natural x))) names+ages])
         (when (pair? names+ages)
           (printf "~a is ~a years old!\n"
                   (first names+ages)
                   (second names+ages))
           (loop (cddr names+ages))))
       (printf "done printing ~a ages" (/ (length names+ages) 2)))
     (print-name+ages)
     (print-name+ages "Charlotte" 8 "Harrison" 5 "Sydney" 3)]

  Both the mandatory and optional argument lists may contain keywords paired
  with types.

  @ex[(: kw-f (->* (#:x Integer) (#:y Integer) Integer))
      (define (kw-f #:x x #:y [y 0]) (+ x y))]

  The syntax for this type constructor matches the syntax of the @->*-element
  contract combinator, but with types instead of contracts.
  }

@deftogether[(
@deftype[Top]
@deftype[Bot])]{ These are propositions that can be used with @racket[->].
  @racket[Top] is the propositions with no information.
  @racket[Bot] is the propositions which means the result cannot happen.
}


@deftype[Procedure]{is the supertype of all function types. The @racket[Procedure]
  type corresponds to values that satisfy the @racket[procedure?] predicate.
  Because this type encodes @emph{only} the fact that the value is a procedure, and
  @emph{not} its argument types or even arity, the type-checker cannot allow values
  of this type to be applied.

  For the types of functions with known arity and argument types, see the @racket[->]
  type constructor.

  @ex[
    (: my-list Procedure)
    (define my-list list)
    (eval:error (my-list "zwiebelkuchen" "socca"))
  ]
}


@deftypeconstr[(U t ...)]{is the union of the types @racket[t ...].
 @ex[(λ ([x : Real]) (if (> 0 x) "yes" 'no))]}

@deftypeconstr[(∩ t ...)]{is the intersection of the types @racket[t ...].
 @ex[((λ #:forall (A) ([x : (∩ Symbol A)]) x) 'foo)]}

@deftypeconstr[(case-> fun-ty ...)]{is a function that behaves like all of
  the @racket[fun-ty]s, considered in order from first to last.
 The @racket[fun-ty]s must all be non-dependent function types (i.e. no
 preconditions or dependencies between arguments are currently allowed).
  @ex[(: add-map : (case->
                     [(Listof Integer) -> (Listof Integer)]
                     [(Listof Integer) (Listof Integer) -> (Listof Integer)]))]
  For the definition of @racket[add-map] look into @racket[case-lambda:].}

@deftypeform/none[(t t1 t2 ...)]{is the instantiation of the parametric type
  @racket[t] at types @racket[t1 t2 ...]}

@deftypeform*[[(All (a ...) t)
               (All (a ... a ooo) t)]]{
  is a parameterization of type @racket[t], with
  type variables @racket[a ...].  If @racket[t] is a function type
      constructed with infix @racket[->], the outer pair of parentheses
      around the function type may be omitted.
      @ex[(: list-length : (All (A) (Listof A) -> Natural))
          (define (list-length lst)
            (if (null? lst)
                0
                (add1 (list-length (cdr lst)))))
          (list-length (list 1 2 3))]}

@deftypeform[(Some (a ...) t)]{
  See @tech[#:key "Some"]{existential type results}.
  @history[#:added "1.10"]
}

@deftypeconstr[(Values t ...)]{

Returns the type of a sequence of multiple values, with
types @racket[t ...].  This can only appear as the return type of a
function.
@ex[(values 1 2 3)]}
Note that a type variable cannot be instantiated with a @racket[(Values ....)]
type. For example, the type @racket[(All (A) (-> A))] describes a thunk that
returns exactly one value.
@deftypeform/none[v]{where @racket[v] is a number, boolean or string, is the singleton type containing only that value}
@deftypeform/none[(quote val)]{where @racket[val] is a Racket value, is the singleton type containing only that value}
@deftypeform/none[i]{where @racket[i] is an identifier can be a reference to a type
name or a type variable}

@deftypeform[(Rec n t)]{is a recursive type where @racket[n] is bound to the
recursive type in the body @racket[t]
@ex[(define-type IntList (Rec List (Pair Integer (U List Null))))

    (define-type (List A) (Rec List (Pair A (U List Null))))]}

@deftypeform[(Struct st)]{is a type which is a supertype of all instances of the
potentially-polymorphic structure type @racket[_st].  Note that structure
accessors for @racket[_st] will @emph{not} accept @racket[(Struct st)] as an
argument.}

@deftypeform[(Struct-Type st)]{is a type for the structure type descriptor value
for the structure type @racket[st]. Values of this type are used with
reflective operations such as @racket[struct-type-info].

@ex[struct:arity-at-least
    (struct-type-info struct:arity-at-least)]
}

@deftype[Struct-TypeTop]{is the supertype of all types for structure type
descriptor values. The corresponding structure type is unknown for values of
this top type.

@ex[(struct-info (arity-at-least 0))]
}

@deftypeconstr[(Prefab key type ...)]{Describes a @rtech{prefab}
 structure with the given (implicitly quoted) @emph{prefab
  key} @racket[key] and specified field types.

 Prefabs are more-or-less tagged polymorphic tuples which
 can be directly serialized and whose fields can be accessed
 by anyone. Subtyping is covariant for immutable fields and
 invariant for mutable fields.

 When a prefab struct is defined with @racket[struct] the
 struct name is bound at the type-level to the
 @racket[Prefab] type with the corresponding key and field
 types and the constructor expects types corresponding to
 those declared for each field. The defined predicate,
 however, only tests whether a value is a prefab structure
 with the same key and number of fields, but does not inspect
 the fields' values.

  @ex[(struct person ([name : String]) #:prefab)
      person
      person?
      person-name
      (person "Jim")
      (ann '#s(person "Dwight") person)
      (ann '#s(person "Pam") (Prefab person String))
      (ann '#s(person "Michael") (Prefab person Any))
      (eval:error (person 'Toby))
      (eval:error (ann #s(person Toby) (Prefab person String)))
      (ann '#s(person Toby) (Prefab person Symbol))
      (person? '#s(person "Michael"))
      (person? '#s(person Toby))
      (struct employee person ([schrute-bucks : Natural]) #:prefab)
      (employee "Oscar" 10000)
      (ann '#s((employee person 1) "Oscar" 10000) employee)
      (ann '#s((employee person 1) "Oscar" 10000)
           (Prefab (employee person 1) String Natural))
      (person? '#s((employee person 1) "Oscar" 10000))
      (employee? '#s((employee person 1) "Oscar" 10000))
      (eval:error (employee 'Toby -1))
      (ann '#s((employee person 1) Toby -1)
           (Prefab (employee person 1) Symbol Integer))
      (person? '#s((employee person 1) Toby -1))
      (employee? '#s((employee person 1) Toby -1))]
}

@deftypeform[(PrefabTop key field-count)]{Describes all
prefab types with the (implicitly quoted) prefab-key
 @racket[key] and @racket[field-count] many fields.

 For immutable prefabs this is equivalent to
 @racket[(Prefab key Any ...)] with @racket[field-count] many
 occurrences of @racket[Any]. For mutable prefabs, this
 describes a prefab that can be read from but not written to
 (since we do not know at what type other code may have the
 fields typed at).

@ex[(struct point ([x : Number] [y : Number])
      #:prefab
      #:mutable)
    point
    point-x
    point-y
    point?
    (define (maybe-read-x p)
      (if (point? p)
          (ann (point-x p) Any)
          'not-a-point))
    (eval:error (define (read-some-x-num p)
      (if (point? p)
          (ann (point-x p) Number)
          -1)))]

@history[#:added "1.7"]}

@deftypeconstr[(Struct-Property ty)]{
  Describes a property that can be attached to a structure type.
  The property value must match the type @racket[ty].

  @ex[(:print-type prop:input-port)]

  @history[#:added "1.10"]}

@deftype[Self]{
  This type can only appear in a @racket[Struct-Property] type.
  A struct property value is attached to an instance of a structure type;
  the @racket[Self] type refers to this instance.

  @ex[(:print-type prop:custom-write)]

  @history[#:added "1.10"]}

@deftype[Imp]{
  This type can only appear in a @racket[Struct-Property] type.
  An @racket[Imp] value may be a @rtech{structure subtype} of the @racket[Self]
  value, or another instance created by the same struct constructor.

  @ex[(:print-type prop:equal+hash)]

  @history[#:added "1.10"]}

@deftypeform[(Has-Struct-Property prop)]{
  This type describes an instance of a
  structure type associcated with a @racket[Struct-Property] named @racket[prop].
}

@defalias[∪ U "type constructor"]
@defalias[Union U "type constructor"]
@defalias[Intersection ∩ "type constructor"]
@defalias[→ -> "type constructor"]
@defalias[→* ->* "type constructor"]
@defalias[case→ case-> "type constructor"]
@defalias[∀ All "type"]

@section{Other Types}

@deftypeconstr[(Option t)]{Either @racket[t] or @racket[#f]}
@deftypeconstr[(Opaque t)]{A type constructed using the @racket[#:opaque]
clause of @racket[require/typed].}

@(close-eval the-eval)
