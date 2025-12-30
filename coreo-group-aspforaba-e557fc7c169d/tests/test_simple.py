import pytest

from pathlib import Path
from aspforaba import ABASolver
from aspforaba.abaf import AssumptionSet

TEST_DATA_DIR = Path(__file__).resolve().parent / 'data'

SEMANTICS = ["CO", "AD", "PR", "GR", "ST", "ID"]

def simple_abaf():
    s = ABASolver()

    s.add_assumption("a")
    s.add_assumption("b")
    s.add_assumption("c")
    s.add_rule("-a",["b"])
    s.add_rule("y",[])
    s.add_contrary("a","-a")
    s.add_contrary("c","y")

    return s

def test_add_elements():
    s = simple_abaf()
    assert s.assumptions == {"a", "b", "c"}
    assert s.contraries["a"] == {"-a"}
    assert ("-a", ["b"]) in s.rules

def test_credulous_simple():
    s = simple_abaf()

    assert not s.decide_credulous("CO","a")
    assert not s.decide_credulous("PR","a")
    assert s.decide_credulous("CO","b")
    assert s.decide_credulous("PR","b")
    assert s.decide_credulous("CO","-a")

def test_skeptical_simple():
    s = simple_abaf()

    assert not s.decide_skeptical("CO","a")
    assert not s.decide_skeptical("PR","a")
    assert s.decide_skeptical("PR","b")
    assert s.decide_skeptical("PR","y")
    assert s.decide_skeptical("PR","-a")

def test_cyclical():
    s = ABASolver()

    s.add_rule("x", ["y"])
    s.add_rule("y", ["x"])

    for sem in SEMANTICS:
        assert s.find_extension(sem) == AssumptionSet(set(), set())
        assert not s.decide_credulous(sem, "x")
        assert not s.decide_credulous(sem, "y")
        assert not s.decide_skeptical(sem, "x")
        assert not s.decide_skeptical(sem, "y")

def test_contrary_to_nonexistent_assumption():
    s = ABASolver()

    try:
        s.add_contrary("x", "-x")
        assert False
    except ValueError:
        assert True

def test_simple2():
    s = ABASolver()
    s.add_assumption("x")
    s.add_contrary("x", "-x")

    assert s.assumptions == {"x"}
    assert s.atoms == {"x", "-x"}
    assert not s.rules

    for sem in SEMANTICS:
        assert s.decide_credulous(sem, "x")

        if sem == "AD":
            assert not s.decide_skeptical(sem, "x")
        else:
            assert s.decide_skeptical(sem, "x")

        assert not s.decide_credulous(sem, "-x")
        assert not s.decide_skeptical(sem, "-x")

def test_query_underivable_atom():
    s = ABASolver()

    s.add_rule("x", ["y"])

    assert not s.decide_credulous("AD", "x")
    assert not s.decide_credulous("AD", "y")

def test_query_nonexistent_atom():
    s = ABASolver()

    try:
        s.decide_credulous("AD", "z")
        assert False
    except ValueError:
        assert True

    try:
        s.decide_skeptical("AD", "z")
        assert False
    except ValueError:
        assert True

def test_journal_paper_example():
    s = ABASolver()

    s.add_assumption("a")
    s.add_assumption("b")
    s.add_assumption("c")
    s.add_assumption("d")

    s.add_contrary("b", "x")
    s.add_contrary("c", "y")
    s.add_contrary("d", "z")

    s.add_rule("w", ["a"])
    s.add_rule("y", ["b", "w"])
    s.add_rule("x", ["c"])
    s.add_rule("z", ["a","b"])

    assert len(s.enumerate_extensions("AD")) == 7
    assert len(s.enumerate_extensions("CO")) == 3
    assert len(s.enumerate_extensions("GR")) == 1
    assert len(s.enumerate_extensions("PR")) == 2
    assert len(s.enumerate_extensions("ST")) == 2
    assert len(s.enumerate_extensions("ID")) == 1

    for ext in s.enumerate_extensions("CO"):
        assert ext.assumptions == {"a"} or ext.assumptions == {"a", "b"} or ext.assumptions == {"a", "c", "d"}

    for ext in s.enumerate_extensions("ST"):
        assert ext.assumptions == {"a", "b"} or ext.assumptions == {"a", "c", "d"}
        assert ext.consequences == {"w", "y", "z"} or ext.consequences == {"w", "x"}

    for ext in s.enumerate_extensions("PR"):
        assert ext.assumptions == {"a", "b"} or ext.assumptions == {"a", "c", "d"}

    assert s.find_extension("GR").assumptions == {"a"}
    assert s.find_extension("GR").consequences == {"w"}

    assert s.find_extension("ID").assumptions == {"a"}
    assert s.find_extension("ID").consequences == {"w"}

    for atom in s.atoms:
        assert s.decide_credulous("AD", atom)
        assert not s.decide_skeptical("AD", atom)

        if atom == "a" or atom == "w":
            for sem in SEMANTICS:
                if sem == "AD": continue
                assert s.decide_credulous(sem, atom)
                assert s.decide_skeptical(sem, atom)
        else:
            assert not s.decide_credulous("GR", atom)
            assert not s.decide_skeptical("GR", atom)
            assert not s.decide_credulous("ID", atom)
            assert not s.decide_skeptical("ID", atom)

            for sem in ["CO", "PR", "ST"]:
                assert s.decide_credulous(sem, atom)
                assert not s.decide_skeptical(sem, atom)

def test_asp_parsing():
    s = ABASolver(from_file = TEST_DATA_DIR/"ex1.asp")

    assert s.assumptions == {"a", "b"}
    assert s.contraries["a"] == {"p"}
    assert s.contraries["b"] == {"x"}

    assert ("p", ["q"]) in s.rules
    assert ("p", ["b"]) in s.rules
    assert ("x", []) in s.rules
    assert len(s.rules) == 3

def test_iccma_parsing():
    s = ABASolver(from_file = TEST_DATA_DIR/"ex2.iccma")

    assert s.assumptions == {"1", "2", "3", "4", "5"}
    assert s.contraries["1"] == {"2", "5"}
    assert s.contraries["2"] == {"1", "4"}
    assert s.contraries["3"] == {"4"}
    assert s.contraries["4"] == {"3", "2"}
    assert s.contraries["5"] == {"1"}
    assert s.rules == [("6", ["2", "3", "5"]), ("6", ["4"])]

def test_asp_parsing_index_fail():
    try:
        s = ABASolver(from_file = TEST_DATA_DIR/"ex2.asp")
        assert False
    except Exception:
        assert True

def test_ideal_and_pref():
    # From Dung, Mancarella, Toni 2007 (AIJ)

    s = ABASolver()

    s.add_assumption("a")
    s.add_assumption("b")
    s.add_assumption("c")
    s.add_assumption("d")

    s.add_rule("x", ["a"])
    s.add_rule("y", ["c"])
    s.add_rule("z", ["d"])

    s.add_contrary("a", "x")
    s.add_contrary("b", "x")
    s.add_contrary("a", "b")
    s.add_contrary("d", "y")
    s.add_contrary("c", "z")

    assert s.decide_credulous("ID", "b")
    assert s.decide_skeptical("ID", "b")
    for a in ["a", "c","d", "x", "z", "y"]:
        assert not s.decide_credulous("ID", a)
        assert not s.decide_skeptical("ID", a)

    pr_extensions = [ext.assumptions for ext in s.enumerate_extensions("PR")]
    assert len(pr_extensions) == 2
    assert {"b","d"} in pr_extensions
    assert {"b","c"} in pr_extensions

    assert s.find_extension("GR") == AssumptionSet(set(), set())

    s.add_assumption("e")
    s.add_assumption("f")

    s.add_rule("-e", ["c"])
    s.add_rule("-e", ["d"])
    s.add_rule("-f", ["e"])

    s.add_contrary("e", "-e")
    s.add_contrary("f", "-f")

    assert s.decide_credulous("ID", "b")
    assert s.decide_skeptical("ID", "b")
    for a in ["a", "c", "d", "x", "z", "y", "e", "f", "-e", "-f"]:
        assert not s.decide_credulous("ID", a)
        assert not s.decide_skeptical("ID", a)

    pr_extensions = [ext.assumptions for ext in s.enumerate_extensions("PR")]
    assert len(pr_extensions) == 2
    assert {"b","d","f"} in pr_extensions
    assert {"b","c","f"} in pr_extensions

    assert s.find_extension("GR") == AssumptionSet(set(), set())

def test_ideal_and_pref2():
    # From Lehtonen, Wallner, Järvisalo 2021 (JAIR)
    s = ABASolver()

    s.add_assumption("a")
    s.add_assumption("b")
    s.add_assumption("c")
    s.add_assumption("d")

    s.add_rule("-b", ["a"])
    s.add_rule("-a", ["b"])
    s.add_rule("-c", ["a"])
    s.add_rule("-c", ["b"])
    s.add_rule("-d", ["c", "d"])

    s.add_contrary("a", "-a")
    s.add_contrary("b", "-b")
    s.add_contrary("c", "-c")
    s.add_contrary("d", "-d")

    assert s.find_extension("ID") == AssumptionSet(set(), set())

    pr_extensions = [ext.assumptions for ext in s.enumerate_extensions("PR")]
    assert len(pr_extensions) == 2
    assert {"a","d"} in pr_extensions
    assert {"b","d"} in pr_extensions

def test_grounded():
    # From Lehtonen, Wallner, Järvisalo 2021 (JAIR)
    s = ABASolver()

    s.add_assumption("a")
    s.add_assumption("b")
    s.add_assumption("c")

    s.add_rule("x", ["a"])
    s.add_rule("y", ["y"])
    s.add_rule("y", ["b"])
    s.add_rule("z", ["y"])

    s.add_contrary("b", "x")
    s.add_contrary("c", "z")
    s.add_contrary("a", "w")

    assert s.find_extension("GR").assumptions == {"a", "c"}
    assert s.find_extension("GR").consequences == {"x"}

def test_input_types():
    s = ABASolver()

    try:
        s.add_assumption(["a"])
        assert False
    except ValueError:
        assert True

    try:
        s.add_assumption(3)
        assert False
    except ValueError:
        assert True

    s.add_assumption("3")
    assert s.assumptions == {"3"}

    try:
        s.add_contrary("a", "-a")
        assert False
    except ValueError:
        assert True

    try:
        s.add_assumption("a")
        s.add_contrary("a", 5)
        assert False
    except ValueError:
        assert True

    s = ABASolver()

    try:
        s.add_assumption("aaa")
        assert s.assumptions == {"aaa"}
        s.add_contrary("a", ["na"])
        assert False
    except ValueError:
        assert True

    s = ABASolver()

    try:
        s.add_rule("x", "abb")
        assert False
    except ValueError:
        assert True

    try:
        s.add_rule("x", ["a", 3])
        assert False
    except ValueError:
        assert True

def test_wrong_inputs2():
    s = ABASolver()
    s.add_assumption("a")

    try:
        s.decide_credulous(3, "a")
        assert False
    except ValueError:
        assert True

    try:
        s.decide_credulous("ad", "a")
        assert False
    except ValueError:
        assert True

    try:
        s.decide_skeptical("..", "a")
        assert False
    except ValueError:
        assert True

    try:
        s.find_extension("..")
        assert False
    except ValueError:
        assert True

    try:
        s.enumerate_extensions("..")
        assert False
    except ValueError:
        assert True

    try:
        s.enumerate_extensions("AD", -1)
        assert False
    except ValueError:
        assert True

    try:
        s.enumerate_extensions("AD", "a")
        assert False
    except ValueError:
        assert True

