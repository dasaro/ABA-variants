% Test if #sup is allowed as weak constraint weight

{ p }. 
{ q }.

% Try using #sup as weight
:~ p. [#sup@1]
:~ q. [100@1]

#show p/0.
#show q/0.
