# ASPforABA
**Answer set programming powered reasoner for Assumption-based Argumentation**

Author of the code: [Tuomo Lehtonen](https://www.tuomolehtonen.com), Aalto University. Please [contact me](mailto:tuomo.lehtonen@aalto.fi) for any bug reports, questions or feature inquiries.

**Table of contents**

[TOC]

# Installation
```
git clone git@bitbucket.org:coreo-group/aspforaba.git
cd aspforaba
pip install .
```

# Usage

Note that at the moment, ASPforABA supports flat ABA frameworks with explicitly listed rules (the so-called logic programming fragment of ABA).

## As a library
Import the ABASolver class and create a solver instance:
```python
$ python3
>>> from aspforaba import ABASolver
>>> s = ABASolver()
```
Then add assumptions, contraries and rules with the functions `add_assumption(assumption: str)`, `add_contrary(assumption: str, contrary: str)`, and `add_rule(head: str, body: list[str])`.
```python
>>> s.add_assumption("a")
>>> s.add_assumption("b")
>>> s.add_assumption("c")
>>> s.add_rule("-a",["b"])
>>> s.add_rule("y",[])
>>> s.add_contrary("a","-a")
>>> s.add_contrary("c","y")
```
Alternatively, you can initialize the solver with a list of assumptions, contraries and rules: 
```python
s = ABASolver(assumptions=["a", "b", "c"], contraries=[("a", "-a"), ("c", "y")], rules=[("-a", ["b"]), ("y", [])])
```
or read an ABA framework from a file (see below for input formats): 
```python
s = ABASolver(from_file="example_file")
```

Finally, solve the reasoning problem of your choice with the functions `solve_credulous(semantics: str, query: str)`, `solve_skeptical(semantics: str, query: str)`, `find_extension(semantics: str)`, and `enumerate_extensions(semantics: str, k=0: int)`.
```python
>>> s.decide_credulous('CO','a')
False
>>> s.decide_skeptical('PR','y')
True
>>> extension = s.find_extension('ID')
>>> extension
AssumptionSet(assumptions={'b'}, consequences={'-a', 'y'})
>>> extension.assumptions, extension.consequences
({'b'}, {'-a', 'y'})
>>> s.enumerate_extensions('AD')
[AssumptionSet(assumptions=set(), consequences={'y'}), AssumptionSet(assumptions={'b'}, consequences={'-a', 'y'})]
>>> s.enumerate_extensions('AD', k=1)
[AssumptionSet(assumptions=set(), consequences={'y'})]
```

The parameter `k` for `enumerate_extensions` dictates how many extensions are enumerated: if `k=0`, all extensions are enumerated and if `k>0`, `k` extensions are enumerated.
The supported semantics are AD, CO, ST, PR, GR, and ID (i.e. admissible, complete, stable, preferred, grounded, and ideal semantics, respectively).

You can also check the elements contained in the ABA framework:
```python
>>> s.assumptions         
{'b', 'a', 'c'}           
>>> s.rules               
[('-a', ['b']), ('y', [])]             
>>> s.contraries                                    
{'a': {'-a'}, 'c': {'y'}}  
```

## Command line
`aspforaba -f INPUT_FILE -p PROBLEM [-a QUERY] [-fo {iccma,asp}]`

Supported input formats are the ICCMA 2023 format (see [specification of ICCMA 2023](https://iccma2023.github.io/rules.html)) and the ASP-based format used in the reference papers (see below for examples). The format can be specified with the flag `-fo`; if not provided, ASPforABA attempts to infer the format based on the first line of the input file. 

The supported problems are DC-S, DS-S, SE-S and EE-S for semantics S (one of AD, CO, ST, PR, GR, or ID). For DC-S and DS-S, a query must be provided via the flag `-a`. An additional integer parameter can be supplied to EE-S to sanction how many extensions should be enumerated: 0 for all extensions, otherwise up to the provided integer.

### ICCMA'23 input format
The same framework as before:
```
p aba 5
a 1
a 2
a 3
r 4 2
r 5
c 1 4
c 3 5
```

### ASP input format
The same framework as before:
```
assumption(a).
assumption(b).
assumption(c).
head(1,-a).
body(1,a).
head(2,y).
contrary(a,-a).
contrary(c,y).
```

# References
(2021a) Tuomo Lehtonen, Johannes P. Wallner, Matti J&auml;rvisalo. [Declarative Algorithms and Complexity Results for Assumption-Based Argumentation](https://doi.org/10.1613/jair.1.12479). Journal of Artificial Intelligence Research 71: 265-318 (2021). [DBLP](https://dblp.org/rec/journals/jair/LehtonenWJ21.html)

(2021b) Tuomo Lehtonen, Johannes P. Wallner, Matti J&auml;rvisalo. [Harnessing Incremental Answer Set Solving for Reasoning in Assumption-Based Argumentation](https://doi.org/10.1017/S1471068421000296). Theory and Practice of Logic Programming 21(6): 717-734 (2021). [DBLP](https://dblp.org/rec/journals/tplp/LehtonenWJ21.html)

Most algorithms included in this version of ASPforABA were introduced in 2021a.
In 2021b we introduced the algorithms for preferred semantics.

# Other versions of ASPforABA
The algorithms in their original form, as used in the experiments of the reference papers, can be found in [the branch "papers"](https://bitbucket.org/coreo-group/aspforaba/src/72516a3d9c6a19db5c2d6b3800d41cd70c6f51b3/?at=release%2Fpapers).
The ICCMA 2023 submission of ASPforABA can be accessed via the [ICCMA'23 tag](https://bitbucket.org/coreo-group/aspforaba/commits/tag/ICCMA23).
