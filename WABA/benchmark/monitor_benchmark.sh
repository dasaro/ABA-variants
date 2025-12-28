#!/bin/bash
# Monitor all 3 benchmark passes

echo "=== WABA Benchmark Monitor ==="
echo "Started: $(date)"
echo

while true; do
    clear
    echo "=== Benchmark Progress - $(date) ==="
    echo
    
    # PASS 1: ENUM
    if [ -f results_v4/enum.jsonl ]; then
        enum_count=$(wc -l < results_v4/enum.jsonl)
        enum_pct=$(python3 -c "print(f'{$enum_count/4608*100:.1f}%')")
        echo "PASS 1 - ENUM: $enum_count/4608 ($enum_pct)"
        python3 << 'EOF'
import json
r = [json.loads(l) for l in open('results_v4/enum.jsonl')]
print(f"  ✓ SAT: {sum(1 for x in r if x['status']=='sat')} | ✗ Errors: {sum(1 for x in r if x['status']=='error')} | ⏱ Timeouts: {sum(1 for x in r if x['status']=='timeout')}")
EOF
    else
        echo "PASS 1 - ENUM: Not started"
    fi
    echo
    
    # PASS 2: OPT MIN
    if [ -f results_v4/opt_min.jsonl ]; then
        opt_min_count=$(wc -l < results_v4/opt_min.jsonl)
        opt_min_pct=$(python3 -c "print(f'{$opt_min_count/4608*100:.1f}%')")
        echo "PASS 2 - OPT MIN: $opt_min_count/4608 ($opt_min_pct)"
        python3 << 'EOF'
import json
r = [json.loads(l) for l in open('results_v4/opt_min.jsonl')]
print(f"  ✓ Optimal: {sum(1 for x in r if x['status']=='optimal')} | SAT: {sum(1 for x in r if x['status']=='sat')} | ✗ Errors: {sum(1 for x in r if x['status']=='error')} | ⏱ Timeouts: {sum(1 for x in r if x['status']=='timeout')}")
EOF
    else
        echo "PASS 2 - OPT MIN: Not started"
    fi
    echo
    
    # PASS 3: OPT MAX
    if [ -f results_v4/opt_max.jsonl ]; then
        opt_max_count=$(wc -l < results_v4/opt_max.jsonl)
        opt_max_pct=$(python3 -c "print(f'{$opt_max_count/4608*100:.1f}%')")
        echo "PASS 3 - OPT MAX: $opt_max_count/4608 ($opt_max_pct)"
        python3 << 'EOF'
import json
r = [json.loads(l) for l in open('results_v4/opt_max.jsonl')]
print(f"  ✓ Optimal: {sum(1 for x in r if x['status']=='optimal')} | SAT: {sum(1 for x in r if x['status']=='sat')} | ✗ Errors: {sum(1 for x in r if x['status']=='error')} | ⏱ Timeouts: {sum(1 for x in r if x['status']=='timeout')}")
EOF
    else
        echo "PASS 3 - OPT MAX: Not started"
    fi
    echo
    
    # Check if all complete
    total=$(wc -l results_v4/*.jsonl 2>/dev/null | tail -1 | awk '{print $1}')
    if [ "$total" = "13824" ]; then
        echo "✓ ALL PASSES COMPLETE!"
        break
    fi
    
    sleep 300  # Update every 5 minutes
done

echo
echo "=== Final Summary ==="
echo "Enum: $(wc -l < results_v4/enum.jsonl)/4608"
echo "Opt Min: $(wc -l < results_v4/opt_min.jsonl)/4608"  
echo "Opt Max: $(wc -l < results_v4/opt_max.jsonl)/4608"
echo "Total: $total/13824"
echo "Completed: $(date)"
