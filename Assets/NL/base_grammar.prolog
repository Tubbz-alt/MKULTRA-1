sentence(S, Mood, Polarity, Tense, Aspect) -->
   { X = $input_from_player, X },
   ['('],
   { bind(speaker, player), bind(addressee, $me) },
   s(S, Mood, Polarity, Tense, Aspect),
   opt_stop(Mood),
   [')'].

sentence(S, Mood, Polarity, Tense, Aspect) -->
   [ Name, ',' ],     
   { X = $input_from_player, X },
   { bind_indexicals_for_addressing_character_named(Name) },
   s(S, Mood, Polarity, Tense, Aspect),
   opt_stop(Mood).

sentence(S, Mood, Polarity, Tense, Aspect) -->
   { bind_discourse_variables(S, Core) },
   s(Core, Mood, Polarity, Tense, Aspect),
   opt_stop(Mood).

bind_discourse_variables(Var, Var) :-
   var(Var),
   !.
bind_discourse_variables( (Core, Other), Core) :-
   !,
   bind_discourse_variables(Other).
bind_discourse_variables(S, S).

bind_discourse_variables( (X, Y)) :-
   !,
   bind_discourse_variables(X),
   bind_discourse_variables(Y).
bind_discourse_variables(is_a(Var, Kind)) :-
   !,
   bind(discourse_variables, [is_a(Var, Kind) | $discourse_variables]).
bind_discourse_variables(_).

%% discourse_variable_type(Var, Kind)
%  Var is bound in $discourse_variables using is_a(Var,Kind).
discourse_variable_type(Var, Kind) :-
   member(is_a(Var, Kind), $discourse_variables).

%% bound_discourse_variable(Var)
%  Var is an uninstantiated variable that is bound to a type in $discourse_variables.
bound_discourse_variable(Var) :-
   var(Var),
   discourse_variable_type(Var, _).

opt_stop(interrogative) --> [ '?' ].
opt_stop(_Mood) --> [ ].
opt_stop(Mood) --> [ '.' ], { Mood \= interrogative }.
opt_stop(Mood) --> [ '!' ], { Mood \= interrogative }.

%% s(?S, ?Mood, ?Polarity, ?Tense, ?Aspect)
%  Sentences

:- randomizable s/7.

%%%
%%% Indicative mood
%%%
s(S, indicative, Polarity, Tense, Aspect) -->
   { lf_subject(S, NP) },
   np((NP^S1)^S, subject, Agreement, nogap, nogap),
   aux_vp(NP^S1, Polarity, Agreement, Tense, Aspect).

% NP is [not] Adj
s(S, indicative, Polarity, Tense, simple) -->
   { lf_subject(S, Noun) },
   np((Noun^S)^S, subject, Agreement, nogap, nogap),
   aux_be(Tense, Agreement),
   opt_not(Polarity),
   ap(Noun^S).

% NP is [not] CLASS
s(be(Noun, Class), indicative, Polarity, Tense, simple) -->
   np((Noun^_)^_, subject, Agreement, nogap, nogap),
   aux_be(Tense, Agreement),
   opt_not(Polarity),
   [a, Class],
   { atom(Class) }.

% NP is [not] NP
s(be(S, O), indicative, Polarity, Tense, simple) -->
   np((S^_)^_, subject, Agreement, nogap, nogap),
   aux_be(Tense, Agreement),
   opt_not(Polarity),
   np((O^_)^_, object, _, nogap, nogap).

% NP is [not] in NP
s(location(S, Container), indicative, Polarity, Tense, simple) -->
   np((S^_)^_, subject, Agreement, nogap, nogap),
   aux_be(Tense, Agreement),
   opt_not(Polarity),
   [in],
   np((Container^_)^_, object, _, nogap, nogap),
   { is_a(Container, closed_container) }.

% NP is [not] on NP
s(location(S, Container), indicative, Polarity, Tense, simple) -->
   np((S^_)^_, subject, Agreement, nogap, nogap),
   aux_be(Tense, Agreement),
   opt_not(Polarity),
   [on],
   np((Container^_)^_, object, _, nogap, nogap),
   { is_a(Container, work_surface) }.

% Character has  NP
s(location(Object, Character), indicative, Polarity, Tense, simple) -->
   np((Character^_)^_, subject, Agreement, nogap, nogap),
   { character(Character) },
   aux_have(Tense, Agreement),
   opt_not(Polarity),
   np((Object^_)^_, object, _, nogap, nogap).

%%%
%%% Imperative mood
%%%
s(S, imperative, Polarity, present, simple) -->
   { lf_subject(S, $addressee) },
   aux_vp($addressee^S, Polarity, second:singular, present, simple).
s(S, imperative, Polarity, present, simple) -->
   [let, us],
   { lf_subject(S, $dialog_group) },
   aux_vp($dialog_group^S, Polarity, first:singular, present, simple).

%%%
%%% Interrogative mood
%%%

% Yes/no question generated by subject-aux inversion
s(S, interrogative, Polarity, Tense, Aspect) -->
   { var(S) ; S \= (_:_) },  % don't try if we already know it's a wh-question.
   inverted_sentence(S, Polarity, Tense, Aspect).

inverted_sentence(S, Polarity, Tense, Aspect) -->
   { lf_subject(S, NP) },
   aux(np((NP^S1)^S, subject, Agreement),
       Polarity, Agreement, Tense, Aspect, Form, Modality),
   vp(Form, Modality, NP^S1, Tense, Agreement, nogap).

inverted_sentence(S, Polarity, Tense, Aspect) -->
   { lf_subject(S, Subject) },
   aux(np((Subject^S1)^S, subject, Agreement),
       Polarity, Agreement, Tense, Aspect, Form, Predication^Modal),
   copula(Form, Tense, Agreement),
   copular_relation(Subject^Object^Predication), 
   np((Object^Modal)^S1, object, _, nogap, nogap).

inverted_sentence(S, Polarity, Tense, simple) -->
   { lf_subject(S, Subject) },
   copula(simple, Tense, Agreement),
   opt_not(Polarity),
   np((Subject^S1)^S, subject, Agreement, nogap, nogap),
   copular_relation(Subject^Object^Predication), 
   np((Object^Predication)^S1, object, _, nogap, nogap).

% Wh-questions about the subject.
s(Subject:(S, is_a(Subject, Kind)), interrogative, Polarity, Tense, Aspect) -->
   { lf_subject(S, Subject) },
   whpron(Kind),
   aux_vp(Subject^S, Polarity, _Agreement, Tense, Aspect).
% Wh-questions about the object.
s(Object:(S, is_a(Object, Kind)), interrogative, Polarity, Tense, Aspect) -->
   { lf_subject(S, NP) },
   whpron(Kind),
   aux(np((NP^S1)^S, subject, Agreement),
       Polarity, Agreement, Tense, Aspect, Form, Modality),
   vp(Form, Modality, NP^S1, Tense, Agreement, np(Object)).
s(Object:(S, is_a(Object, Kind)), interrogative, Polarity, Tense, simple) -->
   { lf_subject(S, Subject) },
   whpron(Kind),
   copula(simple, Tense, Agreement),
   np((Subject^Predication)^S, subject, Agreement, nogap, nogap),
   opt_not(Polarity),
   copular_relation(Subject^Object^Predication).

% Who is/what is Subject
s(Object:(be(Subject, Object), is_a(Subject, Kind)), interrogative, affirmative, present, simple) -->
   whpron(Kind),
   aux_be(present, Agreement),
   np((Subject^S)^S, subject, Agreement, nogap, nogap).

% How is Subject?
s(Manner:manner(be(Subject), Manner), interrogative, affirmative, present, simple) -->
   [ how ],
   aux_be(present, Agreement),
   np((Subject^be(Subject))^be(Subject), subject, Agreement, nogap, nogap).

% How does Subject Predicate?
s(Method:method(S, Method), interrogative, affirmative, Tense, simple) -->
   [ how ],
   { lf_subject(S, NP) },
   aux_do(Tense, Agreement),
   np((NP^S1)^S, subject, Agreement, nogap, nogap),
   vp(base, M^M, NP^S1, present, Agreement, nogap).

% Is he Adjective?
s(S, interrogative, Polarity, present, simple) -->
   aux_be(present, Agreement),
   opt_not(Polarity),
   np((Noun^_)^_, subject, Agreement, nogap, nogap),
   ap(Noun^S).

% why did he X?
s(X:explanation(S, X), interrogative, Polarity, Tense, Aspect) -->
   [why],
   inverted_sentence(S, Polarity, Tense, Aspect).

% where is NP
s(Container:location(S, Container), interrogative, Polarity, Tense, simple) -->
   [where],
   aux_be(Tense, Agreement),
   opt_not(Polarity),
   np((S^S)^S, subject, Agreement, nogap, nogap).

% Who has  NP
s(Character:location(Object, Character), interrogative, Polarity, Tense, simple) -->
   [who],
   aux_have(Tense, third:singular),
   opt_not(Polarity),
   np((Object^S)^S, object, _, nogap, nogap).

% what is on the X
s(S:location(S, Container), interrogative, Polarity, Tense, simple) -->
   [what],
   aux_be(Tense, Agreement),
   opt_not(Polarity),
   [on],
   np((Container^S)^S, subject, Agreement, nogap, nogap),
   { is_a(Container, work_surface) }.

% Who/what is in the X
s(S:(location(S, Container), is_a(S, Kind)), interrogative, Polarity, Tense, simple) -->
   whpron(Kind),
   aux_be(Tense, Agreement),
   opt_not(Polarity),
   [in],
   np((Container^S)^S, subject, Agreement, nogap, nogap),
   { is_a(Container, closed_container), \+ character(Container) }.

% what does Character have?
s(S:location(S, Character), interrogative, Polarity, Tense, simple) -->
   [what],
   aux_do(Tense, Agreement),
   opt_not(Polarity),
   np((Character^S)^S, subject, Agreement, nogap, nogap),
   { character(Character) },
   aux_have(Tense, Agreement).



%%%
%%% Adjectival phrases
%%% Seems silly to make a whole new file for one clause...
%%%

ap(Meaning) -->
   [ Adjective ],
   { adjective(Adjective, Meaning) }.