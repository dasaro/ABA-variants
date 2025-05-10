# ABA-variants

This repository hosts some variants of ABA that are being developed by the logic group at UniSalento and collaborators. At the moment, only the *Weighted Assumption Based Argumentation* (*WABA*) framework is being hosted, but other variants are soon to be added.

## Weighted Assumption Based Argumentation
In order to run WABA, you must have `clingo` installed (tested with version 5.8.0 with Python 3.10.17, without Lua, but older versions may be supported).

In order to run WABA, you must load clingo with the `core` WABA module in the main directory as well as one of the supported semantics under the `Semantics` folder and a WABA framework. You can find some example WABA frameworks in the `Examples` directory. For instance, you may run

```clingo -n 0 core.lp filter.lp Semantics/stable.lp Examples/medical.lp```

where `filter.lp` makes clingo clean up the output via `#show` directives.