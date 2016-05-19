/*  Part of SWI-Prolog

    Author:        Jan Wielemaker
    Copyright (c)  2016, VU University Amsterdam
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions
    are met:

    1. Redistributions of source code must retain the above copyright
       notice, this list of conditions and the following disclaimer.

    2. Redistributions in binary form must reproduce the above copyright
       notice, this list of conditions and the following disclaimer in
       the documentation and/or other materials provided with the
       distribution.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
    COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
    POSSIBILITY OF SUCH DAMAGE.
*/

:- module(table_wrapper,
	  [ (table)/1,			% +Predicates

	    op(1150, fx, table)
	  ]).
:- use_module(library(error)).

:- multifile
	system:term_expansion/2,
	prolog:rename_predicate/2,
	tabled/2.
:- dynamic
	system:term_expansion/2.

%%	table(+PredicateIndicators)
%
%	Prepare the given PredicateIndicators for tabling.  Can only
%	be used as a directive.

table(PIList) :-
	throw(error(context_error(nodirective, table(PIList)), _)).


wrappers(Var) -->
	{ var(Var), !,
	  instantiation_error(Var)
	}.
wrappers((A,B)) --> !,
	wrappers(A),
	wrappers(B).
wrappers(Name//Arity) -->
	{ atom(Name), integer(Arity), Arity >= 0, !,
	  Arity1 is Arity+2
	},
	wrappers(Name/Arity1).
wrappers(Name/Arity) -->
	{ atom(Name), integer(Arity), Arity >= 0, !,
	  functor(Head, Name, Arity),
	  atom_concat(Name, ' tabled', WrapName),
	  Head =.. [Name|Args],
	  WrappedHead =.. [WrapName|Args],
	  prolog_load_context(module, Module)
	},
	[ table_wrapper:tabled(Head, Module),
	  (   Head :-
		 start_tabling(Module:Head, WrappedHead)
	  )
	].

%%	prolog:rename_predicate(:Head0, :Head) is semidet.
%
%	Hook into term_expansion for  post   processing  renaming of the
%	generated predicate.

prolog:rename_predicate(M:Head0, M:Head) :-
	writeln(M:Head0),
	tabled(Head0, M), !,
	rename_term(Head0, Head).

rename_term(Compound0, Compound) :-
	compound(Compound0), !,
	compound_name_arguments(Compound0, Name, Args),
	atom_concat(Name, ' tabled', WrapName),
	compound_name_arguments(Compound, WrapName, Args).
rename_term(Name, WrapName) :-
	atom_concat(Name, ' tabled', WrapName).


system:term_expansion((:- table(Preds)),
		    [ (:- multifile table_wrapper:tabled/2)
		    | Clauses
		    ]) :-
	phrase(wrappers(Preds), Clauses).
