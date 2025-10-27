#!/bin/bash

runs=5
diffs=()

for i in $(seq 1 $runs); do
    echo "Run #$i"
    
    # Capture both stdout and stderr
    output=$(./blant -t 2 -k 3 -s EBE -n 100000000 networks/syeast.el 2>&1)

    # Extract all thread times (fifth word in the line)
    thread_times=($(echo "$output" | awk '/Thread/ {print $5}'))

    if ((${#thread_times[@]} == 0)); then
        echo "Warning: no thread times found for run #$i" >&2
        continue
    fi

    # Find min and max
    min=${thread_times[0]}
    max=${thread_times[0]}
    for t in "${thread_times[@]}"; do
        (( $(echo "$t < $min" | bc -l) )) && min=$t
        (( $(echo "$t > $max" | bc -l) )) && max=$t
    done

    # Difference between fastest and slowest threads
    diff=$(echo "$max - $min" | bc -l)
    diffs+=("$diff")

    echo "  Thread times: ${thread_times[*]}"
    echo "  Run #$i difference: $diff seconds"
    echo
done

# Compute average difference across runs
if (( ${#diffs[@]} > 0 )); then
    sum=0
    for d in "${diffs[@]}"; do
        sum=$(echo "$sum + $d" | bc -l)
    done
    avg=$(echo "$sum / ${#diffs[@]}" | bc -l)
    echo "Average difference between threads across runs: $avg seconds"
else
    echo "No valid data to compute average difference."
fi
