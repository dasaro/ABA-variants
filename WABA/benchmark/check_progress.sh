#!/bin/bash
# Quick progress checker for ENUM benchmark

echo "======================================"
echo "ENUM BENCHMARK PROGRESS"
echo "======================================"
echo ""

# Check if process is running
if ps aux | grep -q "[b]enchmark_runner.py.*enum"; then
    echo "✓ Benchmark process is RUNNING"
    PID=$(ps aux | grep "[b]enchmark_runner.py.*enum" | awk '{print $2}')
    echo "  PID: $PID"
else
    echo "✗ Benchmark process NOT running"
fi
echo ""

# Count results
TOTAL=5760
if [ -f results_v4/enum_results.jsonl ]; then
    COMPLETED=$(wc -l < results_v4/enum_results.jsonl)
    REMAINING=$((TOTAL - COMPLETED))
    PCT=$(echo "scale=1; $COMPLETED * 100 / $TOTAL" | bc)

    echo "Progress: $COMPLETED / $TOTAL ($PCT%)"
    echo "Remaining: $REMAINING runs"
    echo ""

    # Count by status
    TIMEOUTS=$(grep -c '"status": "timeout"' results_v4/enum_results.jsonl 2>/dev/null || echo 0)
    ERRORS=$(grep -c '"status": "error"' results_v4/enum_results.jsonl 2>/dev/null || echo 0)
    KILL_FAILED=$(grep -c '"status": "timeout_kill_failed"' results_v4/enum_results.jsonl 2>/dev/null || echo 0)

    echo "Timeouts: $TIMEOUTS"
    echo "Errors: $ERRORS"
    if [ "$KILL_FAILED" -gt 0 ]; then
        echo "⚠ Kill-failed: $KILL_FAILED"
    fi
    echo ""

    # Latest runs
    echo "Latest 3 runs:"
    tail -3 results_v4/enum_results.jsonl | python3 -c "import sys, json; [print(f\"  {json.loads(line)['instance_id'][:35]:<35} {json.loads(line)['semiring']}/{json.loads(line)['monoid']:<6} {json.loads(line)['status']}\") for line in sys.stdin]" 2>/dev/null || echo "  (parse error)"
else
    echo "No results file found"
fi
echo ""

# Latest log lines
if [ -f results_v4/enum_final.log ]; then
    echo "Latest log (last 5 lines):"
    tail -5 results_v4/enum_final.log | grep -E "^\[|Chunk|Recycling" || tail -3 results_v4/enum_final.log
fi

echo "======================================"
